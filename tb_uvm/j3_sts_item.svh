// -----------------------------------------------------------------------------
// j3_sts_item : transaction for the 'sts' port group
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06 port table (valid/ready status channel, SPEC-00 status channel + handshake rules)
// -----------------------------------------------------------------------------
//
// Ports of this group (from the DUT port table):
//     sts              DUT output (you sample)  sgdma_sts_t  struct from sgdma_pkg
//     sts_valid        DUT output (you sample)  logic
//     sts_ready        DUT input  (you drive)  logic
//
// TODO: decide what ONE transaction of this group is and add its
//               fields as 'rand' variables (things you drive) or plain
//               variables (things the monitor observes). Add constraints for
//               legal values, convert2string() for printing and do_copy().
// -----------------------------------------------------------------------------
class j3_sts_item extends uvm_sequence_item;

  `uvm_object_utils(j3_sts_item)

  // TODO: fields

  function new(string name = "j3_sts_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return "TODO: print the fields";
  endfunction

endclass : j3_sts_item
