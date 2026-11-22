// -----------------------------------------------------------------------------
// j3_env : the environment: agents + scoreboard + coverage
//
// STATUS : SKELETON - structure only. Everything marked TODO is yours.
// Spec   : TB connection guide in docs/, dv_lib package headers (usage examples)
// -----------------------------------------------------------------------------
//
//   build_phase : create
//     axi4_agent      cfg axi4_cfg      vif "axi_vif" (passive), item axi4_item on ap
//     memory backdoor   virtual axi_mem_bd_if, vif "mem_vif" (preload / check memory)
//     reset             virtual rst_if, vif "rst_vif" (the base test already uses it)
//     j3_cmd_agent    vif "cmd_vif" (command)
//     j3_dout_agent   vif "dout_vif" (dout data beats (the DUT SENDS beats, you drive ready))
//     j3_sts_agent    vif "sts_vif" (status)
//     scoreboard, coverage
//   connect_phase : monitor analysis ports -> scoreboard / coverage imps
//
//   Keep handles public so tests can reach them (env.<agent>.sqr, env.<cfg>).
// -----------------------------------------------------------------------------
class j3_env extends uvm_env;

  `uvm_component_utils(j3_env)

  j3_scoreboard scb;
  j3_coverage   cov;

  // TODO: provided agent + cfg handles
  // TODO: your own agent handles

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb = j3_scoreboard::type_id::create("scb", this);
    cov = j3_coverage::type_id::create("cov", this);
    // TODO: cfg objects, config_db, agents
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // TODO: connect monitors to scb and cov
  endfunction

endclass : j3_env
