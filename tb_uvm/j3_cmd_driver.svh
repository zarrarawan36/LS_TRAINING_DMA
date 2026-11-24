// -----------------------------------------------------------------------------
// j3_cmd_driver : drives the DUT inputs of the 'cmd' group
//
// Spec   : SPEC-00 command channel handshake, SPEC-06 (MRD-CMD-*)
// -----------------------------------------------------------------------------
class j3_cmd_driver extends uvm_driver #(j3_cmd_item);

  `uvm_component_utils(j3_cmd_driver)

  virtual sgdma_cmd_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sgdma_cmd_if)::get(this, "", "cmd_vif", vif) || vif == null)
      `uvm_fatal("J3_CMD_DRV", "cmd_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    j3_cmd_item req;

    // Idle outputs
    vif.cb_drv.valid <= 1'b0;
    vif.cb_drv.cmd.addr      <= '0;
    vif.cb_drv.cmd.len_bytes <= '0;
    vif.cb_drv.cmd.inc_addr  <= 1'b0;
    vif.cb_drv.cmd.gen_sop   <= 1'b0;
    vif.cb_drv.cmd.gen_eop   <= 1'b0;
    vif.cb_drv.cmd.desc_id   <= '0;

    @(posedge vif.rst_n);
    @(vif.cb_drv);

    forever begin
      seq_item_port.get_next_item(req);

      // Drive command and assert valid; hold stable until accepted.
      vif.cb_drv.cmd.addr      <= req.addr;
      vif.cb_drv.cmd.len_bytes <= req.len_bytes;
      vif.cb_drv.cmd.inc_addr  <= req.inc_addr;
      vif.cb_drv.cmd.gen_sop   <= req.gen_sop;
      vif.cb_drv.cmd.gen_eop   <= req.gen_eop;
      vif.cb_drv.cmd.desc_id   <= req.desc_id;
      vif.cb_drv.valid         <= 1'b1;

      do @(vif.cb_drv); while (vif.cb_drv.ready !== 1'b1);

      vif.cb_drv.valid <= 1'b0;
      seq_item_port.item_done();
    end
  endtask

endclass : j3_cmd_driver
