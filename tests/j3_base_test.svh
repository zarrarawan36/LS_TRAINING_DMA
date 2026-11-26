// -----------------------------------------------------------------------------
// j3_base_test : base class for all your tests (PROVIDED - extend it, you may
//                 add to it, keep what is here)
//
//   - builds j3_env
//   - prints the component tree (UVM_LOW) so you can check your env
//   - run_phase: raise objection, wait for reset release, call body(),
//     wait drain_cycles, drop objection
//   - report_phase: prints   *** TEST PASSED ***   or   *** TEST FAILED ***
//
// Your tests override body():
//   class j3_my_test extends j3_base_test;
//     `uvm_component_utils(j3_my_test)
//     function new(string name, uvm_component parent); super.new(name, parent); endfunction
//     virtual task body();
//       my_seq seq = my_seq::type_id::create("seq");
//       seq.start(env.<agent>.sqr);
//     endtask
//   endclass
//
// Run:  cd sim && make run TEST=j3_my_test SEED=7
// -----------------------------------------------------------------------------
class j3_base_test extends uvm_test;

  `uvm_component_utils(j3_base_test)

  j3_env        env;
  virtual rst_if rst_vif;
  int unsigned   drain_cycles = 50;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", rst_vif))
      `uvm_fatal("TEST", "rst_vif not found in config_db: tb_top must set it")
    env = j3_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rst_vif.wait_reset_released();
    body();
    repeat (drain_cycles) @(posedge rst_vif.clk); 
    phase.drop_objection(this);
  endtask

  // Override in your tests
  virtual task body();
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server rs = uvm_report_server::get_server();
    if (rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL) == 0)
      `uvm_info("TEST", $sformatf("*** TEST PASSED *** (%s)", get_type_name()), UVM_NONE)
    else
      `uvm_info("TEST", $sformatf("*** TEST FAILED *** (%s): %0d errors", get_type_name(),
                rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL)), UVM_NONE)
  endfunction

endclass : j3_base_test
