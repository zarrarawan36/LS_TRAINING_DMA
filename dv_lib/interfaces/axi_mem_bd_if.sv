`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// axi_mem_bd_if : backdoor access to the sgdma_axi_mem instance
// Spec reference : SPEC-03 Memory Model (Backdoor API)
//
// RULE: instantiate this interface in the SAME module as the memory model and
//       name the memory instance "u_mem". The functions below reach the model
//       through an upward hierarchical reference (u_mem.<function>).
//
// Backdoor accesses take zero simulation time and bypass the AXI bus: the
// monitor does not see them. Use them to preload source buffers / descriptor
// chains and to check destination buffers.
// -----------------------------------------------------------------------------
interface axi_mem_bd_if ();

  function automatic void write_byte(input bit [31:0] addr, input bit [7:0] data);
    u_mem.write_byte(addr, data);
  endfunction

  function automatic bit [7:0] read_byte(input bit [31:0] addr);
    return u_mem.read_byte(addr);
  endfunction

  // Little-endian: data[7:0] goes to addr, data[31:24] to addr+3
  function automatic void write_word(input bit [31:0] addr, input bit [31:0] data);
    u_mem.write_word(addr, data);
  endfunction

  function automatic bit [31:0] read_word(input bit [31:0] addr);
    return u_mem.read_word(addr);
  endfunction

  // Forget every byte written so far (all bytes read back as 0)
  function automatic void clear_all();
    u_mem.clear_all();
  endfunction

  // ERROR INJECTION KNOB
  // Every beat whose (word) address falls inside [lo, hi] is answered with an
  // error. The address compared is the beat address (start address of the
  // burst, +4 per beat for INCR, the same address for FIXED).
  //   read  beat : RRESP = SLVERR and RDATA = 0 for that beat; the burst goes on
  //   write beat : the beat is NOT stored; BRESP = SLVERR for the whole burst
  // One window at a time; calling it again moves the window. May be called at
  // any time during a test (takes effect on the next beat).
  //   example: mem_vif.set_error_range(32'h0000_4000, 32'h0000_4003);  // one word
  function automatic void set_error_range(input bit [31:0] lo, input bit [31:0] hi);
    u_mem.set_error_range(lo, hi);
  endfunction

  // Switch error injection off again (every beat answers OKAY)
  function automatic void clear_error_range();
    u_mem.clear_error_range();
  endfunction

  // STALL KNOB (timing only, data is never affected)
  // pct = percentage (0..90, larger values are clipped to 90) of clock cycles
  // in which the memory holds AWREADY, WREADY, ARREADY low and inserts idle
  // cycles between read beats (RVALID low). Each channel rolls its own dice
  // every cycle. 0 = no stalls (default). May be changed at any time, e.g.
  // random per test or per transfer, to stretch the time a transfer takes.
  function automatic void set_stall_pct(input int unsigned pct);
    u_mem.set_stall_pct(pct);
  endfunction

  function automatic bit in_error_range(input bit [31:0] addr);
    return u_mem.in_error_range(addr);
  endfunction

endinterface : axi_mem_bd_if
