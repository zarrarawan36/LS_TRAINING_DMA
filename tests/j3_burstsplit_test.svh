// -----------------------------------------------------------------------------
// j3_burstsplit_test : 4KB boundary / burst-split scenario
// -----------------------------------------------------------------------------
class j3_burstsplit_test extends j3_base_test;

  `uvm_component_utils(j3_burstsplit_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task body();
    j3_burstsplit_vseq vseq;
    vseq = j3_burstsplit_vseq::type_id::create("vseq");
    if (env == null || env.vseqr == null)
      `uvm_fatal("TEST", "virtual sequencer (env.vseqr) not available")
    `uvm_info("TEST", "Starting j3_burstsplit_vseq", UVM_LOW)
    vseq.start(env.vseqr);
  endtask

endclass : j3_burstsplit_test
