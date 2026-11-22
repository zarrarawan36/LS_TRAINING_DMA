// -----------------------------------------------------------------------------
// j3_sts_item : transaction for the 'sts' port group (status channel)
//
// STATUS : initial implementation (fields/printing/compare/copy)
// Spec   : SPEC-00 status channel, SPEC-06 (MRD-STS-*, MRD-CMD-002, MRD-ERR-*)
// -----------------------------------------------------------------------------
// One transaction represents one accepted status handshake (valid && ready):
//   sts payload: desc_id, eop_seen, err, bytes_done (DUT outputs)
// For mm_rd, eop_seen is 0; illegal cmd => err=1, bytes_done=0, eop_seen=0.
// -----------------------------------------------------------------------------
class j3_sts_item extends uvm_sequence_item;

  bit [7:0]  desc_id;
  bit        eop_seen;
  bit        err;
  bit [15:0] bytes_done;

  `uvm_object_utils_begin(j3_sts_item)
    `uvm_field_int(desc_id,    UVM_ALL_ON)
    `uvm_field_int(eop_seen,   UVM_ALL_ON)
    `uvm_field_int(err,        UVM_ALL_ON)
    `uvm_field_int(bytes_done, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "j3_sts_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("sts{desc_id=0x%0h eop_seen=%0b err=%0b bytes_done=%0d}",
                     desc_id, eop_seen, err, bytes_done);
  endfunction

endclass : j3_sts_item