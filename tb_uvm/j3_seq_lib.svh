// -----------------------------------------------------------------------------
// j3_seq_lib : sequences and virtual sequences for J3 MM-RD
//
// All project sequences (leaf + virtual) are defined in this single file.
// - Leaf sequences run on channel sequencers inside J3 agents.
// - Virtual sequences run on j3_virtual_sequencer and coordinate leaf
//   sequences/resources across agents.
//
// Planned virtual sequences align with docs/j3_mm_rd/testplan.html (Section 8):
//   j3_single_cmd_vseq, j3_illegal_cmd_vseq, j3_rand_vseq,
//   j3_burstsplit_vseq, j3_fixed_addr_vseq, j3_error_resp_vseq,
//   j3_dout_backpressure_vseq, j3_rand_stress_vseq, j3_reset_vseq,
//   j3_keep_last_vseq, j3_back2back_vseq, j3_mem_stall_vseq,
//   j3_sts_backpressure_vseq, j3_maxlen_vseq, j3_cmd_fields_vseq
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// CMD leaf sequences (sequence-driven via j3_cmd_driver)
// -----------------------------------------------------------------------------
class j3_cmd_base_seq extends uvm_sequence #(j3_cmd_item);

  `uvm_object_utils(j3_cmd_base_seq)

  function new(string name = "j3_cmd_base_seq");
    super.new(name);
  endfunction

endclass : j3_cmd_base_seq

// Directed/configurable single-command sequence.
class j3_cmd_single_seq extends j3_cmd_base_seq;

  `uvm_object_utils(j3_cmd_single_seq)

  bit [31:0] addr      = 32'h0000_1000;
  bit [15:0] len_bytes = 16'd10;
  bit        inc_addr  = 1'b1;
  bit        gen_sop   = 1'b0;
  bit        gen_eop   = 1'b0;
  bit [7:0]  desc_id   = 8'h00;

  function new(string name = "j3_cmd_single_seq");
    super.new(name);
  endfunction

  virtual task body();
    j3_cmd_item req;
    req = j3_cmd_item::type_id::create("req");
    start_item(req);
    req.addr      = addr;
    req.len_bytes = len_bytes;
    req.inc_addr  = inc_addr;
    req.gen_sop   = gen_sop;
    req.gen_eop   = gen_eop;
    req.desc_id   = desc_id;
    finish_item(req);
  endtask

endclass : j3_cmd_single_seq

