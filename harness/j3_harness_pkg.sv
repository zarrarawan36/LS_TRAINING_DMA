`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// j3_harness_pkg : harness smoke test for J3 (PROVIDED)
//
// j3_harness_smoke_test proves that tb_top, the RTL, the memory model backdoor and the axi4_agent compile
// and run on your simulator. It uses ONLY the provided interfaces, so it must
// pass on day 1 (placeholders in tb_top) AND after you have connected your
// own interfaces. It checks nothing about the DUT behaviour.
//   cd sim && make run
// -----------------------------------------------------------------------------
package j3_harness_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sgdma_pkg::*;
  import axi4_agent_pkg::*;

  class j3_harness_smoke_test extends uvm_test;

    `uvm_component_utils(j3_harness_smoke_test)

    axi4_cfg              axi_cfg;
    axi4_agent            axi_agt;
    virtual axi_mem_bd_if mem_vif;
    virtual rst_if rst_vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", rst_vif))
        `uvm_fatal("SMOKE", "rst_vif not found in config_db: tb_top must set it")
      axi_cfg = axi4_cfg::type_id::create("axi_cfg");
      if (!uvm_config_db#(virtual axi4_if)::get(this, "", "axi_vif", axi_cfg.vif))
        `uvm_fatal("SMOKE", "axi_vif not found in config_db: tb_top must set it")
      if (!uvm_config_db#(virtual axi_mem_bd_if)::get(this, "", "mem_vif", mem_vif))
        `uvm_fatal("SMOKE", "mem_vif not found in config_db: tb_top must set it")
      axi_cfg.trace = 1'b1;
      uvm_config_db#(axi4_cfg)::set(this, "axi_agt", "cfg", axi_cfg);
      axi_agt = axi4_agent::type_id::create("axi_agt", this);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      rst_vif.wait_reset_released();
      `uvm_info("SMOKE", "reset released", UVM_LOW)
      check_mem_backdoor();
      repeat (20) @(posedge rst_vif.clk);
      phase.drop_objection(this);
    endtask

    `include "smoke_mem_check.svh"
    `include "smoke_report.svh"

  endclass : j3_harness_smoke_test

endpackage : j3_harness_pkg
