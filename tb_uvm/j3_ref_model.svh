// -----------------------------------------------------------------------------
// j3_ref_model : reference model for sgdma_mm_rd (SPEC-06)
//
// Predicts expected AXI read address phases, DOUT beats, and STS from a
// command and memory/error state. Written from the spec, not the RTL.
// -----------------------------------------------------------------------------
class j3_ref_model extends uvm_object;

  `uvm_object_utils(j3_ref_model)

  function new(string name = "j3_ref_model");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static function bit is_illegal_cmd(input j3_cmd_item cmd);
    if (cmd == null) return 1'b1;
    return (cmd.len_bytes == 16'd0) || (cmd.addr[1:0] != 2'b00);
  endfunction

  static function bit [3:0] final_keep(input int unsigned nbytes);
    case (nbytes)
      1:       return 4'b0001;
      2:       return 4'b0011;
      3:       return 4'b0111;
      default: return 4'b1111;
    endcase
  endfunction

  static function int unsigned beats_to_4kb(input bit [31:0] addr);
    bit [31:0] next_4kb;
    int unsigned bytes_left;
    next_4kb   = {addr[31:12] + 20'd1, 12'h000}; 
    bytes_left = int'(next_4kb - addr);
    return bytes_left / 4;
  endfunction

  static function int unsigned burst_beats(input bit [31:0] addr,
                                           input bit [15:0] remaining_bytes,
                                           input bit        inc_addr);
    int unsigned beats;
    int unsigned b4k;
    beats = int'((remaining_bytes + 16'd3) / 16'd4); // ceil(remaining_bytes/4)
    if (beats > 16) beats = 16;
    if (inc_addr) begin
      b4k = beats_to_4kb(addr);
      if (b4k == 0) b4k = 1;
      if (beats > b4k) beats = b4k;
    end
    if (beats == 0) beats = 1;
    return beats;
  endfunction

  static function bit [31:0] read_word32(input virtual axi_mem_bd_if mem_vif,
                                         input bit [31:0] addr);
    if (mem_vif == null) return 32'h0;
    return mem_vif.read_word(addr);
  endfunction

  // ---------------------------------------------------------------------------
  // Predict expected AXI AR sequence, DOUT beats, and STS for one command.
  //
  // Memory reads use mem_vif backdoor. Error injection is modeled by checking
  // mem_vif.in_error_range(beat_addr) for each beat address.
  // ---------------------------------------------------------------------------
  virtual function void predict(input j3_cmd_item cmd,
                                input virtual axi_mem_bd_if mem_vif,
                                output axi4_addr_item exp_ar[$],
                                output j3_dout_item   exp_dout[$],
                                output j3_sts_item    exp_sts);
    bit [31:0]   cur_addr;
    bit [15:0]   rem_bytes;
    bit [15:0]   ok_bytes;
    bit          err_seen;
    bit          done;
    int unsigned nbeats;
    axi4_addr_item ar;
    j3_dout_item   db;

    exp_ar.delete();
    exp_dout.delete();
    exp_sts = j3_sts_item::type_id::create("exp_sts");

    if (cmd == null) begin
      exp_sts.desc_id    = '0;
      exp_sts.eop_seen   = 1'b0;
      exp_sts.err        = 1'b1;
      exp_sts.bytes_done = 16'd0;
      return;
    end

    // MRD-CMD-002 / MRD-STS-002: illegal command => no AR, no DOUT, err status.
    if (is_illegal_cmd(cmd)) begin
      exp_sts.desc_id    = cmd.desc_id;
      exp_sts.eop_seen   = 1'b0;
      exp_sts.err        = 1'b1;
      exp_sts.bytes_done = 16'd0;
      return;
    end

    cur_addr = cmd.addr;
    rem_bytes = cmd.len_bytes;
    ok_bytes  = 16'd0;
    err_seen  = 1'b0;
    done      = 1'b0;

    while (!done) begin
      nbeats = burst_beats(cur_addr, rem_bytes, cmd.inc_addr);

      // Expected AR phase for this burst.
      ar = axi4_addr_item::type_id::create($sformatf("exp_ar_%0d", exp_ar.size()));
      ar.rw    = AXI4_READ; 
      ar.addr  = cur_addr;
      ar.len   = nbeats - 1;
      ar.size  = 3'd2; // ARSIZE=2 (32-bit beats)
      ar.burst = cmd.inc_addr ? AXI4_BURST_INCR : AXI4_BURST_FIXED;
      exp_ar.push_back(ar);

      for (int unsigned i = 0; i < nbeats; i++) begin
        bit [31:0] beat_addr;
        bit [31:0] rdata;
        bit        rbad;
        bit [15:0] beat_bytes;
        bit        is_last_cmd_beat;
        bit        is_last_burst_beat;

        beat_addr = cmd.inc_addr ? (cur_addr + (i * 4)) : cur_addr;  // cur + 4 for incr and cur for fixed
        rbad      = (mem_vif != null) ? mem_vif.in_error_range(beat_addr) : 1'b0;`// Check for read errors
        rdata     = rbad ? 32'h0 : read_word32(mem_vif, beat_addr); // Read data from memory or return 0 on error
        beat_bytes = (rem_bytes > 16'd4) ? 16'd4 : rem_bytes;  
        is_last_cmd_beat   = (rem_bytes <= 16'd4); 
        is_last_burst_beat = (i == nbeats - 1); 

        db = j3_dout_item::type_id::create($sformatf("exp_dout_%0d", exp_dout.size()));
        db.data = rdata;
        db.keep = is_last_cmd_beat ? final_keep(int'(beat_bytes)) : 4'hF;
        
        // MRD-ERR-001: on error, last beat of that burst carries dout_last=1.
        db.last = is_last_cmd_beat || (is_last_burst_beat && (err_seen || rbad));
        exp_dout.push_back(db);

        if (rbad)
          err_seen = 1'b1;
        else if (!err_seen)
          ok_bytes += beat_bytes;

        rem_bytes -= beat_bytes;

        if (is_last_burst_beat) begin
          if (err_seen || rem_bytes == 0) begin
            done = 1'b1;
          end else begin
            // MRD-BRS-002: next INCR burst starts at prev address + 4*beats.
            cur_addr = cmd.inc_addr ? (cur_addr + (nbeats * 4)) : cur_addr;
          end
        end
      end
    end

    // MRD-STS-002
    exp_sts.desc_id    = cmd.desc_id;
    exp_sts.eop_seen   = 1'b0;
    exp_sts.err        = err_seen;
    exp_sts.bytes_done = ok_bytes;
  endfunction

endclass : j3_ref_model
