// -----------------------------------------------------------------------------
// j3_dout_agent : agent for the 'dout' group
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06 port table (valid/ready data-beat channel, SPEC-00 data-beat channel)
// -----------------------------------------------------------------------------
//
//   Standard agent: monitor always, sequencer + driver when active.
//   Compare with dv_lib/axi4lite_agent/axi4lite_agent.svh.
// -----------------------------------------------------------------------------
typedef uvm_sequencer #(j3_dout_item) j3_dout_sequencer;

class j3_dout_agent extends uvm_agent;

  `uvm_component_utils(j3_dout_agent)

  j3_dout_sequencer sqr;
  j3_dout_driver    drv;
  j3_dout_monitor   mon;

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

endclass : j3_dout_agent
