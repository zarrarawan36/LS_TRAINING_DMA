// -----------------------------------------------------------------------------
// axi4_monitor : passive AXI4 monitor
//
//   addr_ap.write(axi4_addr_item) : on every AW / AR handshake
//   ap.write(axi4_item)           : read  -> on the R handshake with RLAST=1
//                                   write -> on the B handshake
//
// Write data beats are collected per burst. A burst is closed by WLAST=1; if
// the master never raises WLAST, the beats seen up to the B handshake are
// reported (so a scoreboard can still compare and flag the missing WLAST via
// item.last[]).
// Read beats are attached to the oldest outstanding AR and closed by RLAST.
// The monitor does NOT check protocol rules. All queues flush on reset.
// -----------------------------------------------------------------------------
class axi4_monitor extends uvm_monitor;

  `uvm_component_utils(axi4_monitor)

  uvm_analysis_port #(axi4_addr_item) addr_ap;
  uvm_analysis_port #(axi4_item)      ap;

  axi4_cfg        cfg;
  virtual axi4_if vif;

  protected axi4_item aw_q[$];     // AW seen, data not yet complete
  protected axi4_item wdat_q[$];   // write beats grouped per burst
  protected axi4_item wcur;        // burst currently collecting W beats
  protected axi4_item wdone_q[$];  // AW + all W seen, waiting for B
  protected axi4_item ar_q[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    addr_ap = new("addr_ap", this);
    ap      = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4_cfg)::get(this, "", "cfg", cfg) || cfg == null)
      `uvm_fatal("AXI4_MON", "no axi4_cfg found in config_db (key \"cfg\")")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("AXI4_MON", "cfg.vif is null")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (vif.rst_n !== 1'b1) begin
        flush();
        continue;
      end
      sample_edge();
    end
  endtask

  protected function void flush();
    aw_q.delete(); wdat_q.delete(); wdone_q.delete(); ar_q.delete();
    wcur = null;
  endfunction

  protected function void sample_edge();
    axi4_item t;

    // ---------------- write response ----------------
    if (vif.bvalid === 1'b1 && vif.bready === 1'b1) begin
      pair_write();
      if (wdone_q.size() == 0 && aw_q.size() > 0 && wcur != null) begin
        // B arrived although WLAST was never seen: close what we have
        wdat_q.push_back(wcur);
        wcur = null;
        pair_write();
      end
      if (wdone_q.size() == 0) begin
        `uvm_error("AXI4_MON", "B handshake without a complete AW+W burst")
      end else begin
        t = wdone_q.pop_front();
        t.bresp    = vif.bresp;
        t.end_time = $time;
        publish(t);
      end
    end

    // ---------------- read data ----------------
    if (vif.rvalid === 1'b1 && vif.rready === 1'b1) begin
      if (ar_q.size() == 0) begin
        `uvm_error("AXI4_MON", "R handshake without a preceding AR")
      end else begin
        t = ar_q[0];
        t.data.push_back(vif.rdata);
        t.strb.push_back(4'hF);
        t.last.push_back(vif.rlast);
        t.rresp.push_back(vif.rresp);
        if (vif.rlast === 1'b1) begin
          void'(ar_q.pop_front());
          t.end_time = $time;
          publish(t);
        end
      end
    end

    // ---------------- write address ----------------
    if (vif.awvalid === 1'b1 && vif.awready === 1'b1) begin
      t = axi4_item::type_id::create("wr");
      t.rw        = AXI4_WRITE;
      t.addr      = vif.awaddr;
      t.len       = vif.awlen;
      t.size      = vif.awsize;
      t.burst     = vif.awburst;
      t.addr_time = $time;
      aw_q.push_back(t);
      publish_addr(t);
    end

    // ---------------- write data ----------------
    if (vif.wvalid === 1'b1 && vif.wready === 1'b1) begin
      if (wcur == null) wcur = axi4_item::type_id::create("wdat");
      wcur.data.push_back(vif.wdata);
      wcur.strb.push_back(vif.wstrb);
      wcur.last.push_back(vif.wlast);
      if (vif.wlast === 1'b1) begin
        wdat_q.push_back(wcur);
        wcur = null;
      end
    end
    pair_write();

    // ---------------- read address ----------------
    if (vif.arvalid === 1'b1 && vif.arready === 1'b1) begin
      t = axi4_item::type_id::create("rd");
      t.rw        = AXI4_READ;
      t.addr      = vif.araddr;
      t.len       = vif.arlen;
      t.size      = vif.arsize;
      t.burst     = vif.arburst;
      t.addr_time = $time;
      ar_q.push_back(t);
      publish_addr(t);
    end
  endfunction

  protected function void pair_write();
    while (aw_q.size() > 0 && wdat_q.size() > 0) begin
      axi4_item a = aw_q.pop_front();
      axi4_item d = wdat_q.pop_front();
      a.data = d.data;
      a.strb = d.strb;
      a.last = d.last;
      wdone_q.push_back(a);
    end
  endfunction

  protected function void publish_addr(axi4_item t);
    axi4_addr_item a = axi4_addr_item::type_id::create("addr");
    a.rw        = t.rw;
    a.addr      = t.addr;
    a.len       = t.len;
    a.size      = t.size;
    a.burst     = t.burst;
    a.addr_time = t.addr_time;
    addr_ap.write(a);
  endfunction

  protected function void publish(axi4_item t);
    if (cfg.trace) `uvm_info("AXI4_MON", t.convert2string(), UVM_MEDIUM)
    ap.write(t);
  endfunction

endclass : axi4_monitor
