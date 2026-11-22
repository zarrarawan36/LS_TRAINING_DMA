`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// axi4_if : AXI4 (full) signal bundle used between a DUT master and the
//           sgdma_axi_mem slave. 32-bit address / data, no ID / USER / QOS /
//           CACHE / LOCK signals (single master, one outstanding transaction).
// Spec reference : SPEC-11 DV Library, SPEC-00 Common Interfaces
//
// Driven by     : DUT master (AW/W/AR, BREADY/RREADY), sgdma_axi_mem (rest)
// Sampled by    : axi4_monitor (passive)
// -----------------------------------------------------------------------------
interface axi4_if (input logic clk, input logic rst_n);

  // Write address channel
  logic [31:0] awaddr;
  logic [7:0]  awlen;
  logic [2:0]  awsize;
  logic [1:0]  awburst;
  logic        awvalid;
  logic        awready;

  // Write data channel
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wlast;
  logic        wvalid;
  logic        wready;

  // Write response channel
  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;

  // Read address channel
  logic [31:0] araddr;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic        arvalid;
  logic        arready;

  // Read data channel
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rlast;
  logic        rvalid;
  logic        rready;

endinterface : axi4_if