// Randomized command sequence (simple randomized fields; adjust constraints per spec).
class j3_cmd_rand_seq extends j3_cmd_base_seq;

  `uvm_object_utils(j3_cmd_rand_seq)

  int unsigned num_cmds = 1;

  function new(string name = "j3_cmd_rand_seq");
    super.new(name);
  endfunction

  virtual task body();
    j3_cmd_item req;
    for (int i = 0; i < num_cmds; i++) begin
      req = j3_cmd_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      req.addr      = 32'h0000_1000 + (i * 32'h40); 
      req.len_bytes = 16'd4 + ($urandom_range(0, 60));
      req.inc_addr  = ($urandom_range(0, 9) != 0); // mostly INCR
      req.gen_sop   = $urandom_range(0, 1);
      req.gen_eop   = $urandom_range(0, 1);
      req.desc_id   = i[7:0];
      if (req.len_bytes == 0) req.len_bytes = 1;
      finish_item(req);
    end
  endtask

endclass : j3_cmd_rand_seq

// Back-to-back command sequence (issues cmds without extra gaps in sequence logic).
class j3_cmd_back2back_seq extends j3_cmd_base_seq;

  `uvm_object_utils(j3_cmd_back2back_seq)

  int unsigned num_cmds = 2;
  bit [31:0]   base_addr = 32'h0000_2000;
  bit [15:0]   len_bytes = 16'd16;
  bit          inc_addr  = 1'b1;

  function new(string name = "j3_cmd_back2back_seq");
    super.new(name);
  endfunction

  virtual task body();
    j3_cmd_item req;
    for (int i = 0; i < num_cmds; i++) begin
      req = j3_cmd_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      req.addr      = base_addr + (i * 32'h100);
      req.len_bytes = len_bytes;
      req.inc_addr  = inc_addr;
      req.gen_sop   = 1'b0;
      req.gen_eop   = 1'b0;
      req.desc_id   = i[7:0];
      finish_item(req);
    end
  endtask

endclass : j3_cmd_back2back_seq

// -----------------------------------------------------------------------------
// DOUT/STS leaf ready-control sequences (sequence-driven backpressure)
// Drivers consume items via try_next_item() and apply item.ready for one cycle.
// -----------------------------------------------------------------------------
class j3_dout_base_seq extends uvm_sequence #(j3_dout_item);

  `uvm_object_utils(j3_dout_base_seq)

  function new(string name = "j3_dout_base_seq");
    super.new(name);
  endfunction

endclass : j3_dout_base_seq

class j3_dout_ready_const_seq extends j3_dout_base_seq;

  `uvm_object_utils(j3_dout_ready_const_seq)

  bit          ready_value = 1'b1;
  int unsigned num_cycles  = 1;

  function new(string name = "j3_dout_ready_const_seq");
    super.new(name);
  endfunction

  virtual task body();
    j3_dout_item req;
    for (int i = 0; i < num_cycles; i++) begin
      req = j3_dout_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      req.ready = ready_value;
      finish_item(req);
    end
  endtask

endclass : j3_dout_ready_const_seq

// Periodic stall pattern: assert ready for run_cycles, deassert for stall_cycles.
class j3_dout_backpressure_seq extends j3_dout_base_seq;

  `uvm_object_utils(j3_dout_backpressure_seq)

  int unsigned num_cycles   = 100;
  int unsigned stall_every  = 4;
  int unsigned stall_cycles = 2;

  function new(string name = "j3_dout_backpressure_seq");
    super.new(name);
  endfunction

  virtual task body();
    j3_dout_item req;
    for (int i = 0; i < num_cycles; i++) begin
      req = j3_dout_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      if (stall_every > 0 && (i % stall_every) < stall_cycles)
        req.ready = 1'b0;
      else
        req.ready = 1'b1;
      finish_item(req);
    end
  endtask

endclass : j3_dout_backpressure_seq

class j3_sts_base_seq extends uvm_sequence #(j3_sts_item);

  `uvm_object_utils(j3_sts_base_seq)

  function new(string name = "j3_sts_base_seq");
    super.new(name);
  endfunction

endclass : j3_sts_base_seq

class j3_sts_ready_const_seq extends j3_sts_base_seq;

  `uvm_object_utils(j3_sts_ready_const_seq)

  bit          ready_value = 1'b1;
  int unsigned num_cycles  = 1;

  function new(string name = "j3_sts_ready_const_seq");
    super.new(name);
  endfunction

  virtual task body();
    j3_sts_item req;
    for (int i = 0; i < num_cycles; i++) begin
      req = j3_sts_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      req.ready = ready_value;
      finish_item(req);
    end
  endtask

endclass : j3_sts_ready_const_seq

class j3_sts_backpressure_seq extends j3_sts_base_seq;

  `uvm_object_utils(j3_sts_backpressure_seq)

  int unsigned num_cycles   = 100;
  int unsigned stall_every  = 4;
  int unsigned stall_cycles = 2;

  function new(string name = "j3_sts_backpressure_seq");
    super.new(name);
  endfunction

  virtual task body();
    j3_sts_item req;
    for (int i = 0; i < num_cycles; i++) begin
      req = j3_sts_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      if (stall_every > 0 && (i % stall_every) < stall_cycles)
        req.ready = 1'b0;
      else
        req.ready = 1'b1;
      finish_item(req);
    end
  endtask

endclass : j3_sts_backpressure_seq

// -----------------------------------------------------------------------------
// Virtual sequences (run on j3_virtual_sequencer)
// -----------------------------------------------------------------------------
class j3_base_vseq extends uvm_sequence;

  `uvm_object_utils(j3_base_vseq)
  `uvm_declare_p_sequencer(j3_virtual_sequencer)

  function new(string name = "j3_base_vseq");
    super.new(name);
  endfunction

  virtual task preload_mem(input bit [31:0] addr,
                           input bit [15:0] len_bytes,
                           input bit [7:0]  seed = 8'h00);
    if (p_sequencer == null || p_sequencer.mem_vif == null) begin
      `uvm_warning("J3_VSEQ", "mem_vif not available; skipping memory preload")
      return;
    end
  
    for (int unsigned i = 0; i < len_bytes; i++) begin
      p_sequencer.mem_vif.write_byte(addr + i, seed + i[7:0]);
    end
  endtask

  // Convenience: issue a single CMD leaf sequence with given fields.
  virtual task send_one_cmd(input bit [31:0] addr,
                            input bit [15:0] len_bytes,
                            input bit        inc_addr = 1'b1,
                            input bit [7:0]  desc_id  = 8'h00,
                            input bit        gen_sop  = 1'b0,
                            input bit        gen_eop  = 1'b0);
    j3_cmd_single_seq cmd_seq;
    if (p_sequencer == null || p_sequencer.cmd_sqr == null)
      `uvm_fatal("J3_VSEQ", "cmd_sqr not available on virtual sequencer")
    cmd_seq = j3_cmd_single_seq::type_id::create("cmd_seq");
    cmd_seq.addr      = addr;
    cmd_seq.len_bytes = len_bytes;
    cmd_seq.inc_addr  = inc_addr;
    cmd_seq.desc_id   = desc_id;
    cmd_seq.gen_sop   = gen_sop;
    cmd_seq.gen_eop   = gen_eop;
    cmd_seq.start(p_sequencer.cmd_sqr);
  endtask
endclass : j3_base_vseq

// j3_single_cmd_vseq: one simple legal INCR command (directed).
class j3_single_cmd_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_single_cmd_vseq)

  bit [31:0] addr      = 32'h0000_1000;
  bit [15:0] len_bytes = 16'd10;
  bit        inc_addr  = 1'b1;
  bit        gen_sop   = 1'b0;
  bit        gen_eop   = 1'b0;
  bit [7:0]  desc_id   = 8'h00;

  function new(string name = "j3_single_cmd_vseq");
    super.new(name);
  endfunction

  virtual task body();
    if (p_sequencer != null && p_sequencer.mem_vif != null) begin
      // Preload memory with a simple pattern for the transfer.
      p_sequencer.mem_vif.write_word(32'h0000_1000, 32'h0302_0100);
      p_sequencer.mem_vif.write_word(32'h0000_1004, 32'h0706_0504);
      p_sequencer.mem_vif.write_word(32'h0000_1008, 32'h0B0A_0908);
    end else begin
      `uvm_warning("J3_VSEQ", "mem_vif not available; skipping memory preload")
    end
    // Issue the single command via a CMD leaf sequence.
    send_one_cmd(addr, len_bytes, inc_addr, desc_id, gen_sop, gen_eop);
  endtask

endclass : j3_single_cmd_vseq


class j3_illegal_cmd_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_illegal_cmd_vseq)

  bit [31:0] addr      = 32'h0000_3000;
  bit [15:0] len_bytes = 16'd0; // placeholder illegal case; adjust per spec
  bit        inc_addr  = 1'b1;
  bit [7:0]  desc_id   = 8'h01;

  function new(string name = "j3_illegal_cmd_vseq");
    super.new(name);
  endfunction

  virtual task body();
    preload_mem(addr, (len_bytes == 0) ? 16'd4 : len_bytes, 8'hA0); 
    send_one_cmd(addr, len_bytes, inc_addr, desc_id, 1'b0, 1'b0);
  endtask

endclass : j3_illegal_cmd_vseq

// j3_rand_vseq: randomized legal-ish command traffic.
class j3_rand_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_rand_vseq)

  int unsigned num_cmds = 10; 

  function new(string name = "j3_rand_vseq");
    super.new(name);
  endfunction

  virtual task body();
    j3_cmd_rand_seq cmd_seq;

    // Preload a broad region for randomized addresses/lengths.
    if (p_sequencer != null && p_sequencer.mem_vif != null) begin 
      for (int unsigned i = 0; i < 4096; i++)
        p_sequencer.mem_vif.write_byte(32'h0000_1000 + i, i[7:0]);
    end
    
    cmd_seq = j3_cmd_rand_seq::type_id::create("cmd_seq");
    cmd_seq.num_cmds = num_cmds;
    if (p_sequencer == null || p_sequencer.cmd_sqr == null)
      `uvm_fatal("J3_VSEQ", "cmd_sqr not available on virtual sequencer")
    cmd_seq.start(p_sequencer.cmd_sqr);
  endtask

endclass : j3_rand_vseq

// j3_burstsplit_vseq: transfer crossing 4KB boundary to exercise burst splitting.
class j3_burstsplit_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_burstsplit_vseq)

  bit [31:0] addr      = 32'h0000_0FFC;
  bit [15:0] len_bytes = 16'd8;

  function new(string name = "j3_burstsplit_vseq");
    super.new(name);
  endfunction

  virtual task body();
    preload_mem(addr, len_bytes, 8'h10);
    send_one_cmd(addr, len_bytes, 1'b1, 8'h02, 1'b0, 1'b0);
  endtask

endclass : j3_burstsplit_vseq

// j3_fixed_addr_vseq: fixed-address read (inc_addr == 0).
class j3_fixed_addr_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_fixed_addr_vseq)

  bit [31:0] addr      = 32'h0000_4000;
  bit [15:0] len_bytes = 16'd16;

  function new(string name = "j3_fixed_addr_vseq");
    super.new(name);
  endfunction

  virtual task body();
    preload_mem(addr, 16'd4, 8'h55); // fixed beat source word(s)
    send_one_cmd(addr, len_bytes, 1'b0, 8'h03, 1'b0, 1'b0);
  endtask

