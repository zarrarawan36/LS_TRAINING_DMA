`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// sgdma_sts_if : status channel interface for sgdma_mm_rd
//   DUT ports: sts (out, sgdma_sts_t), sts_valid (out), sts_ready (in)
//   Suggested config_db name: "sts_vif"
// Spec references: SPEC-00 (valid/ready status channel), SPEC-06, tb_connections
// -----------------------------------------------------------------------------
interface sgdma_sts_if (input logic clk, input logic rst_n);
  import sgdma_pkg::*;

  sgdma_sts_t sts;
  logic       valid;   // sts_valid
  logic       ready;   // sts_ready

  // Driver clocking (TB receiver drives ready, samples status/valid)
  clocking cb_drv @(posedge clk);
    default input #1step output #0;
    input  sts;
    input  valid;
    output ready;
  endclocking

  // Monitor clocking (samples all channel signals)
  clocking cb_mon @(posedge clk);
    default input #1step output #0;
    input sts;
    input valid;
    input ready;
  endclocking

  modport drv (clocking cb_drv, input clk, input rst_n);
  modport mon (clocking cb_mon, input clk, input rst_n);

  // Optional protocol checks (enable/refine as needed)
  // property p_sts_stable;
  //   @(posedge clk) disable iff (!rst_n)
  //     (valid && !ready) |=> (valid && $stable(sts));
  // endproperty
  // assert property (p_sts_stable);

endinterface : sgdma_sts_if