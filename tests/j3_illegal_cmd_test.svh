// -----------------------------------------------------------------------------
// j3_illegal_cmd_test : directed illegal-command scenario
// -----------------------------------------------------------------------------
class j3_illegal_cmd_test extends j3_base_test;

  `uvm_component_utils(j3_illegal_cmd_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task body();
    j3_illegal_cmd_vseq vseq;
    vseq = j3_illegal_cmd_vseq::type_id::create("vseq");
    if (env == null || env.vseqr == null)
      `uvm_fatal("TEST", "virtual sequencer (env.vseqr) not available")
    `uvm_info("TEST", "Starting j3_illegal_cmd_vseq", UVM_LOW)
    vseq.start(env.vseqr);
  endtask

endclass : j3_illegal_cmd_test
