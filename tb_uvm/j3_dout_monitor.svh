// -----------------------------------------------------------------------------
// j3_dout_monitor : observes the 'dout' group
//
// Spec   : SPEC-00 data-beat channel handshake, SPEC-06 (MRD-DATA-*)
// -----------------------------------------------------------------------------
class j3_dout_monitor extends uvm_monitor;

  `uvm_component_utils(j3_dout_monitor)

  uvm_analysis_port #(j3_dout_item) ap;
  virtual j3_data_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual j3_data_if)::get(this, "", "dout_vif", vif) || vif == null)
      `uvm_fatal("J3_DOUT_MON", "dout_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    j3_dout_item tr;
    forever begin
      @(vif.cb_mon);
      if (vif.rst_n !== 1'b1) continue;
      if (vif.cb_mon.valid === 1'b1 && vif.cb_mon.ready === 1'b1) begin
        tr = j3_dout_item::type_id::create("dout_tr", this);
        tr.data = '0;
        tr.keep = '0;
        tr.data = vif.cb_mon.data;
        tr.keep = vif.cb_mon.keep;
        tr.last = vif.cb_mon.last;
        ap.write(tr);
      end
    end
  endtask

endclass : j3_dout_monitor
