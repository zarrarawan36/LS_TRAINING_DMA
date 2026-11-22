// -----------------------------------------------------------------------------
// j3_first_test : your first directed test
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : your test plan, first row of section Tests
// -----------------------------------------------------------------------------
//
//   Goal: ONE simple, legal transaction through the DUT, checked by the
//   scoreboard. Make this pass (and understand the waveform) before writing
//   anything random.
//   Run:  cd sim && make run TEST=j3_first_test SEED=1
// -----------------------------------------------------------------------------
class j3_first_test extends j3_base_test;

  `uvm_component_utils(j3_first_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task body();
    // TODO: create a sequence and start it on an agent sequencer
    `uvm_info("TEST", "TODO: j3_first_test does nothing yet", UVM_LOW)
  endtask

endclass : j3_first_test
