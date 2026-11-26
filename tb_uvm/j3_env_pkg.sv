`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// j3_env_pkg : your environment package
//
// STATUS : SKELETON. Add new files to the include list in dependency order
//          (a class must be included before the classes that use it).
// Your interfaces are NOT in a package: list them in sim/my_tb.f BEFORE
// this file.
// -----------------------------------------------------------------------------
package j3_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sgdma_pkg::*;
  import axi4_agent_pkg::*;

  `include "j3_cmd_item.svh"
  `include "j3_cmd_driver.svh"
  `include "j3_cmd_monitor.svh"
  `include "j3_cmd_agent.svh"
  `include "j3_dout_item.svh"
  `include "j3_dout_driver.svh"
  `include "j3_dout_monitor.svh"
  `include "j3_dout_agent.svh"
  `include "j3_sts_item.svh"
  `include "j3_sts_driver.svh"
  `include "j3_sts_monitor.svh"
  `include "j3_sts_agent.svh"
  `include "j3_ref_model.svh"
  `include "j3_scoreboard.svh"
  `include "j3_coverage.svh"
  `include "j3_virtual_sequencer.svh"
  `include "j3_env.svh"
  `include "j3_seq_lib.svh"

endpackage : j3_env_pkg
