// -----------------------------------------------------------------------------
// smoke_report.svh : report_phase shared by the harness smoke tests
// (included inside a uvm_test class)
// -----------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
      uvm_report_server rs = uvm_report_server::get_server();
      if (rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL) == 0)
        `uvm_info("SMOKE", "*** HARNESS SMOKE TEST PASSED ***", UVM_NONE)
      else
        `uvm_info("SMOKE", "*** HARNESS SMOKE TEST FAILED ***", UVM_NONE)
    endfunction
