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

endpackage : j3_test_pkg
