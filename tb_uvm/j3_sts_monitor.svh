// -----------------------------------------------------------------------------
// j3_sts_monitor : observes the 'sts' group
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06 port table (valid/ready status channel, SPEC-00 status channel + handshake rules)
// -----------------------------------------------------------------------------
//
//   Steps (see axi4lite_monitor.svh in dv_lib for a commented example):
//     1. build_phase : get the virtual interface ("sts_vif")
//     2. run_phase   : on every rising clk edge, when a transfer happens
//                      (valid && ready, or a pulse / level change for plain
//                      wires) create a NEW item, fill it, ap.write(item)
//   The monitor only observes. It never drives a signal and never checks.
// -----------------------------------------------------------------------------
class j3_sts_monitor extends uvm_monitor;

  `uvm_component_utils(j3_sts_monitor)

  uvm_analysis_port #(j3_sts_item) ap;

  // TODO: virtual <your_interface> vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // TODO: get the vif from uvm_config_db
  endfunction

  task run_phase(uvm_phase phase);
    // TODO: sample the interface, publish items on ap
  endtask

endclass : j3_sts_monitor
