`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// sgdma_clk_rst : clock and reset generator (simulation model, golden)
// Spec reference : SPEC-02 Clock and Reset
//
//   clk   : free-running, CLK_PERIOD_NS period, 50 % duty, starts low
//   rst_n : low from time 0; released synchronously after RESET_CYCLES
//           rising clock edges. Raising rst_req asserts rst_n immediately;
//           after rst_req falls, rst_n is released again after RESET_CYCLES
//           rising edges.
// -----------------------------------------------------------------------------
module sgdma_clk_rst #(
  parameter real CLK_PERIOD_NS = 10.0,
  parameter int  RESET_CYCLES  = 5
) (
  input  logic rst_req,
  output logic clk,
  output logic rst_n
);

  /* verilator lint_off PROCASSINIT */
  logic clk_q   = 1'b0;
  logic rst_n_q = 1'b0;
  int   cnt_q   = 0;
  /* verilator lint_on PROCASSINIT */

  initial begin
    forever #(CLK_PERIOD_NS / 2.0) clk_q = ~clk_q;
  end

  always @(posedge clk_q or posedge rst_req) begin
    if (rst_req) begin
      rst_n_q <= 1'b0;
      cnt_q   <= 0;
    end else if (!rst_n_q) begin
      if (cnt_q >= RESET_CYCLES - 1) rst_n_q <= 1'b1;
      else                           cnt_q   <= cnt_q + 1;
    end
  end

  assign clk   = clk_q;
  assign rst_n = rst_n_q;

endmodule : sgdma_clk_rst
