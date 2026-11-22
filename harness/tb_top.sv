`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// tb_top : J3 testbench top for sgdma_mm_rd  (PROVIDED, PARTIALLY WIRED)
// Spec reference : TB connections page + harness guide (docs/, linked from README.html)
//
// ALREADY WIRED FOR YOU (do not change):
//   sgdma_clk_rst (clk, rst_n), rst_if, sgdma_axi_mem + backdoor (mem_if_i)
//   axi4_if axi_if_i  : AXI4 read master port m_axi_ar* / r* to sgdma_axi_mem
//   config_db::set of the provided virtual interfaces, run_test()
//
// YOUR JOB (search for 'TODO'):
//   [1/3] declare YOUR interfaces for the simple ports
//   [2/3] connect them to the DUT (replace every ph_* placeholder)
//   [3/3] uvm_config_db::set your virtual interfaces
//   then delete the ph_* placeholder declarations and rerun:  cd sim && make run
//
// config_db names already set here:
//   "rst_vif" "mem_vif" "axi_vif"
// -----------------------------------------------------------------------------
`include "uvm_macros.svh"

module tb_top;

  import uvm_pkg::*;
  import sgdma_pkg::*;
  import j3_harness_pkg::*;

  logic clk;
  logic rst_n;

  // ---------------------------------------------------------------------------
  // Provided interfaces (already wired)
  // ---------------------------------------------------------------------------
  rst_if        rst_if_i (.clk(clk), .rst_n(rst_n));
  axi4_if       axi_if_i (.clk(clk), .rst_n(rst_n));
  axi_mem_bd_if mem_if_i ();   // backdoor, must sit next to u_mem

  sgdma_clk_rst #(.CLK_PERIOD_NS(10.0), .RESET_CYCLES(5)) u_clk_rst (
    .rst_req (rst_if_i.rst_req),
    .clk     (clk),
    .rst_n   (rst_n)
  );

  // this DUT has no AXI write channels: memory-model write inputs tied off
  assign axi_if_i.awaddr   = '0;
  assign axi_if_i.awlen    = '0;
  assign axi_if_i.awsize   = '0;
  assign axi_if_i.awburst  = '0;
  assign axi_if_i.awvalid  = 1'b0;
  assign axi_if_i.wdata    = '0;
  assign axi_if_i.wstrb    = '0;
  assign axi_if_i.wlast    = 1'b0;
  assign axi_if_i.wvalid   = 1'b0;
  assign axi_if_i.bready   = 1'b1;

  // ===========================================================================
  // TODO [1/3]: declare your interfaces here
  //   One interface per signal group listed on the TB connections page, e.g.
  //     my_cmd_if cmd_if_i (.clk(clk), .rst_n(rst_n));
  // ===========================================================================


  // ---------------------------------------------------------------------------
  // PLACEHOLDERS: keep the DUT compiling until your interfaces exist.
  // Delete each line once its DUT port is connected to your interface.
  // ---------------------------------------------------------------------------
  // group 'cmd': command  (suggested config_db name "cmd_vif")
  sgdma_cmd_t ph_cmd = '0;                 // TODO: DUT input, tied off -> connect to your interface
  logic ph_cmd_valid = 1'b0;               // TODO: DUT input, tied off -> connect to your interface
  logic ph_cmd_ready;                      // TODO: DUT output, unused -> connect to your interface
  // group 'dout': dout data beats (the DUT SENDS beats, you drive ready)  (suggested config_db name "dout_vif")
  logic [31:0] ph_dout_data;               // TODO: DUT output, unused -> connect to your interface
  logic [3:0] ph_dout_keep;                // TODO: DUT output, unused -> connect to your interface
  logic ph_dout_last;                      // TODO: DUT output, unused -> connect to your interface
  logic ph_dout_valid;                     // TODO: DUT output, unused -> connect to your interface
  logic ph_dout_ready = 1'b0;              // TODO: DUT input, tied off -> connect to your interface
  // group 'sts': status  (suggested config_db name "sts_vif")
  sgdma_sts_t ph_sts;                      // TODO: DUT output, unused -> connect to your interface
  logic ph_sts_valid;                      // TODO: DUT output, unused -> connect to your interface
  logic ph_sts_ready = 1'b0;               // TODO: DUT input, tied off -> connect to your interface

  // ---------------------------------------------------------------------------
  // DUT
  // TODO [2/3]: connect them to the DUT here
  //   replace every ph_<port> with <your_if_instance>.<signal>
  // ---------------------------------------------------------------------------
  sgdma_mm_rd u_dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .cmd           (ph_cmd),
    .cmd_valid     (ph_cmd_valid),
    .cmd_ready     (ph_cmd_ready),
    .m_axi_araddr  (axi_if_i.araddr),
    .m_axi_arlen   (axi_if_i.arlen),
    .m_axi_arsize  (axi_if_i.arsize),
    .m_axi_arburst (axi_if_i.arburst),
    .m_axi_arvalid (axi_if_i.arvalid),
    .m_axi_arready (axi_if_i.arready),
    .m_axi_rdata   (axi_if_i.rdata),
    .m_axi_rresp   (axi_if_i.rresp),
    .m_axi_rlast   (axi_if_i.rlast),
    .m_axi_rvalid  (axi_if_i.rvalid),
    .m_axi_rready  (axi_if_i.rready),
    .dout_data     (ph_dout_data),
    .dout_keep     (ph_dout_keep),
    .dout_last     (ph_dout_last),
    .dout_valid    (ph_dout_valid),
    .dout_ready    (ph_dout_ready),
    .sts           (ph_sts),
    .sts_valid     (ph_sts_valid),
    .sts_ready     (ph_sts_ready)
  );

  sgdma_axi_mem #(.RD_LATENCY(2), .WR_RESP_LATENCY(1)) u_mem (
    .clk           (clk),
    .rst_n         (rst_n),
    .s_axi_awaddr   (axi_if_i.awaddr),
    .s_axi_awlen    (axi_if_i.awlen),
    .s_axi_awsize   (axi_if_i.awsize),
    .s_axi_awburst  (axi_if_i.awburst),
    .s_axi_awvalid  (axi_if_i.awvalid),
    .s_axi_awready  (axi_if_i.awready),
    .s_axi_wdata    (axi_if_i.wdata),
    .s_axi_wstrb    (axi_if_i.wstrb),
    .s_axi_wlast    (axi_if_i.wlast),
    .s_axi_wvalid   (axi_if_i.wvalid),
    .s_axi_wready   (axi_if_i.wready),
    .s_axi_bresp    (axi_if_i.bresp),
    .s_axi_bvalid   (axi_if_i.bvalid),
    .s_axi_bready   (axi_if_i.bready),
    .s_axi_araddr   (axi_if_i.araddr),
    .s_axi_arlen    (axi_if_i.arlen),
    .s_axi_arsize   (axi_if_i.arsize),
    .s_axi_arburst  (axi_if_i.arburst),
    .s_axi_arvalid  (axi_if_i.arvalid),
    .s_axi_arready  (axi_if_i.arready),
    .s_axi_rdata    (axi_if_i.rdata),
    .s_axi_rresp    (axi_if_i.rresp),
    .s_axi_rlast    (axi_if_i.rlast),
    .s_axi_rvalid   (axi_if_i.rvalid),
    .s_axi_rready   (axi_if_i.rready)
  );

  initial begin
    // provided virtual interfaces
    uvm_config_db#(virtual rst_if)::set(null, "*", "rst_vif", rst_if_i);
    uvm_config_db#(virtual axi_mem_bd_if)::set(null, "*", "mem_vif", mem_if_i);
    uvm_config_db#(virtual axi4_if)::set(null, "*", "axi_vif", axi_if_i);

    // =========================================================================
    // TODO [3/3]: uvm_config_db::set your vifs here (BEFORE run_test)
    //   e.g.
    //   uvm_config_db#(virtual my_cmd_if)::set(null, "*", "cmd_vif", cmd_if_i);
    // =========================================================================

    run_test();
  end

  `include "tb_top_common.svh"

endmodule : tb_top
