// -----------------------------------------------------------------------------
// j3_cmd_driver : drives the DUT inputs of the 'cmd' group
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06 port table (valid/ready command channel, SPEC-00 command channel + handshake rules)
// -----------------------------------------------------------------------------
//
//   This group has DUT inputs you must drive: cmd, cmd_valid.
//   Steps (see axi4lite_driver.svh in dv_lib for a commented example):
//     1. build_phase : get your virtual interface (config_db name "cmd_vif")
//     2. run_phase   : drive idle values, wait for rst_n = 1
//     3. forever: get_next_item(req) -> drive it with the handshake rules of
//                 SPEC-00 -> item_done()
//   Some groups only need READY driven (e.g. a status or data receiver). For
//   those you may drive READY every cycle from a config knob instead of using
//   sequences (look at axis_slave_driver.svh for that style).
// -----------------------------------------------------------------------------
class j3_cmd_driver extends uvm_driver #(j3_cmd_item);

  `uvm_component_utils(j3_cmd_driver)

  // TODO: virtual <your_interface> vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // TODO: get the vif from uvm_config_db, `uvm_fatal if missing
  endfunction

  task run_phase(uvm_phase phase);
    // TODO: idle values, wait for reset release, main loop
  endtask

endclass : j3_cmd_driver
