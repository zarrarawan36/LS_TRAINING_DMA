// -----------------------------------------------------------------------------
// axi4_agent : passive agent, contains only the monitor
//
//   agent.ap      : complete bursts (axi4_item)
//   agent.addr_ap : address phases  (axi4_addr_item)
// -----------------------------------------------------------------------------
class axi4_agent extends uvm_agent;

  `uvm_component_utils(axi4_agent)

  axi4_cfg     cfg;
  axi4_monitor mon;

  uvm_analysis_port #(axi4_item)      ap;
  uvm_analysis_port #(axi4_addr_item) addr_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi4_cfg)::get(this, "", "cfg", cfg) || cfg == null)
      `uvm_fatal("AXI4_AGT", "no axi4_cfg found in config_db (key \"cfg\")")
    uvm_config_db#(axi4_cfg)::set(this, "*", "cfg", cfg);
    mon = axi4_monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap      = mon.ap;
    addr_ap = mon.addr_ap;
  endfunction

endclass : axi4_agent
