// -----------------------------------------------------------------------------
// j3_cmd_monitor : observes the 'cmd' group
//
// Spec   : SPEC-00 command channel handshake, SPEC-06 (MRD-CMD-*)
// -----------------------------------------------------------------------------
class j3_cmd_monitor extends uvm_monitor;

  `uvm_component_utils(j3_cmd_monitor)

  uvm_analysis_port #(j3_cmd_item) ap;
  virtual j3_cmd_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual j3_cmd_if)::get(this, "", "cmd_vif", vif) || vif == null)
      `uvm_fatal("J3_CMD_MON", "cmd_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    j3_cmd_item tr;
    forever begin
      @(vif.cb_mon);
      if (vif.rst_n !== 1'b1) continue;
      if (vif.cb_mon.valid === 1'b1 && vif.cb_mon.ready === 1'b1) begin
        tr = j3_cmd_item::type_id::create("cmd_tr", this);
        tr.addr      = vif.cb_mon.cmd.addr;
        tr.len_bytes = vif.cb_mon.cmd.len_bytes;
        tr.inc_addr  = vif.cb_mon.cmd.inc_addr;
        tr.gen_sop   = vif.cb_mon.cmd.gen_sop;
        tr.gen_eop   = vif.cb_mon.cmd.gen_eop;
        tr.desc_id   = vif.cb_mon.cmd.desc_id;
        ap.write(tr);
      end
    end
  endtask

endclass : j3_cmd_monitor
