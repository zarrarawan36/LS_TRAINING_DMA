`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// j3_cmd_if : command channel interface for j3_mm_rd
//   DUT ports: cmd (in, j3_cmd_t), cmd_valid (in), cmd_ready (out)
//   Suggested config_db name: "cmd_vif"
// Spec references: SPEC-00 (valid/ready command channel), SPEC-06, tb_connections
// -----------------------------------------------------------------------------
interface j3_cmd_if (input logic clk, input logic rst_n);

  import j3_pkg::*;

  j3_cmd_t cmd;
  logic       valid;   // cmd_valid
  logic       ready;   // cmd_ready

  // Driver clocking (TB drives command payload/valid, samples ready)
  clocking cb_drv @(posedge clk);
    default input #1step output #0;
    output cmd;
    output valid;
    input  ready;
  endclocking

  // Monitor clocking (samples all channel signals)
  clocking cb_mon @(posedge clk);
    default input #1step output #0;
    input cmd;
    input valid;
    input ready;
  endclocking

  modport drv (clocking cb_drv, input clk, input rst_n);
  modport mon (clocking cb_mon, input clk, input rst_n);

  // Optional protocol checks (enable/refine as needed)
  // property p_cmd_stable;
  //   @(posedge clk) disable iff (!rst_n)
  //     (valid && !ready) |=> (valid && $stable(cmd));
  // endproperty
  // assert property (p_cmd_stable);

endinterface : j3_cmd_if