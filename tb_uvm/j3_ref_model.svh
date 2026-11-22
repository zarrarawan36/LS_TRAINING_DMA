// -----------------------------------------------------------------------------
// j3_ref_model : reference model (predicts what the DUT should do)
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06
// -----------------------------------------------------------------------------
//
//   Keep it SIMPLE: plain SystemVerilog that computes the expected result
//   from the stimulus, written from the spec (never from the RTL).
//   Typical shape: a function that takes what went IN and returns what must
//   come OUT (expected beats, expected memory bytes, expected register value,
//   expected status). The scoreboard calls it.
// -----------------------------------------------------------------------------
class j3_ref_model extends uvm_object;

  `uvm_object_utils(j3_ref_model)

  function new(string name = "j3_ref_model");
    super.new(name);
  endfunction

  // TODO: state variables (e.g. register values, memory image)
  // TODO: predict functions

endclass : j3_ref_model
