// -----------------------------------------------------------------------------
// tb_top_common.svh : lines shared by every tb_top (included inside the module)
//
//   - imports your test package when the Makefile passes TEST_PKG=<name>
//     (adds +define+USER_TEST_PKG=<name>)
//   - global watchdog: +TB_TIMEOUT_NS=<n> (default 2_000_000 ns = 2 ms)
//   - waveform dump : make WAVES=1  (adds +define+DUMP_VCD, writes waves.vcd)
// -----------------------------------------------------------------------------
`ifdef USER_TEST_PKG
  import `USER_TEST_PKG::*;
`endif

  initial begin : watchdog
    longint unsigned timeout_ns;
    if (!$value$plusargs("TB_TIMEOUT_NS=%d", timeout_ns)) timeout_ns = 64'd2_000_000;
    #(timeout_ns * 1ns);
    `uvm_fatal("TB_TOP", $sformatf("global watchdog expired after %0d ns (+TB_TIMEOUT_NS)", timeout_ns))
  end

`ifdef DUMP_VCD
  initial begin : dump
    $dumpfile("waves.vcd");
    $dumpvars(0, tb_top);
  end
`endif
