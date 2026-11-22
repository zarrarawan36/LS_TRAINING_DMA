// -----------------------------------------------------------------------------
// smoke_mem_check.svh : backdoor sanity check used by the harness smoke tests
// (included inside a uvm_test class that has "virtual axi_mem_bd_if mem_vif")
// -----------------------------------------------------------------------------
    function void check_mem_backdoor();
      bit [31:0] rd;
      mem_vif.write_word(32'h0000_1000, 32'hA5A5_0001);
      rd = mem_vif.read_word(32'h0000_1000);
      if (rd !== 32'hA5A5_0001)
        `uvm_error("SMOKE", $sformatf("memory backdoor read 0x%08h, expected 0xA5A50001", rd))
      else
        `uvm_info("SMOKE", "memory backdoor write/read OK", UVM_LOW)
      if (mem_vif.read_byte(32'h0000_1003) !== 8'hA5)
        `uvm_error("SMOKE", "memory backdoor byte order is not little-endian")
      mem_vif.clear_all();
    endfunction
