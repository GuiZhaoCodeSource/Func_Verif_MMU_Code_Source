/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrwrites_bus_monitor.sv
* DEVICE:    MMU_PROC_SFRWRITES VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRWRITES_BUS_MONITOR_SV
`define MMU_PROC_SFRWRITES_BUS_MONITOR_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_sfrwrites_bus_monitor
//
//------------------------------------------------------------------------------

class mmu_proc_sfrwrites_bus_monitor extends uvm_monitor;

   typedef mmu_proc_sfrwrites_bus_monitor mmu_proc_sfrwrites_bus_monitor_t;
   typedef mmu_proc_sfrwrites_transfer mmu_proc_sfrwrites_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_sfrwrites_if mmu_proc_sfrwrites_mi;

    string v_name;
    mmu_proc_sfrwrites_transfer_t mmu_proc_sfrwrites_queue[$];
    event new_trans_detected;
    event pending_trans_is_empty;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_sfrwrites_bus_monitor_t)
        `uvm_field_string(v_name, UVM_ALL_ON)
    `uvm_component_utils_end

    // Analysis ports for the item_collected and state notifier.
    uvm_analysis_port #(mmu_proc_sfrwrites_transfer_t) item_collected_port;

    // The following property holds the transaction information currently
    // being captured (by the collect_address_phase and data_phase methods).
    protected mmu_proc_sfrwrites_transfer_t pending_trans[$];

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_sfrwrites_if mmu_proc_sfrwrites_mi);
        this.mmu_proc_sfrwrites_mi = mmu_proc_sfrwrites_mi;
    endfunction

    // run phase
    task run_phase(uvm_phase phase);
        // Implement monitoring and log tasks
        integer fileID;
        mmu_proc_sfrwrites_transfer_t cur_trans;
        
        if ((fileID = $fopen($psprintf("mmu_proc_sfrwrites_%s.log",v_name), "w")) == 0) begin
            $display($psprintf("Error opening 'mmu_proc_sfrwrites_%s.log' file", v_name));
        end
    @(negedge mmu_proc_sfrwrites_mi.reset)
      forever begin
          @(negedge mmu_proc_sfrwrites_mi.clock)

          if (mmu_proc_sfrwrites_queue.size == 1) begin
             
              $fdisplay(fileID, $psprintf("[%0d]: %0d: Code of write '%0d',Write register '%0d',Value to be written  'h%X'", $time, mmu_proc_sfrwrites_queue[0].req_time, mmu_proc_sfrwrites_queue[0].cmd, mmu_proc_sfrwrites_queue[0].cpu_wr_reg_idx_i, mmu_proc_sfrwrites_queue[0].cpu_wr_reg_val_i));
              mmu_proc_sfrwrites_queue = {};
          end
          if (mmu_proc_sfrwrites_mi.cpu_wr_reg_en_i_m == 1) begin
              cur_trans = new;
              cur_trans.req_time = $time;          
              cur_trans.cpu_wr_reg_idx_i = mmu_proc_sfrwrites_mi.cpu_wr_reg_idx_i_m;
              cur_trans.cpu_wr_reg_val_i = mmu_proc_sfrwrites_mi.cpu_wr_reg_val_i_m;
              cur_trans.cmd = mmu_proc_sfrwrites_mi.cpu_wr_reg_cmd_i_m;
              mmu_proc_sfrwrites_queue = {mmu_proc_sfrwrites_queue, cur_trans};
         
          end
      end
        
    endtask : run_phase


endclass : mmu_proc_sfrwrites_bus_monitor

`endif
