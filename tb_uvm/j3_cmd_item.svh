// -----------------------------------------------------------------------------
// j3_cmd_item : transaction for the 'cmd' port group (command channel)
//
// Spec   : SPEC-00 command channel, SPEC-06 (MRD-CMD-*, burst/data behavior)
// -----------------------------------------------------------------------------
// One transaction represents one command on the cmd interface
// (desc_id/gen_eop/gen_sop/inc_addr/len_bytes/addr), driven by the TB and
// sampled by the monitor on a valid && ready handshake.
// -----------------------------------------------------------------------------
class j3_cmd_item extends uvm_sequence_item;

  rand bit [31:0] addr;
  rand bit [15:0] len_bytes;
  rand bit        inc_addr;
  rand bit        gen_sop;
  rand bit        gen_eop;
  rand bit [7:0]  desc_id;

  `uvm_object_utils_begin(j3_cmd_item)
    `uvm_field_int(addr,      UVM_ALL_ON)
    `uvm_field_int(len_bytes, UVM_ALL_ON)
    `uvm_field_int(inc_addr,  UVM_ALL_ON)
    `uvm_field_int(gen_sop,   UVM_ALL_ON)
    `uvm_field_int(gen_eop,   UVM_ALL_ON)
    `uvm_field_int(desc_id,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "j3_cmd_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("cmd{desc_id=0x%0h addr=0x%08h len=%0d inc=%0b sop=%0b eop=%0b}",
                     desc_id, addr, len_bytes, inc_addr, gen_sop, gen_eop);
  endfunction

  // Populate fields from an sgdma_cmd_t struct.
  virtual function void set_from_cmd(input sgdma_cmd_t cmd);
    addr      = cmd.addr;
    len_bytes = cmd.len_bytes;
    inc_addr  = cmd.inc_addr;
    gen_sop   = cmd.gen_sop;
    gen_eop   = cmd.gen_eop;
    desc_id   = cmd.desc_id;
  endfunction

  // Convert fields to an sgdma_cmd_t struct.
  virtual function sgdma_cmd_t get_cmd();
    sgdma_cmd_t cmd;
    cmd.addr      = addr;
    cmd.len_bytes = len_bytes;
    cmd.inc_addr  = inc_addr;
    cmd.gen_sop   = gen_sop;
    cmd.gen_eop   = gen_eop;
    cmd.desc_id   = desc_id;
    return cmd;
  endfunction

endclass : j3_cmd_item