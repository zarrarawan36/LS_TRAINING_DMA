`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// j3_data_if : data-beat channel interface (used for dout)
//   DUT ports: dout_data/out, dout_keep/out, dout_last/out, dout_valid/out, dout_ready/in
//   Suggested config_db name: "dout_vif"
// Spec references: SPEC-00 (valid/ready data-beat channel), SPEC-06, tb_connections
// -----------------------------------------------------------------------------
interface j3_data_if (input logic clk, input logic rst_n);

  logic [31:0] data;   // dout_data
  logic [3:0]  keep;   // dout_keep
  logic        last;   // dout_last
  logic        valid;  // dout_valid
  logic        ready;  // dout_ready

  // Driver clocking (TB receiver drives ready, samples payload/valid)
  clocking cb_drv @(posedge clk);
    default input #1step output #0;
    input  data;
    input  keep;
    input  last;
    input  valid;
    output ready;
  endclocking

  // Monitor clocking (samples all channel signals)
  clocking cb_mon @(posedge clk);
    default input #1step output #0;
    input data;
    input keep;
    input last;
    input valid;
    input ready;
  endclocking

  modport drv (clocking cb_drv, input clk, input rst_n);
  modport mon (clocking cb_mon, input clk, input rst_n);

  // Optional protocol checks (enable/refine as needed)
  // property p_data_stable;
  //   @(posedge clk) disable iff (!rst_n)
  //     (valid && !ready) |=> (valid && $stable(data) && $stable(keep) && $stable(last));
  // endproperty
  // assert property (p_data_stable);

endinterface : j3_data_if