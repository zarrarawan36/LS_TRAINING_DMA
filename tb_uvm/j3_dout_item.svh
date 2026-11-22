// -----------------------------------------------------------------------------
// j3_dout_item : transaction for the 'dout' port group
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06 port table (valid/ready data-beat channel, SPEC-00 data-beat channel)
// -----------------------------------------------------------------------------
//
// Ports of this group (from the DUT port table):
//     dout_data        DUT output (you sample)  logic [31:0]
//     dout_keep        DUT output (you sample)  logic [3:0]
//     dout_last        DUT output (you sample)  logic
//     dout_valid       DUT output (you sample)  logic
//     dout_ready       DUT input  (you drive)  logic
//
// TODO: decide what ONE transaction of this group is and add its
//               fields as 'rand' variables (things you drive) or plain
//               variables (things the monitor observes). Add constraints for
//               legal values, convert2string() for printing and do_copy().
// -----------------------------------------------------------------------------
class j3_dout_item extends uvm_sequence_item;

  `uvm_object_utils(j3_dout_item)

  // TODO: fields

  function new(string name = "j3_dout_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return "TODO: print the fields";
  endfunction

endclass : j3_dout_item
