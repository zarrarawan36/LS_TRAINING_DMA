// -----------------------------------------------------------------------------
// my_tb.f : YOUR files, compiled after rtl.f and dv_lib.f, before harness.f
// Paths are relative to sim/. Order matters:
//   1. your interfaces (they are used by your packages and by tb_top)
//   2. your env package, then your test package
// -----------------------------------------------------------------------------
// TODO: add your interface files here, for example
//   ../tb_uvm/my_cmd_if.sv      (command)
//   ../tb_uvm/my_dout_if.sv      (dout data beats (the DUT SENDS beats, you drive ready))
//   ../tb_uvm/my_sts_if.sv      (status)

+incdir+../tb_uvm
+incdir+../tests
../tb_uvm/j3_env_pkg.sv
../tests/j3_test_pkg.sv
