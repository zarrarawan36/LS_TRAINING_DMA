tb_uvm/  -  your UVM testbench
=====================================================================

The pre-created files (j3_env_pkg.sv, j3_*.svh) give the structure;
search for "TODO" to see what you fill in.

Add here:
  interfaces for the DUT ports that have no provided agent
  your agents (item, driver, monitor, sequencer, agent)
  env + env config, scoreboard + reference model, coverage collector
  sequences

Every new file goes into ../sim/my_tb.f (interfaces before packages).
How the DUT is connected: docs/j3_mm_rd/tb_connections.html and
../harness/tb_top.sv. Provided agents and their knobs: dv_lib/ and
docs/specs/11_dv_lib_agents.html.
