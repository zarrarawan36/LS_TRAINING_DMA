`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// j3_test_pkg : all your tests. tb_top imports this package (Makefile
//               TEST_PKG=j3_test_pkg) so +UVM_TESTNAME can find every test.
//               Add one `include per new test file.
// -----------------------------------------------------------------------------
package j3_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sgdma_pkg::*;
  import axi4_agent_pkg::*;
  import j3_env_pkg::*;

  `include "j3_base_test.svh"
  `include "j3_first_test.svh"
  `include "j3_illegal_cmd_test.svh"
  `include "j3_rand_test.svh"
  `include "j3_burstsplit_test.svh"
  `include "j3_fixed_addr_test.svh"
  `include "j3_error_resp_test.svh"
  `include "j3_dout_backpressure_test.svh"
  `include "j3_sts_backpressure_test.svh"
  `include "j3_mem_stall_test.svh"
  `include "j3_rand_stress_test.svh"
  `include "j3_reset_test.svh"
  `include "j3_keep_last_test.svh"
  `include "j3_back2back_test.svh"
  `include "j3_maxlen_test.svh"
  `include "j3_cmd_fields_test.svh"

endpackage : j3_test_pkg
