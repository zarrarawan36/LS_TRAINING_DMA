// -----------------------------------------------------------------------------
// j3_cmd_item : transaction for the 'cmd' port group
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06 port table (valid/ready command channel, SPEC-00 command channel + handshake rules)
// -----------------------------------------------------------------------------
//
// Ports of this group (from the DUT port table):
//     cmd              DUT input  (you drive)  sgdma_cmd_t  struct from sgdma_pkg
//     cmd_valid        DUT input  (you drive)  logic
//     cmd_ready        DUT output (you sample)  logic
//
// TODO: decide what ONE transaction of this group is and add its
//               fields as 'rand' variables (things you drive) or plain
//               variables (things the monitor observes). Add constraints for
//               legal values, convert2string() for printing and do_copy().
// -----------------------------------------------------------------------------
class j3_cmd_item extends uvm_sequence_item;

  `uvm_object_utils(j3_cmd_item)

  // TODO: fields

  function new(string name = "j3_cmd_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return "TODO: print the fields";
  endfunction

endclass : j3_cmd_item
