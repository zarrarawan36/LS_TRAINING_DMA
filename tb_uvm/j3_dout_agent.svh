// -----------------------------------------------------------------------------
// j3_dout_agent : agent for the 'dout' group
//
// Spec   : SPEC-00 data-beat channel handshake, SPEC-06 (MRD-DATA-*)
// -----------------------------------------------------------------------------
typedef uvm_sequencer #(j3_dout_item) j3_dout_sequencer;

class j3_dout_agent extends uvm_agent;

  `uvm_component_utils(j3_dout_agent)

  j3_dout_sequencer sqr;
  j3_dout_driver    drv;
  j3_dout_monitor   mon;

  uvm_analysis_port #(j3_dout_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = j3_dout_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = j3_dout_sequencer::type_id::create("sqr", this);
      drv = j3_dout_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass : j3_dout_agent