endclass : j3_fixed_addr_vseq

// j3_error_resp_vseq: inject AXI error response via memory error range.
class j3_error_resp_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_error_resp_vseq)

  bit [31:0] addr      = 32'h0000_5000;
  bit [15:0] len_bytes = 16'd16;
  bit [31:0] err_lo    = 32'h0000_5000;
  bit [31:0] err_hi    = 32'h0000_5003;

  function new(string name = "j3_error_resp_vseq");
    super.new(name);
  endfunction

  virtual task body();
    preload_mem(addr, len_bytes, 8'h20);
    if (p_sequencer != null && p_sequencer.mem_vif != null) begin
      p_sequencer.mem_vif.set_error_range(err_lo, err_hi);
    end
    send_one_cmd(addr, len_bytes, 1'b1, 8'h04, 1'b0, 1'b0);
    if (p_sequencer != null && p_sequencer.mem_vif != null) begin
      p_sequencer.mem_vif.clear_error_range();
    end
  endtask

endclass : j3_error_resp_vseq

// j3_dout_backpressure_vseq: exercise dout_ready backpressure during transfer.
class j3_dout_backpressure_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_dout_backpressure_vseq)

  bit [31:0] addr      = 32'h0000_6000;
  bit [15:0] len_bytes = 16'd32;

  function new(string name = "j3_dout_backpressure_vseq");
    super.new(name);
  endfunction

  virtual task body();
    j3_dout_backpressure_seq bp;
    preload_mem(addr, len_bytes, 8'h30);
    if (p_sequencer != null && p_sequencer.dout_sqr != null) begin
      bp = j3_dout_backpressure_seq::type_id::create("bp");
      bp.num_cycles   = 200;
      bp.stall_every  = 3;
      bp.stall_cycles = 1;
      fork
        bp.start(p_sequencer.dout_sqr);
      join_none
    end
    send_one_cmd(addr, len_bytes, 1'b1, 8'h05, 1'b0, 1'b0);
  endtask

endclass : j3_dout_backpressure_vseq

// j3_sts_backpressure_vseq: exercise sts_ready backpressure.
class j3_sts_backpressure_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_sts_backpressure_vseq)

  bit [31:0] addr      = 32'h0000_6100;
  bit [15:0] len_bytes = 16'd32;

  function new(string name = "j3_sts_backpressure_vseq");
    super.new(name);
  endfunction

  virtual task body();
    j3_sts_backpressure_seq bp;
    preload_mem(addr, len_bytes, 8'h31);
    if (p_sequencer != null && p_sequencer.sts_sqr != null) begin
      bp = j3_sts_backpressure_seq::type_id::create("bp");
      bp.num_cycles   = 200;
      bp.stall_every  = 3;
      bp.stall_cycles = 1;
      fork
        bp.start(p_sequencer.sts_sqr);
      join_none
    end
    send_one_cmd(addr, len_bytes, 1'b1, 8'h06, 1'b0, 1'b0);
  endtask

endclass : j3_sts_backpressure_vseq

// j3_mem_stall_vseq: apply memory stall percentage during a transfer.
class j3_mem_stall_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_mem_stall_vseq)

  bit [31:0]   addr      = 32'h0000_7000;
  bit [15:0]   len_bytes = 16'd64;
  int unsigned stall_pct = 30;

  function new(string name = "j3_mem_stall_vseq");
    super.new(name);
  endfunction

  virtual task body();
    preload_mem(addr, len_bytes, 8'h40);
    if (p_sequencer != null && p_sequencer.mem_vif != null)
      p_sequencer.mem_vif.set_stall_pct(stall_pct);
    send_one_cmd(addr, len_bytes, 1'b1, 8'h07, 1'b0, 1'b0);
    
    if (p_sequencer != null && p_sequencer.mem_vif != null)
      p_sequencer.mem_vif.set_stall_pct(0);
  endtask

endclass : j3_mem_stall_vseq

// j3_rand_stress_vseq: mixed random commands with optional memory stalls.
class j3_rand_stress_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_rand_stress_vseq)

  int unsigned num_cmds   = 20;
  int unsigned stall_pct  = 10;

  function new(string name = "j3_rand_stress_vseq");
    super.new(name);
  endfunction

  virtual task body();
    j3_cmd_rand_seq cmd_seq;
    if (p_sequencer != null && p_sequencer.mem_vif != null) begin
      p_sequencer.mem_vif.clear_all();
      for (int unsigned i = 0; i < 8192; i++)
        p_sequencer.mem_vif.write_byte(32'h0000_1000 + i, $urandom_range(0, 255));
      p_sequencer.mem_vif.set_stall_pct(stall_pct);
    end
    cmd_seq = j3_cmd_rand_seq::type_id::create("cmd_seq");
    cmd_seq.num_cmds = num_cmds;
    if (p_sequencer != null && p_sequencer.cmd_sqr != null)
      cmd_seq.start(p_sequencer.cmd_sqr);
    if (p_sequencer != null && p_sequencer.mem_vif != null)
      p_sequencer.mem_vif.set_stall_pct(0);
  endtask

endclass : j3_rand_stress_vseq

// j3_reset_vseq: apply reset and then run a simple command (basic reset scenario).
// For mid-transfer reset, extend to fork traffic and pulse rst_vif.apply_reset().
class j3_reset_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_reset_vseq)

  bit [31:0]   addr      = 32'h0000_8000;
  bit [15:0]   len_bytes = 16'd16;
  int unsigned reset_cycles = 2;

  function new(string name = "j3_reset_vseq");
    super.new(name);
  endfunction

  virtual task body();
    if (p_sequencer != null && p_sequencer.rst_vif != null) begin
      p_sequencer.rst_vif.apply_reset(reset_cycles);
    end else begin
      `uvm_warning("J3_VSEQ", "rst_vif not available; skipping reset pulse")
    end
    preload_mem(addr, len_bytes, 8'h50);
    send_one_cmd(addr, len_bytes, 1'b1, 8'h08, 1'b0, 1'b0);
  endtask

endclass : j3_reset_vseq

// j3_keep_last_vseq: lengths causing partial final beat / keep variations.
class j3_keep_last_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_keep_last_vseq)

  function new(string name = "j3_keep_last_vseq");
    super.new(name);
  endfunction

  virtual task body();
    bit [15:0] lens[4];
    lens[0] = 16'd1;
    lens[1] = 16'd3;
    lens[2] = 16'd5;
    lens[3] = 16'd10;
    foreach (lens[i]) begin
      bit [31:0] a = 32'h0000_9000 + (i * 32'h100);
      preload_mem(a, lens[i], 8'h60 + i[7:0]);
      send_one_cmd(a, lens[i], 1'b1, i[7:0], 1'b0, 1'b0);
    end
  endtask

endclass : j3_keep_last_vseq

// j3_back2back_vseq: issue multiple commands back-to-back.
class j3_back2back_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_back2back_vseq)

  int unsigned num_cmds = 4;

  function new(string name = "j3_back2back_vseq");
    super.new(name);
  endfunction

  virtual task body();
    j3_cmd_back2back_seq cmd_seq;
    if (p_sequencer != null && p_sequencer.mem_vif != null) begin
      for (int unsigned i = 0; i < 2048; i++)
        p_sequencer.mem_vif.write_byte(32'h0000_A000 + i, i[7:0]);
    end
    cmd_seq = j3_cmd_back2back_seq::type_id::create("cmd_seq");
    cmd_seq.num_cmds  = num_cmds;
    cmd_seq.base_addr = 32'h0000_A000;
    cmd_seq.len_bytes = 16'd16;
    if (p_sequencer == null || p_sequencer.cmd_sqr == null)
      `uvm_fatal("J3_VSEQ", "cmd_sqr not available on virtual sequencer")
    cmd_seq.start(p_sequencer.cmd_sqr);
  endtask

