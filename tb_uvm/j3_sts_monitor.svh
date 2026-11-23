// -----------------------------------------------------------------------------
// j3_sts_monitor : observes the 'sts' group
//
// Spec   : SPEC-00 status channel handshake, SPEC-06 (MRD-STS-*)
// -----------------------------------------------------------------------------
class j3_sts_monitor extends uvm_monitor;

  `uvm_component_utils(j3_sts_monitor)

  uvm_analysis_port #(j3_sts_item) ap;
  virtual sgdma_sts_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sgdma_sts_if)::get(this, "", "sts_vif", vif) || vif == null)
      `uvm_fatal("J3_STS_MON", "sts_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    j3_sts_item tr;
    forever begin
      @(vif.cb_mon);
      if (vif.rst_n !== 1'b1) continue;
      if (vif.cb_mon.valid === 1'b1 && vif.cb_mon.ready === 1'b1) begin
        tr = j3_sts_item::type_id::create("sts_tr", this);
        tr.set_from_sts(vif.cb_mon.sts);
        ap.write(tr);
      end
    end
  endtask

endclass : j3_sts_monitor
