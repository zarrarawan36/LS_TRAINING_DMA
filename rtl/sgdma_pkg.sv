`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// sgdma_pkg : shared types and constants for the SG-DMA (AXI) IP family
// Spec reference : SPEC-00 Common Interfaces, SPEC-01 Descriptor and CSR Map
// -----------------------------------------------------------------------------
package sgdma_pkg;

  // ---------------------------------------------------------------------------
  // Global parameters (IF-P001)
  // ---------------------------------------------------------------------------
  localparam int DATA_W          = 32;
  localparam int ADDR_W          = 32;
  localparam int KEEP_W          = DATA_W / 8;
  localparam int MAX_BURST_BEATS = 16;
  localparam int DESC_BYTES      = 32;

  // ---------------------------------------------------------------------------
  // AXI encodings
  // ---------------------------------------------------------------------------
  localparam logic [1:0] AXI_BURST_FIXED = 2'b00;
  localparam logic [1:0] AXI_BURST_INCR  = 2'b01;
  localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam logic [1:0] AXI_RESP_SLVERR = 2'b10;
  localparam logic [2:0] AXI_SIZE_4B     = 3'b010;

  // ---------------------------------------------------------------------------
  // Transfer modes (CSR MODE register)
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    MODE_M2M  = 2'd0,
    MODE_M2S  = 2'd1,
    MODE_S2M  = 2'd2,
    MODE_RSVD = 2'd3
  } sgdma_mode_e;

  // ---------------------------------------------------------------------------
  // Internal command channel payload (IF-C001)
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [7:0]  desc_id;    // descriptor index inside the chain
    logic        gen_eop;    // end-of-packet requested at end of this command
    logic        gen_sop;    // start-of-packet requested at start of this command
    logic        inc_addr;   // 1: INCR addressing, 0: FIXED address
    logic [15:0] len_bytes;  // number of bytes to transfer (0 is illegal)
    logic [31:0] addr;       // byte address (must be 4-byte aligned)
  } sgdma_cmd_t;

  // ---------------------------------------------------------------------------
  // Internal status channel payload (IF-C002)
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [7:0]  desc_id;     // echoes cmd.desc_id
    logic        eop_seen;    // end-of-packet was produced / observed
    logic        err;         // command finished with an error
    logic [15:0] bytes_done;  // bytes successfully transferred
  } sgdma_sts_t;

  // ---------------------------------------------------------------------------
  // Descriptor layout (DESC-F001 / DESC-F002 / DESC-F003)
  // ---------------------------------------------------------------------------
  localparam logic [4:0] DESC_OFS_SRC    = 5'h00;
  localparam logic [4:0] DESC_OFS_DST    = 5'h04;
  localparam logic [4:0] DESC_OFS_CTRL   = 5'h08;  // [15:0] length, [31:16] flags
  localparam logic [4:0] DESC_OFS_NEXT   = 5'h0C;
  localparam logic [4:0] DESC_OFS_STATUS = 5'h10;

  localparam int DESC_FLAG_OWNED   = 16;
  localparam int DESC_FLAG_INC_SRC = 17;
  localparam int DESC_FLAG_INC_DST = 18;
  localparam int DESC_FLAG_GEN_SOP = 19;
  localparam int DESC_FLAG_GEN_EOP = 20;

  localparam int DESC_STS_ERR_BIT = 16;
  localparam int DESC_STS_EOP_BIT = 17;

  // ---------------------------------------------------------------------------
  // CSR map (CSR-R001 .. CSR-R008)
  // ---------------------------------------------------------------------------
  localparam logic [7:0] CSR_CONTROL    = 8'h00;
  localparam logic [7:0] CSR_STATUS     = 8'h04;
  localparam logic [7:0] CSR_NEXT_DESC  = 8'h08;
  localparam logic [7:0] CSR_MODE       = 8'h0C;
  localparam logic [7:0] CSR_IRQ_ENABLE = 8'h10;
  localparam logic [7:0] CSR_IRQ_STATUS = 8'h14;
  localparam logic [7:0] CSR_VERSION    = 8'h18;
  localparam logic [7:0] CSR_SCRATCH    = 8'h1C;

  localparam logic [31:0] CSR_VERSION_VALUE = 32'h0001_0000;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  // Byte-enable mask for the final beat of a transfer: n_bytes in 1..4
  function automatic logic [KEEP_W-1:0] keep_mask(input logic [15:0] n_bytes);
    case (n_bytes)
      16'd1:   return 4'b0001;
      16'd2:   return 4'b0011;
      16'd3:   return 4'b0111;
      default: return 4'b1111;
    endcase
  endfunction

  function automatic logic [2:0] popcount4(input logic [3:0] v);
    return {2'b00, v[0]} + {2'b00, v[1]} + {2'b00, v[2]} + {2'b00, v[3]};
  endfunction

endpackage : sgdma_pkg
