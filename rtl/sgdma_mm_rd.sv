`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// sgdma_mm_rd : memory-mapped read engine (AXI4 read master)
//   cmd  -> AXI4 read bursts -> data beat stream (dout_*) -> status
// Spec reference : SPEC-06 sgdma_mm_rd
// -----------------------------------------------------------------------------
module sgdma_mm_rd
  import sgdma_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,

  // Command
  input  sgdma_cmd_t  cmd,
  input  logic        cmd_valid,
  output logic        cmd_ready,

  // AXI4 read master
  output logic [31:0] m_axi_araddr,
  output logic [7:0]  m_axi_arlen,
  output logic [2:0]  m_axi_arsize,
  output logic [1:0]  m_axi_arburst,
  output logic        m_axi_arvalid,
  input  logic        m_axi_arready,
  input  logic [31:0] m_axi_rdata,
  input  logic [1:0]  m_axi_rresp,
  input  logic        m_axi_rlast,
  input  logic        m_axi_rvalid,
  output logic        m_axi_rready,

  // Data out
  output logic [31:0] dout_data,
  output logic [3:0]  dout_keep,
  output logic        dout_last,
  output logic        dout_valid,
  input  logic        dout_ready,

  // Status
  output sgdma_sts_t  sts,
  output logic        sts_valid,
  input  logic        sts_ready
);

  typedef enum logic [2:0] {
    ST_IDLE,
    ST_AR,
    ST_R,
    ST_DRAIN,
    ST_STS
  } state_e;

  state_e      state_q;
  sgdma_cmd_t  cmd_q;
  logic [31:0] addr_q;         // address of next burst
  logic [15:0] req_left_q;     // bytes not yet requested on AR
  logic [15:0] dlv_left_q;     // bytes not yet delivered on dout
  logic [15:0] ok_bytes_q;     // bytes delivered with OKAY response
  logic        err_q;
  logic [4:0]  burst_beats;
  logic        burst_issued_q; // at least one burst issued for this command

  // ---------------------------------------------------------------------------
  // Burst sizing
  // ---------------------------------------------------------------------------
  logic [15:0] beats_left;
  assign beats_left = (req_left_q + 16'd3) >> 2;


  always_comb begin
    burst_beats = (beats_left > 16'(MAX_BURST_BEATS)) ? 5'(MAX_BURST_BEATS) : beats_left[4:0];
  end

  // Final-beat byte enables
  function automatic logic [3:0] final_keep(input logic [15:0] n_bytes);
    case (n_bytes)
      16'd1:   return 4'b0011;
      16'd2:   return 4'b0011;
      16'd3:   return 4'b0111;
      default: return 4'b1111;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // AXI read address channel
  // ---------------------------------------------------------------------------
  assign m_axi_araddr  = addr_q;
  assign m_axi_arlen   = 8'(burst_beats) - 8'd1;
  assign m_axi_arsize  = AXI_SIZE_4B;
  assign m_axi_arburst = (cmd_q.inc_addr || burst_issued_q) ? AXI_BURST_INCR : AXI_BURST_FIXED;
  assign m_axi_arvalid = (state_q == ST_AR);

  // One-entry output register; R is accepted only when it can be stored
  assign m_axi_rready = (state_q == ST_R) && (!dout_valid || dout_ready);
  assign cmd_ready    = (state_q == ST_IDLE);

  wire        r_hs      = m_axi_rvalid && m_axi_rready;
  wire        r_bad     = (m_axi_rresp != AXI_RESP_OKAY);
  wire [15:0] beat_bytes = (dlv_left_q > 16'd4) ? 16'd4 : dlv_left_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q     <= ST_IDLE;
      cmd_q       <= '0;
      addr_q      <= '0;
      req_left_q  <= '0;
      dlv_left_q  <= '0;
      ok_bytes_q  <= '0;
      err_q       <= 1'b0;
      burst_issued_q <= 1'b0;
      dout_valid  <= 1'b0;
      dout_data   <= '0;
      dout_keep   <= '0;
      dout_last   <= 1'b0;
      sts_valid   <= 1'b0;
      sts         <= '0;
    end else begin
      if (dout_valid && dout_ready) dout_valid <= 1'b0;

      case (state_q)
        ST_IDLE: begin
          if (cmd_valid) begin
            cmd_q       <= cmd;
            addr_q      <= cmd.addr;
            req_left_q  <= cmd.len_bytes;
            dlv_left_q  <= cmd.len_bytes;
            ok_bytes_q  <= '0;
            err_q       <= 1'b0;
            burst_issued_q <= 1'b0;
            if ((cmd.len_bytes == 16'd0) || (cmd.addr[1:0] != 2'b00)) begin
              err_q   <= 1'b1;
              state_q <= ST_STS;
            end else begin
              state_q <= ST_AR;
            end
          end
        end

        ST_AR: begin
          if (m_axi_arready) begin
            burst_issued_q <= 1'b1;
            if (cmd_q.inc_addr) addr_q <= addr_q + 32'({burst_beats, 2'b00});
            req_left_q <= (req_left_q > {9'd0, burst_beats, 2'b00}) ?
                          (req_left_q - {9'd0, burst_beats, 2'b00}) : 16'd0;
            state_q <= ST_R;
          end
        end

        ST_R: begin
          if (r_hs) begin
            dout_valid <= 1'b1;
            dout_data  <= m_axi_rdata;
            dout_keep  <= (dlv_left_q > 16'd4) ? 4'hF : final_keep(dlv_left_q);
            dout_last  <= (dlv_left_q <= 16'd4) || (m_axi_rlast && (err_q || r_bad));
            dlv_left_q <= dlv_left_q - beat_bytes;
            if (r_bad) err_q <= 1'b1;
            else if (!err_q) ok_bytes_q <= ok_bytes_q + beat_bytes;
            if (m_axi_rlast) begin
              if (err_q || r_bad || (dlv_left_q <= 16'd4)) state_q <= ST_DRAIN;
              else                                         state_q <= ST_AR;
            end
          end
        end

        // wait until the final beat has left the output register
        ST_DRAIN: begin
          if (!dout_valid || dout_ready) state_q <= ST_STS;
        end

        ST_STS: begin
          if (!sts_valid) begin
            sts_valid      <= 1'b1;
            sts.desc_id    <= cmd_q.desc_id;
            sts.eop_seen   <= 1'b0;
            sts.err        <= err_q;
            sts.bytes_done <= ok_bytes_q;
          end else if (sts_ready) begin
            sts_valid <= 1'b0;
            state_q   <= ST_IDLE;
          end
        end

        default: state_q <= ST_IDLE;
      endcase
    end
  end

endmodule : sgdma_mm_rd