endclass : j3_back2back_vseq

// j3_maxlen_vseq: maximum-length command (default placeholder; align with spec).
class j3_maxlen_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_maxlen_vseq)

  bit [31:0] addr      = 32'h0000_C000;
  bit [15:0] len_bytes = 16'd1024; // placeholder max length; adjust per spec

  function new(string name = "j3_maxlen_vseq");
    super.new(name);
  endfunction

  virtual task body();
    preload_mem(addr, len_bytes, 8'h70);
    send_one_cmd(addr, len_bytes, 1'b1, 8'h09, 1'b0, 1'b0);
  endtask

endclass : j3_maxlen_vseq

// j3_cmd_fields_vseq: vary command field combinations (desc_id, sop/eop flags).
class j3_cmd_fields_vseq extends j3_base_vseq;

  `uvm_object_utils(j3_cmd_fields_vseq)

  function new(string name = "j3_cmd_fields_vseq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] a;
    // Vary desc_id and gen_sop/gen_eop across a few commands.
    for (int i = 0; i < 4; i++) begin
      a = 32'h0000_D000 + (i * 32'h40);
      preload_mem(a, 16'd8, 8'h80 + i[7:0]);
      send_one_cmd(a, 16'd8, 1'b1, i[7:0], i[0], i[1]);
    end
  endtask

endclass : j3_cmd_fields_vseq
