// -----------------------------------------------------------------------------
// j3_dout_driver : drives the DUT inputs of the 'dout' group (TB drives dout_ready)
//
// Spec   : SPEC-00 data-beat channel handshake, SPEC-06 (MRD-DATA-*)
// Sequence-driven: consumes j3_dout_item control items (item.ready) when
// provided; otherwise falls back to always_ready each cycle.
// -----------------------------------------------------------------------------
class j3_dout_driver extends uvm_driver #(j3_dout_item);

  `uvm_component_utils(j3_dout_driver)

  virtual sgdma_data_if vif;

  // Default ready behavior when no sequence item is available.
  bit always_ready = 1'b1;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sgdma_data_if)::get(this, "", "dout_vif", vif) || vif == null)
      `uvm_fatal("J3_DOUT_DRV", "dout_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    j3_dout_item req;
    bit last_ready;
    bit ready_drv;

    vif.cb_drv.ready <= 1'b0;
    last_ready = 1'b0;
    `uvm_info("J3_DOUT_DRV", $sformatf("Waiting for reset release, rst_n=%0b", vif.rst_n), UVM_LOW)
    @(posedge vif.rst_n);

    forever begin
      @(vif.cb_drv);
      if (vif.rst_n !== 1'b1) begin
        vif.cb_drv.ready <= 1'b0;
        last_ready = 1'b0;
        continue;
      end

      ready_drv = always_ready;
      seq_item_port.try_next_item(req);
      if (req != null) begin
        ready_drv = req.ready;
        seq_item_port.item_done();
      end
      vif.cb_drv.ready <= ready_drv;

      if (ready_drv !== last_ready) begin
        `uvm_info("J3_DOUT_DRV", $sformatf("dout_ready drive=%0b sampled valid=%0b ready=%0b",
                                           ready_drv, vif.cb_drv.valid, vif.cb_drv.ready), UVM_LOW)
      end
      last_ready = ready_drv;
    end
  endtask

endclass : j3_dout_driver
