/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_master_driver.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_MASTER_DRIVER_SV
`define MMUCFG_MASTER_DRIVER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_master_driver
//
//------------------------------------------------------------------------------

class mmucfg_master_driver extends uvm_driver #(mmucfg_transfer);

   typedef mmucfg_master_driver mmucfg_master_driver_t;
   typedef mmucfg_transfer mmucfg_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmucfg_if mmucfg_mi;

    string v_name;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmucfg_master_driver_t)
        `uvm_field_string(v_name,  UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmucfg_if mmucfg_mi);
        this.mmucfg_mi = mmucfg_mi;
    endfunction : assign_vi

    // run phase
    virtual task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $psprintf("Staring driver run"), UVM_LOW)
        fork
            reset_signals();
            get_and_drive();
        join
    endtask : run_phase

    // reset_signals
    virtual protected task reset_signals();
        `uvm_info(get_type_name(), $psprintf("Reseting signals"), UVM_LOW)
        mmucfg_mi.mmu_enable_m <= 0;
        mmucfg_mi.processor_in_debug_m <= 0;
        mmucfg_mi.priviledge_mode_m <= 0;
        mmucfg_mi.k1_64_mode_m <= 0;
        mmucfg_mi.smem_ext_cfg_m <= 0;

       
    endtask : reset_signals

    // get_and_drive
    virtual protected task get_and_drive();
        `uvm_info(get_type_name(), $psprintf("get_and_drive"), UVM_LOW)
        @(negedge mmucfg_mi.reset);
        forever begin
          seq_item_port.get_next_item(req);
          if (req.v_name == v_name) begin
              $cast(rsp, req.clone());
              rsp.set_id_info(req);
              drive_transfer(rsp);
          end
          seq_item_port.item_done(rsp);
        end
    endtask : get_and_drive

    virtual protected task drive_transfer (mmucfg_transfer_t trans);
      // Wait latency before request
      mmucfg_mi.mmu_enable_m <= trans.mmu_enable;
      mmucfg_mi.processor_in_debug_m <= trans.proc_in_debug;
      mmucfg_mi.priviledge_mode_m <= trans.priviledge_mode;
      mmucfg_mi.k1_64_mode_m <= trans.k1_64b_mode;
      mmucfg_mi.smem_ext_cfg_m <= trans.smem_ext_cfg;

      
    endtask : drive_transfer

endclass : mmucfg_master_driver

`endif
