tests/  -  your tests
=====================================================================

  j3_test_pkg.sv     includes every test of this folder
  j3_base_test.svh   builds the env, every other test extends it
  j3_first_test.svh  example of a small directed test

New test: one .svh file per test, `include it in j3_test_pkg.sv and add
a line "<test name> <seed>" to ../sim/regress.list.

  cd ../sim
  make run TEST=<test> SEED=<n>        one test
  make regress                         every line of regress.list

A run passes when it has no UVM_ERROR and no UVM_FATAL. Logs are in
sim/logs/<test>_<seed>.log; re-run with the same SEED to reproduce a failure.
