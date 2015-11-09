/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrwrites_master_driver.sv
* DEVICE:    MMU_PROC_SFRWRITES VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRWRITES_MASTER_DRIVER_SV
`define MMU_PROC_SFRWRITES_MASTER_DRIVER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_sfrwrites_master_driver
//
//------------------------------------------------------------------------------

class mmu_proc_sfrwrites_master_driver extends uvm_driver #(mmu_proc_sfrwrites_transfer);

   typedef mmu_proc_sfrwrites_master_driver mmu_proc_sfrwrites_master_driver_t;
   typedef mmu_proc_sfrwrites_transfer mmu_proc_sfrwrites_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_sfrwrites_if mmu_proc_sfrwrites_mi;

    string v_name;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_sfrwrites_master_driver_t)
        `uvm_field_string(v_name,  UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_sfrwrites_if mmu_proc_sfrwrites_mi);
        this.mmu_proc_sfrwrites_mi = mmu_proc_sfrwrites_mi;
    endfunction : assign_vi

    // run phase
    virtual task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $psprintf("Starting driver run"), UVM_LOW)
        fork
            reset_signals();
            get_and_drive();
        join
    endtask : run_phase

    // reset_signals
    virtual protected task reset_signals();
        `uvm_info(get_type_name(), $psprintf("Reseting signals"), UVM_LOW)
    
       mmu_proc_sfrwrites_mi.cpu_wr_reg_en_i_m = 0;
       mmu_proc_sfrwrites_mi.cpu_wr_reg_cmd_i_m <= RES;
       mmu_proc_sfrwrites_mi.cpu_wr_reg_idx_i_m <= $urandom_range('hFF,0);
       mmu_proc_sfrwrites_mi.cpu_wr_reg_val_i_m <= $urandom_range('hFFFF_FFFF,0);
       
    endtask : reset_signals

    // get_and_drive
    virtual protected task get_and_drive();
        `uvm_info(get_type_name(), $psprintf("get_and_drive"), UVM_LOW)
        @(negedge mmu_proc_sfrwrites_mi.reset);
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

    virtual protected task drive_transfer (mmu_proc_sfrwrites_transfer_t trans);
      `uvm_info(get_type_name(), $psprintf("Driver starting in %0d cycles", trans.req_lat), UVM_LOW)
      // Wait latency before request
      repeat(trans.req_lat) @(posedge mmu_proc_sfrwrites_mi.clock );
      // Drive the request 
      mmu_proc_sfrwrites_mi.cpu_wr_reg_cmd_i_m <=trans.cmd;
      mmu_proc_sfrwrites_mi.cpu_wr_reg_en_i_m <=1;
      mmu_proc_sfrwrites_mi.cpu_wr_reg_idx_i_m <= trans.cpu_wr_reg_idx_i;
      mmu_proc_sfrwrites_mi.cpu_wr_reg_val_i_m <= trans.cpu_wr_reg_val_i;
      // Wait one cycle
      @(posedge mmu_proc_sfrwrites_mi.clock );
      // Reset signals
       reset_signals();
       
    endtask : drive_transfer

endclass : mmu_proc_sfrwrites_master_driver

`endif
