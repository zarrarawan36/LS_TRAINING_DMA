// -----------------------------------------------------------------------------
// j3_rand_stress_test : randomized stress scenario
// -----------------------------------------------------------------------------
class j3_rand_stress_test extends j3_base_test;

  `uvm_component_utils(j3_rand_stress_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drain_cycles = 500;
  endfunction

  virtual task body();
    j3_rand_stress_vseq vseq;
    vseq = j3_rand_stress_vseq::type_id::create("vseq");
    if (env == null || env.vseqr == null)
      `uvm_fatal("TEST", "virtual sequencer (env.vseqr) not available")
    `uvm_info("TEST", "Starting j3_rand_stress_vseq", UVM_LOW)
    vseq.start(env.vseqr);
  endtask

endclass : j3_rand_stress_test
