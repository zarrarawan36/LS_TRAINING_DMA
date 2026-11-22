`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// rst_if : testbench handle on sgdma_clk_rst
// Spec reference : SPEC-02 Clock and Reset
//
// rst_req is connected to sgdma_clk_rst.rst_req in tb_top.
//   wait_reset_released() : blocks until rst_n is 1, then one more clk edge
//   apply_reset(n)        : holds rst_req for n clk cycles; rst_n goes low
//                           immediately and is released RESET_CYCLES rising
//                           edges after rst_req falls
// -----------------------------------------------------------------------------
interface rst_if (input logic clk, input logic rst_n);

  logic rst_req;

  initial rst_req = 1'b0;

  task automatic wait_reset_released();
    while (rst_n !== 1'b1) @(posedge clk);
    @(posedge clk);
  endtask

  task automatic apply_reset(input int unsigned cycles = 2);
    @(posedge clk);
    rst_req <= 1'b1;
    repeat (cycles) @(posedge clk);
    rst_req <= 1'b0;
    wait_reset_released();
  endtask

endinterface : rst_if
