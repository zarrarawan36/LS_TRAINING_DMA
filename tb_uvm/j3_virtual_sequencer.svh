// -----------------------------------------------------------------------------
// j3_virtual_sequencer : virtual sequencer for J3 MM-RD
//
// Holds handles to channel sequencers and shared resources for virtual
// sequences coordinating stimulus across agents.
// -----------------------------------------------------------------------------
class j3_virtual_sequencer extends uvm_sequencer;

  `uvm_component_utils(j3_virtual_sequencer)

  j3_cmd_sequencer  cmd_sqr;
  j3_dout_sequencer dout_sqr;
  j3_sts_sequencer  sts_sqr;

  // Shared resources for virtual sequences
  virtual axi_mem_bd_if mem_vif;
  virtual rst_if        rst_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : j3_virtual_sequencer
