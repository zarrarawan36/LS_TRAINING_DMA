// -----------------------------------------------------------------------------
// j3_scoreboard : compares DUT behaviour against expected/observed transactions
//
// Spec   : SPEC-06 (MRD-CMD-*, MRD-DAT-*, MRD-STS-*, MRD-ERR-*)
// -----------------------------------------------------------------------------
// The scoreboard receives transactions from the monitors and compares them against
`uvm_analysis_imp_decl(_cmd)
`uvm_analysis_imp_decl(_dout)
`uvm_analysis_imp_decl(_sts)
`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_axi_addr)

class j3_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(j3_scoreboard)

  // Analysis imps (connect monitor analysis ports to these in the env)
  uvm_analysis_imp_cmd      #(j3_cmd_item,     j3_scoreboard) cmd_imp;
  uvm_analysis_imp_dout     #(j3_dout_item,    j3_scoreboard) dout_imp;
  uvm_analysis_imp_sts      #(j3_sts_item,     j3_scoreboard) sts_imp;
  uvm_analysis_imp_axi      #(axi4_item,       j3_scoreboard) axi_imp;
  uvm_analysis_imp_axi_addr #(axi4_addr_item,  j3_scoreboard) axi_addr_imp;

  j3_ref_model          ref_model;
  virtual axi_mem_bd_if mem_vif;

  // Observed transactions (for debug/reporting)
  j3_cmd_item    obs_cmd_q[$];
  j3_dout_item   obs_dout_q[$];
  j3_sts_item    obs_sts_q[$];
  axi4_item      obs_axi_rd_q[$];
  axi4_addr_item obs_axi_ar_q[$];

  // Expected queues produced by ref_model in command order.
  j3_dout_item   exp_dout_q[$];
  j3_sts_item    exp_sts_q[$];
  axi4_addr_item exp_ar_q[$];

  // Pending commands waiting for status correlation.
  j3_cmd_item pending_cmd_q[$];

  // Bookkeeping
  int unsigned n_match;
  int unsigned n_mismatch;
  int unsigned n_cmd;
  int unsigned n_dout_beats;
  longint unsigned n_dout_bytes;
  int unsigned n_sts;
  int unsigned n_axi_rd_bursts;
  int unsigned n_axi_ar;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cmd_imp      = new("cmd_imp", this);
    dout_imp     = new("dout_imp", this);
    sts_imp      = new("sts_imp", this);
    axi_imp      = new("axi_imp", this);
    axi_addr_imp = new("axi_addr_imp", this);
    ref_model    = j3_ref_model::type_id::create("ref_model");
    if (!uvm_config_db#(virtual axi_mem_bd_if)::get(this, "", "mem_vif", mem_vif))
      `uvm_warning("SCB", "mem_vif not found; ref_model memory/error predictions may be inaccurate")
  endfunction

  // ---------------------------- cmd monitor ----------------------------------
  function void write_cmd(j3_cmd_item t);
    j3_cmd_item c;
    axi4_addr_item exp_ar[$];
    j3_dout_item   exp_dout[$];
    j3_sts_item    exp_sts;

    if (t == null) return;
    $cast(c, t.clone());
    obs_cmd_q.push_back(c);
    pending_cmd_q.push_back(c);
    n_cmd++;

    `uvm_info("SCB", $sformatf("CMD  #%0d %s", n_cmd, c.convert2string()), UVM_MEDIUM)

    if (ref_model != null) begin
      ref_model.predict(c, mem_vif, exp_ar, exp_dout, exp_sts);
      foreach (exp_ar[i])   exp_ar_q.push_back(exp_ar[i]);
      foreach (exp_dout[i]) exp_dout_q.push_back(exp_dout[i]);
      if (exp_sts != null)  exp_sts_q.push_back(exp_sts);
      `uvm_info("SCB", $sformatf("PRED cmd(desc=0x%0h): ar=%0d dout=%0d sts.err=%0b bytes_done=%0d",
                                 c.desc_id, exp_ar.size(), exp_dout.size(), exp_sts.err, exp_sts.bytes_done),
                UVM_MEDIUM)
    end
  endfunction

  // ---------------------------- dout monitor ---------------------------------
  function void write_dout(j3_dout_item t);
    j3_dout_item d;
    j3_dout_item exp;
    if (t == null) return;
    $cast(d, t.clone());
    obs_dout_q.push_back(d);
    n_dout_beats++;
    n_dout_bytes += d.num_valid_bytes();
    `uvm_info("SCB", $sformatf("DOUT #%0d %s", n_dout_beats, d.convert2string()), UVM_HIGH)

    if (exp_dout_q.size() == 0) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-DAT-001] Unexpected DOUT beat: %s", d.convert2string()))
      return;
    end

    exp = exp_dout_q.pop_front();
    compare_dout(exp, d);
  endfunction

  // ---------------------------- sts monitor ----------------------------------
  function void write_sts(j3_sts_item t);
    j3_sts_item s;
    j3_sts_item exp;
    int cmd_idx;

    if (t == null) return;
    $cast(s, t.clone());
    obs_sts_q.push_back(s);
    n_sts++;

    `uvm_info("SCB", $sformatf("STS  #%0d %s", n_sts, s.convert2string()), UVM_MEDIUM)

    if (exp_sts_q.size() == 0) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-STS-001] Unexpected STS (no expected status): %s", s.convert2string()))
      return;
    end

    exp = exp_sts_q.pop_front();
    compare_sts(exp, s);

    cmd_idx = find_pending_cmd_by_desc(s.desc_id);
    if (cmd_idx < 0) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-STS-001] Status received for unknown desc_id=0x%0h: %s",
                                  s.desc_id, s.convert2string()))
    end else begin
      pending_cmd_q.delete(cmd_idx);
    end
  endfunction

  // ---------------------------- AXI monitor ----------------------------------
  function void write_axi(axi4_item t);
    axi4_item a;
    if (t == null) return;
    $cast(a, t.clone());
    if (a.rw == AXI4_READ) begin
      obs_axi_rd_q.push_back(a);
      n_axi_rd_bursts++;
      `uvm_info("SCB", $sformatf("AXI-RD #%0d %s", n_axi_rd_bursts, a.convert2string()), UVM_HIGH)
      check_axi_read_burst(a);
    end
  endfunction

  // ---------------------------- AXI-ADDR monitor -----------------------------
  function void write_axi_addr(axi4_addr_item t);
    axi4_addr_item ar;
    axi4_addr_item exp;
    if (t == null) return;
    // axi4_addr_item has no do_copy/field macros; clone() returns defaults.
    ar = axi4_addr_item::type_id::create("ar_obs");
    ar.rw        = t.rw;
    ar.addr      = t.addr;
    ar.len       = t.len;
    ar.size      = t.size;
    ar.burst     = t.burst;
    ar.addr_time = t.addr_time;
    if (ar.rw != AXI4_READ) return;

    obs_axi_ar_q.push_back(ar);
    n_axi_ar++;
    `uvm_info("SCB", $sformatf("AXI-AR #%0d %s", n_axi_ar, ar.convert2string()), UVM_HIGH)

    if (exp_ar_q.size() == 0) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-BRS] Unexpected AXI AR: %s", ar.convert2string()))
      return;
    end

    exp = exp_ar_q.pop_front();
    compare_ar(exp, ar);
  endfunction

  // ---------------------------- comparisons ----------------------------------
  function void compare_dout(j3_dout_item exp, j3_dout_item obs);
    bit ok;
    ok = (exp.data === obs.data) &&
         (exp.keep === obs.keep) &&
         (exp.last === obs.last);
    if (ok) begin
      n_match++;
      `uvm_info("SCB", $sformatf("[MRD-DAT] DOUT match: %s", obs.convert2string()), UVM_HIGH)
    end else begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-DAT] DOUT mismatch\n  exp: %s\n  obs: %s",
                                  exp.convert2string(), obs.convert2string()))
    end
  endfunction

  function void compare_sts(j3_sts_item exp, j3_sts_item obs);
    bit ok;
    ok = (exp.desc_id    === obs.desc_id) &&
         (exp.eop_seen   === obs.eop_seen) &&
         (exp.err        === obs.err) &&
         (exp.bytes_done === obs.bytes_done);
    if (ok) begin
      n_match++;
      `uvm_info("SCB", $sformatf("[MRD-STS] STS match: %s", obs.convert2string()), UVM_MEDIUM)
    end else begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-STS] STS mismatch\n  exp: %s\n  obs: %s",
                                  exp.convert2string(), obs.convert2string()))
    end
  endfunction

  function void compare_ar(axi4_addr_item exp, axi4_addr_item obs);
    bit ok;
    ok = (obs.rw    === exp.rw) &&
         (obs.addr  === exp.addr) &&
         (obs.len   === exp.len) &&
         (obs.size  === exp.size) &&
         (obs.burst === exp.burst);
    if (ok) begin
      n_match++;
      `uvm_info("SCB", $sformatf("[MRD-BRS] AR match: %s", obs.convert2string()), UVM_HIGH)
    end else begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-BRS] AR mismatch\n  exp: %s\n  obs: %s",
                                  exp.convert2string(), obs.convert2string()))
    end
  endfunction

  function void check_axi_read_burst(axi4_item a);
    if (a == null) return;
    if (a.size != 3'd2) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-BRS-001] ARSIZE must be 2, got %0d for %s", a.size, a.convert2string()))
    end
    if (a.burst != AXI4_BURST_INCR && a.burst != AXI4_BURST_FIXED) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-BRS] Unsupported ARBURST %0d for %s", a.burst, a.convert2string()))
    end
    if (a.burst == AXI4_BURST_INCR && a.crosses_4k()) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-BRS-002] INCR burst crosses 4KB: %s", a.convert2string()))
    end
    if (a.num_beats() != int'(a.len) + 1) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-BRS] Beat count mismatch len=%0d beats=%0d: %s",
                                  a.len, a.num_beats(), a.convert2string()))
    end
  endfunction

  // ---------------------------- helpers --------------------------------------
  function int find_pending_cmd_by_desc(bit [7:0] desc_id);
    foreach (pending_cmd_q[i]) begin
      if (pending_cmd_q[i].desc_id == desc_id) return i;
    end
    return -1;
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (n_cmd == 0) begin
      n_mismatch++;
      `uvm_error("SCB", "No CMD transactions observed")
    end
    if (n_sts == 0) begin
      n_mismatch++;
      `uvm_error("SCB", "No STS transactions observed")
    end
    if (n_cmd != n_sts) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("CMD/STS count mismatch: cmds=%0d sts=%0d", n_cmd, n_sts))
    end

    if (pending_cmd_q.size() != 0) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-STS-001] %0d command(s) without observed status", pending_cmd_q.size()))
      foreach (pending_cmd_q[i]) begin
        `uvm_info("SCB", $sformatf("Unmatched CMD: %s", pending_cmd_q[i].convert2string()), UVM_LOW)
      end
    end

    if (exp_dout_q.size() != 0) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-DAT-001] %0d expected DOUT beat(s) not observed", exp_dout_q.size()))
    end
    if (exp_sts_q.size() != 0) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-STS-001] %0d expected STS item(s) not observed", exp_sts_q.size()))
    end
    if (exp_ar_q.size() != 0) begin
      n_mismatch++;
      `uvm_error("SCB", $sformatf("[MRD-BRS] %0d expected AXI AR item(s) not observed", exp_ar_q.size()))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB",
      $sformatf("Summary: cmds=%0d dout_beats=%0d dout_bytes=%0d sts=%0d axi_ar=%0d axi_rd_bursts=%0d matches=%0d mismatches=%0d",
                n_cmd, n_dout_beats, n_dout_bytes, n_sts, n_axi_ar, n_axi_rd_bursts, n_match, n_mismatch),
      UVM_LOW)
  endfunction

endclass : j3_scoreboard
