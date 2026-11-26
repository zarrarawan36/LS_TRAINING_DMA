// -----------------------------------------------------------------------------
// j3_env : the environment: agents + scoreboard + coverage
//
// Spec   : TB connection guide in docs/, dv_lib package headers (usage examples)
// -----------------------------------------------------------------------------
class j3_env extends uvm_env;

  `uvm_component_utils(j3_env)

  // Provided passive AXI4 monitor agent (axi4_agent_pkg)
  axi4_cfg   axi_cfg;
  axi4_agent axi_agt;

  // J3 channel agents
  j3_cmd_agent  cmd_agt;
  j3_dout_agent dout_agt;
  j3_sts_agent  sts_agt;

  j3_scoreboard scb;
  j3_coverage   cov;

  // Virtual sequencer and shared resources
  j3_virtual_sequencer  vseqr;
  virtual axi_mem_bd_if mem_vif;
  virtual rst_if        rst_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Passive AXI4 monitor
    axi_cfg = axi4_cfg::type_id::create("axi_cfg");
    if (!uvm_config_db#(virtual axi4_if)::get(this, "", "axi_vif", axi_cfg.vif))
      `uvm_fatal("J3_ENV", "axi_vif not found in config_db")
    axi_agt = axi4_agent::type_id::create("axi_agt", this);
    axi_agt.is_active = UVM_PASSIVE;
    uvm_config_db#(axi4_cfg)::set(this, "axi_agt", "cfg", axi_cfg);

    // Memory backdoor and reset interface (optional but expected in harness)
    if (!uvm_config_db#(virtual axi_mem_bd_if)::get(this, "", "mem_vif", mem_vif))
      `uvm_fatal("J3_ENV", "mem_vif not found in config_db")
    void'(uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", rst_vif));

    // Channel agents (active by default: monitor always, driver/sequencer when active)
    cmd_agt  = j3_cmd_agent::type_id::create("cmd_agt",  this);
    dout_agt = j3_dout_agent::type_id::create("dout_agt", this);
    sts_agt  = j3_sts_agent::type_id::create("sts_agt",  this);

    scb   = j3_scoreboard::type_id::create("scb", this);
    cov   = j3_coverage::type_id::create("cov", this);
    vseqr = j3_virtual_sequencer::type_id::create("vseqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Monitor analysis connections to scoreboard
    if (cmd_agt != null && cmd_agt.ap != null)
      cmd_agt.ap.connect(scb.cmd_imp);
    if (dout_agt != null && dout_agt.ap != null)
      dout_agt.ap.connect(scb.dout_imp);
    if (sts_agt != null && sts_agt.ap != null)
      sts_agt.ap.connect(scb.sts_imp);
    if (axi_agt != null) begin
      axi_agt.ap.connect(scb.axi_imp);
      axi_agt.addr_ap.connect(scb.axi_addr_imp);
    end

    if (scb != null) scb.mem_vif = mem_vif;

    // Virtual sequencer handles
    if (vseqr != null) begin
      if (cmd_agt != null)  vseqr.cmd_sqr  = cmd_agt.sqr;
      if (dout_agt != null) vseqr.dout_sqr = dout_agt.sqr;
      if (sts_agt != null)  vseqr.sts_sqr  = sts_agt.sqr;
      vseqr.mem_vif = mem_vif;
      vseqr.rst_vif = rst_vif;
    end

    // TODO: connect monitor analysis ports to coverage when ready.
  endfunction

endclass : j3_env
