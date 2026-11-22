// -----------------------------------------------------------------------------
// j3_coverage : functional coverage collector
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : your test plan, section Coverage
// -----------------------------------------------------------------------------
//
//   One covergroup per thing you want to measure (lengths, addresses near a
//   4 KB boundary, register x access type, back-pressure seen, error
//   responses, ...). Sample it in write_*() functions fed by the monitors,
//   exactly like the scoreboard. Each coverpoint should map to a row of the
//   Coverage section of your test plan.
// -----------------------------------------------------------------------------
class j3_coverage extends uvm_component;

  `uvm_component_utils(j3_coverage)

  // TODO: analysis imps (same pattern as the scoreboard)
  // TODO: covergroups, constructed in new()

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : j3_coverage
