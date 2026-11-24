// -----------------------------------------------------------------------------
// my_tb.f : YOUR files, compiled after rtl.f and dv_lib.f, before harness.f
// Paths are relative to sim/. Order matters:
//   1. your interfaces (they are used by your packages and by tb_top)
//   2. your env package, then your test package
// -----------------------------------------------------------------------------
../tb_uvm/sgdma_cmd_if.sv
../tb_uvm/sgdma_data_if.sv
../tb_uvm/sgdma_sts_if.sv

+incdir+../tb_uvm
+incdir+../tests
../tb_uvm/j3_env_pkg.sv
../tests/j3_test_pkg.sv