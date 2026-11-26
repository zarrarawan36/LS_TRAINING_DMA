// -----------------------------------------------------------------------------
// j3_mem_stall_test : memory stall scenario
// -----------------------------------------------------------------------------
class j3_mem_stall_test extends j3_base_test;

  `uvm_component_utils(j3_mem_stall_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drain_cycles = 200;
  endfunction

  virtual task body();
    j3_mem_stall_vseq vseq;
    vseq = j3_mem_stall_vseq::type_id::create("vseq");
    if (env == null || env.vseqr == null)
      `uvm_fatal("TEST", "virtual sequencer (env.vseqr) not available")
    `uvm_info("TEST", "Starting j3_mem_stall_vseq", UVM_LOW)
    vseq.start(env.vseqr);
  endtask

endclass : j3_mem_stall_test
