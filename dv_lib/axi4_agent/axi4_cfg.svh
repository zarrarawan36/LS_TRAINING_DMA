// -----------------------------------------------------------------------------
// axi4_cfg : configuration object for axi4_agent (passive)
// -----------------------------------------------------------------------------
class axi4_cfg extends uvm_object;

  virtual axi4_if vif;

  // Print every complete burst at UVM_MEDIUM
  bit             trace = 1'b0;

  `uvm_object_utils(axi4_cfg)

  function new(string name = "axi4_cfg");
    super.new(name);
  endfunction

endclass : axi4_cfg
