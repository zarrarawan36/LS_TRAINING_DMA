`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// axi4_agent_pkg : PASSIVE AXI4 monitor agent (PROVIDED - use it, don't edit)
// Spec reference : SPEC-11 DV Library, section "axi4_agent"
//
// Why passive only? The AXI4 slave in your testbench is the memory model
// sgdma_axi_mem (it answers the DUT automatically). You never drive this bus;
// you only WATCH it to check what the DUT did.
//
// Files
//   axi4_item.svh    : axi4_addr_item (one AW or AR) and axi4_item (one
//                      complete burst with all its beats)
//   axi4_cfg.svh     : vif + trace
//   axi4_monitor.svh : sends axi4_addr_item on addr_ap, axi4_item on ap
//   axi4_agent.svh   : wraps the monitor
//
// Memory content is set up and checked through the BACKDOOR interface
// (axi_mem_bd_if, config_db name "mem_vif"), not through this agent.
//
// ============================ USAGE EXAMPLE ================================
// config_db vif name set by tb_top : "axi_vif"
//
//   // ---- in your env ----
//   import axi4_agent_pkg::*;
//   axi4_agent axi_agt;  axi4_cfg axi_cfg;
//   axi_cfg = axi4_cfg::type_id::create("axi_cfg");
//   if (!uvm_config_db#(virtual axi4_if)::get(this, "", "axi_vif", axi_cfg.vif))
//     `uvm_fatal("ENV", "axi_vif not found")
//   uvm_config_db#(axi4_cfg)::set(this, "axi_agt", "cfg", axi_cfg);
//   axi_agt = axi4_agent::type_id::create("axi_agt", this);
//   ...
//   axi_agt.ap.connect(scb.axi_imp);          // complete bursts
//   axi_agt.addr_ap.connect(scb.axi_addr_imp); // only if you need it
//
//   // ---- in your scoreboard write function ----
//   function void write_axi(axi4_item t);
//     if (t.crosses_4k()) `uvm_error("SCB", {"4KB crossing: ", t.convert2string()})
//     foreach (t.data[i]) ... t.beat_addr(i), t.strb[i], t.last[i] ...
//   endfunction
// ===========================================================================
package axi4_agent_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum bit {
    AXI4_READ  = 1'b0,
    AXI4_WRITE = 1'b1
  } axi4_rw_e;

  localparam bit [1:0] AXI4_BURST_FIXED = 2'b00;
  localparam bit [1:0] AXI4_BURST_INCR  = 2'b01;
  localparam bit [1:0] AXI4_BURST_WRAP  = 2'b10;
  localparam bit [1:0] AXI4_RESP_OKAY   = 2'b00;
  localparam bit [1:0] AXI4_RESP_SLVERR = 2'b10;

  `include "axi4_item.svh"
  `include "axi4_cfg.svh"
  `include "axi4_monitor.svh"
  `include "axi4_agent.svh"

endpackage : axi4_agent_pkg
