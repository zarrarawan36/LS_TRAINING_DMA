// -----------------------------------------------------------------------------
// j3_sts_backpressure_test : STS ready backpressure scenario
// -----------------------------------------------------------------------------
class j3_sts_backpressure_test extends j3_base_test;

  `uvm_component_utils(j3_sts_backpressure_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drain_cycles = 300;
  endfunction

  virtual task body();
    j3_sts_backpressure_vseq vseq;
    vseq = j3_sts_backpressure_vseq::type_id::create("vseq");
    if (env == null || env.vseqr == null)
      `uvm_fatal("TEST", "virtual sequencer (env.vseqr) not available")
    `uvm_info("TEST", "Starting j3_sts_backpressure_vseq", UVM_LOW)
    vseq.start(env.vseqr);
  endtask

endclass : j3_sts_backpressure_test
