// -----------------------------------------------------------------------------
// j3_sts_driver : drives the DUT inputs of the 'sts' group (TB drives sts_ready)
//
// Spec   : SPEC-00 status channel handshake, SPEC-06 (MRD-STS-*)
// -----------------------------------------------------------------------------
class j3_sts_driver extends uvm_driver #(j3_sts_item);

  `uvm_component_utils(j3_sts_driver)

  virtual sgdma_sts_if vif;

  // Default ready behavior: 1 => always ready.
  bit always_ready = 1'b1;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sgdma_sts_if)::get(this, "", "sts_vif", vif) || vif == null)
      `uvm_fatal("J3_STS_DRV", "sts_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    // Idle: not ready
    vif.cb_drv.ready <= 1'b0;

    @(posedge vif.rst_n);
    forever begin
      @(vif.cb_drv);
      if (always_ready)
        vif.cb_drv.ready <= 1'b1;
      else
        vif.cb_drv.ready <= 1'b0;
    end
  endtask

endclass : j3_sts_driver
