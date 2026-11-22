`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// sgdma_axi_mem : AXI4 slave memory model (simulation model, golden)
// Spec reference : SPEC-03 Memory Model
//
//   - sparse byte memory, full 32-bit address space, unwritten bytes read 0
//   - one read burst and one write burst in flight (independent channels)
//   - INCR and FIXED bursts, 4-byte beats, WSTRB honoured
//   - programmable SLVERR address window, programmable ready/valid stalls
//   - backdoor functions for the testbench (see "Backdoor API")
//   - does NOT check AXI protocol rules; that is the testbench's job
// -----------------------------------------------------------------------------

module sgdma_axi_mem
  import sgdma_pkg::*;
#(
  parameter int RD_LATENCY      = 2,   // cycles from AR handshake to first RVALID
  parameter int WR_RESP_LATENCY = 1    // cycles from last W handshake to BVALID
) (
  input  logic        clk,
  input  logic        rst_n,

  // Write address
  input  logic [31:0] s_axi_awaddr,
  input  logic [7:0]  s_axi_awlen,
  input  logic [2:0]  s_axi_awsize,
  input  logic [1:0]  s_axi_awburst,
  input  logic        s_axi_awvalid,
  output logic        s_axi_awready,
  // Write data
  input  logic [31:0] s_axi_wdata,
  input  logic [3:0]  s_axi_wstrb,
  input  logic        s_axi_wlast,
  input  logic        s_axi_wvalid,
  output logic        s_axi_wready,
  // Write response
  output logic [1:0]  s_axi_bresp,
  output logic        s_axi_bvalid,
  input  logic        s_axi_bready,
  // Read address
  input  logic [31:0] s_axi_araddr,
  input  logic [7:0]  s_axi_arlen,
  input  logic [2:0]  s_axi_arsize,
  input  logic [1:0]  s_axi_arburst,
  input  logic        s_axi_arvalid,
  output logic        s_axi_arready,
  // Read data
  output logic [31:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp,
  output logic        s_axi_rlast,
  output logic        s_axi_rvalid,
  input  logic        s_axi_rready
);

  // ---------------------------------------------------------------------------
  // Storage and knobs
  // ---------------------------------------------------------------------------
  bit [7:0]    mem [bit [31:0]];
  bit          err_en    = 1'b0;
  bit [31:0]   err_lo    = '0;
  bit [31:0]   err_hi    = '0;
  int unsigned stall_pct = 0;

  // ---------------------------------------------------------------------------
  // Backdoor API (call hierarchically, e.g. tb_top.u_mem.write_word(...))
  // ---------------------------------------------------------------------------
  function automatic void write_byte(input bit [31:0] addr, input bit [7:0] data);
    mem[addr] = data;
  endfunction

  function automatic bit [7:0] read_byte(input bit [31:0] addr);
    return mem.exists(addr) ? mem[addr] : 8'h00;
  endfunction

  function automatic void write_word(input bit [31:0] addr, input bit [31:0] data);
    for (int i = 0; i < 4; i++) mem[addr + i] = data[8*i +: 8];
  endfunction

  function automatic bit [31:0] read_word(input bit [31:0] addr);
    bit [31:0] d;
    for (int i = 0; i < 4; i++) d[8*i +: 8] = read_byte(addr + i);
    return d;
  endfunction

  function automatic void clear_all();
    mem.delete();
  endfunction

  function automatic void set_error_range(input bit [31:0] lo, input bit [31:0] hi);
    err_en = 1'b1;
    err_lo = lo;
    err_hi = hi;
  endfunction

  function automatic void clear_error_range();
    err_en = 1'b0;
  endfunction

  function automatic void set_stall_pct(input int unsigned pct);
    stall_pct = (pct > 90) ? 90 : pct;
  endfunction

  function automatic bit in_error_range(input bit [31:0] addr);
    return err_en && (addr >= err_lo) && (addr <= err_hi);
  endfunction

  // Random stall source, re-rolled every cycle
  bit stall_aw, stall_w, stall_ar, stall_r;
  always @(posedge clk) begin
    stall_aw <= ($urandom_range(0, 99) < stall_pct);
    stall_w  <= ($urandom_range(0, 99) < stall_pct);
    stall_ar <= ($urandom_range(0, 99) < stall_pct);
    stall_r  <= ($urandom_range(0, 99) < stall_pct);
  end

  /* verilator lint_off BLKSEQ */
  // ---------------------------------------------------------------------------
  // Write path
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} wstate_e;
  wstate_e     wstate;
  bit [31:0]   w_base;
  bit [7:0]    w_len;
  bit [1:0]    w_burst;
  bit [7:0]    w_beat;
  bit          w_err;
  int          w_delay;

  assign s_axi_awready = (wstate == W_IDLE) && !stall_aw;
  assign s_axi_wready  = (wstate == W_DATA) && !stall_w;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wstate       <= W_IDLE;
      s_axi_bvalid <= 1'b0;
      s_axi_bresp  <= AXI_RESP_OKAY;
      w_beat       <= '0;
      w_err        <= 1'b0;
      w_delay      <= 0;
    end else begin
      case (wstate)
        W_IDLE: begin
          if (s_axi_awvalid && s_axi_awready) begin
            w_base  <= s_axi_awaddr;
            w_len   <= s_axi_awlen;
            w_burst <= s_axi_awburst;
            w_beat  <= '0;
            w_err   <= 1'b0;
            wstate  <= W_DATA;
          end
        end
        W_DATA: begin
          if (s_axi_wvalid && s_axi_wready) begin
            bit [31:0] a;
            a = (w_burst == AXI_BURST_FIXED) ? w_base : (w_base + 32'({w_beat, 2'b00}));
            if (in_error_range(a)) begin
              w_err <= 1'b1;
            end else begin
              for (int i = 0; i < 4; i++)
                if (s_axi_wstrb[i]) mem[a + i] = s_axi_wdata[8*i +: 8];
            end
            w_beat <= w_beat + 8'd1;
            if (w_beat == w_len) begin
              w_delay <= WR_RESP_LATENCY;
              wstate  <= W_RESP;
            end
          end
        end
        W_RESP: begin
          if (!s_axi_bvalid) begin
            if (w_delay > 0) begin
              w_delay <= w_delay - 1;
            end else begin
              s_axi_bvalid <= 1'b1;
              s_axi_bresp  <= w_err ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
            end
          end else if (s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            wstate       <= W_IDLE;
          end
        end
        default: wstate <= W_IDLE;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Read path
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {R_IDLE, R_WAIT, R_DATA} rstate_e;
  rstate_e     rstate;
  bit [31:0]   r_base;
  bit [7:0]    r_len;
  bit [1:0]    r_burst;
  bit [7:0]    r_beat;
  int          r_delay;

  assign s_axi_arready = (rstate == R_IDLE) && !stall_ar;

  function automatic bit [31:0] r_addr(input bit [7:0] beat);
    return (r_burst == AXI_BURST_FIXED) ? r_base : (r_base + 32'({beat, 2'b00}));
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rstate       <= R_IDLE;
      s_axi_rvalid <= 1'b0;
      s_axi_rdata  <= '0;
      s_axi_rresp  <= AXI_RESP_OKAY;
      s_axi_rlast  <= 1'b0;
      r_beat       <= '0;
      r_delay      <= 0;
    end else begin
      case (rstate)
        R_IDLE: begin
          if (s_axi_arvalid && s_axi_arready) begin
            r_base  <= s_axi_araddr;
            r_len   <= s_axi_arlen;
            r_burst <= s_axi_arburst;
            r_beat  <= '0;
            r_delay <= (RD_LATENCY > 0) ? RD_LATENCY - 1 : 0;
            rstate  <= R_WAIT;
          end
        end
        R_WAIT: begin
          if (r_delay > 0) begin
            r_delay <= r_delay - 1;
          end else begin
            rstate <= R_DATA;
          end
        end
        R_DATA: begin
          if (s_axi_rvalid && s_axi_rready) begin
            if (s_axi_rlast) begin
              s_axi_rvalid <= 1'b0;
              rstate       <= R_IDLE;
            end else begin
              r_beat <= r_beat + 8'd1;
              if (stall_r) begin
                s_axi_rvalid <= 1'b0;
              end else begin
                s_axi_rdata <= in_error_range(r_addr(r_beat + 8'd1)) ? 32'h0 : read_word(r_addr(r_beat + 8'd1));
                s_axi_rresp <= in_error_range(r_addr(r_beat + 8'd1)) ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
                s_axi_rlast <= ((r_beat + 8'd1) == r_len);
              end
            end
          end else if (!s_axi_rvalid && !stall_r) begin
            s_axi_rvalid <= 1'b1;
            s_axi_rdata  <= in_error_range(r_addr(r_beat)) ? 32'h0 : read_word(r_addr(r_beat));
            s_axi_rresp  <= in_error_range(r_addr(r_beat)) ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
            s_axi_rlast  <= (r_beat == r_len);
          end
        end
        default: rstate <= R_IDLE;
      endcase
    end
  end

  /* verilator lint_on BLKSEQ */

endmodule : sgdma_axi_mem
