// -----------------------------------------------------------------------------
// axi4_addr_item : one address-phase handshake (AW or AR)
// axi4_item      : one complete burst
//
// axi4_item fields
//   rw, addr, len (AxLEN, beats-1), size (AxSIZE), burst (AxBURST)
//   data[i], strb[i], last[i] : one entry per data beat, in bus order
//                               (strb is 4'hF for reads)
//   rresp[i]                  : per-beat read response (reads only)
//   bresp                     : write response (writes only)
//   addr_time, end_time       : AW/AR handshake time, last R / B time
//
// Helper functions
//   num_beats()      : data.size()
//   beat_addr(i)     : byte address of beat i (honours FIXED / INCR)
//   end_addr()       : last byte address touched by an INCR burst
//   crosses_4k()     : 1 if an INCR burst crosses a 4 KB boundary
//   any_error()      : 1 if any beat (read) or the B (write) is not OKAY
// -----------------------------------------------------------------------------
class axi4_addr_item extends uvm_sequence_item;

  axi4_rw_e  rw;
  bit [31:0] addr;
  bit [7:0]  len;
  bit [2:0]  size;
  bit [1:0]  burst;
  time       addr_time;

  `uvm_object_utils(axi4_addr_item)

  function new(string name = "axi4_addr_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("%s addr=0x%08h len=%0d size=%0d burst=%s",
                     (rw == AXI4_WRITE) ? "AW" : "AR", addr, len, size,
                     (burst == AXI4_BURST_FIXED) ? "FIXED" :
                     (burst == AXI4_BURST_INCR)  ? "INCR"  :
                     (burst == AXI4_BURST_WRAP)  ? "WRAP"  : "RSVD");
  endfunction

endclass : axi4_addr_item


class axi4_item extends uvm_sequence_item;

  axi4_rw_e  rw;
  bit [31:0] addr;
  bit [7:0]  len;
  bit [2:0]  size;
  bit [1:0]  burst;

  bit [31:0] data[$];
  bit [3:0]  strb[$];
  bit        last[$];
  bit [1:0]  rresp[$];
  bit [1:0]  bresp;

  time       addr_time;
  time       end_time;

  `uvm_object_utils(axi4_item)

  function new(string name = "axi4_item");
    super.new(name);
  endfunction

  function int unsigned num_beats();
    return data.size();
  endfunction

  function bit [31:0] beat_addr(int unsigned i);
    if (burst == AXI4_BURST_FIXED) return addr;
    return addr + 32'(i << size);
  endfunction

  function bit [31:0] end_addr();
    return addr + 32'(((int'(len) + 1) << size) - 1);
  endfunction

  function bit crosses_4k();
    if (burst != AXI4_BURST_INCR) return 1'b0;
    return addr[31:12] != end_addr()[31:12];
  endfunction

  function bit any_error();
    if (rw == AXI4_WRITE) return bresp != AXI4_RESP_OKAY;
    foreach (rresp[i]) if (rresp[i] != AXI4_RESP_OKAY) return 1'b1;
    return 1'b0;
  endfunction

  virtual function void do_copy(uvm_object rhs);
    axi4_item t;
    super.do_copy(rhs);
    if (!$cast(t, rhs)) `uvm_fatal("AXI4_ITEM", "do_copy: wrong type")
    rw = t.rw; addr = t.addr; len = t.len; size = t.size; burst = t.burst;
    data = t.data; strb = t.strb; last = t.last; rresp = t.rresp; bresp = t.bresp;
    addr_time = t.addr_time; end_time = t.end_time;
  endfunction

  virtual function string convert2string();
    string s;
    s = $sformatf("%s addr=0x%08h len=%0d size=%0d burst=%s beats=%0d",
                  (rw == AXI4_WRITE) ? "WR" : "RD", addr, len, size,
                  (burst == AXI4_BURST_FIXED) ? "FIXED" :
                  (burst == AXI4_BURST_INCR)  ? "INCR"  :
                  (burst == AXI4_BURST_WRAP)  ? "WRAP"  : "RSVD",
                  data.size());
    if (rw == AXI4_WRITE) s = {s, $sformatf(" bresp=%0d", bresp)};
    foreach (data[i]) begin
      s = {s, $sformatf("\n    [%0d] data=0x%08h strb=%04b last=%0b", i, data[i], strb[i], last[i])};
      if (rw == AXI4_READ) s = {s, $sformatf(" rresp=%0d", rresp[i])};
    end
    return s;
  endfunction

endclass : axi4_item
