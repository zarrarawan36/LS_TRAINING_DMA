// -----------------------------------------------------------------------------
// j3_dout_item : transaction for the 'dout' port group (data-beat channel)
//
// STATUS : initial implementation (fields/printing/compare/copy)
// Spec   : SPEC-00 data-beat channel, SPEC-06 (MRD-DAT-*, MRD-ERR-*)
// -----------------------------------------------------------------------------
// One transaction represents one accepted data beat (valid && ready):
//   data/keep/last are DUT outputs sampled by the monitor; ready is TB-driven.
// -----------------------------------------------------------------------------
class j3_dout_item extends uvm_sequence_item;

  bit [31:0] data;
  bit [3:0]  keep;
  bit        last;

  `uvm_object_utils_begin(j3_dout_item)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(keep, UVM_ALL_ON)
    `uvm_field_int(last, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "j3_dout_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("dout{data=0x%08h keep=0x%1h last=%0b}", data, keep, last);
  endfunction

  // Count bytes indicated valid by keep mask.
  virtual function int unsigned num_valid_bytes();
    int unsigned n;
    n = 0;
    foreach (keep[i]) begin
      if (keep[i]) n++;
    end
    return n;
  endfunction

endclass : j3_dout_item