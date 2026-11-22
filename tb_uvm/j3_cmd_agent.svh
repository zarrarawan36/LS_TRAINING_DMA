// -----------------------------------------------------------------------------
// j3_cmd_agent : agent for the 'cmd' group
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06 port table (valid/ready command channel, SPEC-00 command channel + handshake rules)
// -----------------------------------------------------------------------------
//
//   Standard agent: monitor always, sequencer + driver when active.
//   Compare with dv_lib/axi4lite_agent/axi4lite_agent.svh.
// -----------------------------------------------------------------------------
typedef uvm_sequencer #(j3_cmd_item) j3_cmd_sequencer;

class j3_cmd_agent extends uvm_agent;

  `uvm_component_utils(j3_cmd_agent)

  j3_cmd_sequencer sqr;
  j3_cmd_driver    drv;
  j3_cmd_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // TODO: create mon; if get_is_active() == UVM_ACTIVE create sqr and drv
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // TODO: drv.seq_item_port.connect(sqr.seq_item_export) when active
  endfunction

endclass : j3_cmd_agent
