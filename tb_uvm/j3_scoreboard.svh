// -----------------------------------------------------------------------------
// j3_scoreboard : compares DUT behaviour with the reference model
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : SPEC-06
// -----------------------------------------------------------------------------
//
//   1. One analysis_imp per monitor you connect. With several inputs use the
//      imp_decl macros (they must be OUTSIDE the class), e.g.
//        `uvm_analysis_imp_decl(_in)
//        `uvm_analysis_imp_decl(_out)
//        uvm_analysis_imp_in  #(<item>, j3_scoreboard) in_imp;
//        function void write_in(<item> t);  ... endfunction
//   2. In write_*(): store expected results (queue) / compare actual ones.
//   3. Count matches and mismatches; `uvm_error on every mismatch with a
//      message that says WHAT differed and the spec requirement ID.
//   4. check_phase: anything still expected but never seen is an error.
// -----------------------------------------------------------------------------
class j3_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(j3_scoreboard)

  j3_ref_model ref_model;
  int unsigned  n_match;
  int unsigned  n_mismatch;

  // TODO: analysis imps

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ref_model = j3_ref_model::type_id::create("ref_model");
    // TODO: create your imps
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    // TODO: report leftovers (expected items never observed)
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("matches=%0d mismatches=%0d", n_match, n_mismatch), UVM_LOW)
  endfunction

endclass : j3_scoreboard
