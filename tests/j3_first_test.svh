// -----------------------------------------------------------------------------
// j3_first_test : your first directed test
//
// Spec   : your test plan, first row of section Tests
// -----------------------------------------------------------------------------
class j3_first_test extends j3_base_test;

  `uvm_component_utils(j3_first_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task body();
    j3_single_cmd_vseq vseq;
    vseq = j3_single_cmd_vseq::type_id::create("vseq");

    if (env == null || env.vseqr == null)
      `uvm_fatal("TEST", "virtual sequencer (env.vseqr) not available")

    `uvm_info("TEST", "Starting j3_single_cmd_vseq (first directed command)", UVM_LOW)
    vseq.start(env.vseqr);
  endtask

endclass : j3_first_test
