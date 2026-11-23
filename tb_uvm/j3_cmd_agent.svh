// -----------------------------------------------------------------------------
// j3_cmd_agent : agent for the 'cmd' group
//
// Spec   : SPEC-00 command channel handshake, SPEC-06 (MRD-CMD-*)
// -----------------------------------------------------------------------------
typedef uvm_sequencer #(j3_cmd_item) j3_cmd_sequencer;

class j3_cmd_agent extends uvm_agent;

  `uvm_component_utils(j3_cmd_agent)

  j3_cmd_sequencer sqr;
  j3_cmd_driver    drv;
  j3_cmd_monitor   mon;

  uvm_analysis_port #(j3_cmd_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = j3_cmd_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = j3_cmd_sequencer::type_id::create("sqr", this);
      drv = j3_cmd_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass : j3_cmd_agent
