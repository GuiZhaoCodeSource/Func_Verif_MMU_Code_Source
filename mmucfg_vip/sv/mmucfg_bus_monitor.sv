/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_bus_monitor.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_BUS_MONITOR_SV
`define MMUCFG_BUS_MONITOR_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_bus_monitor
//
//------------------------------------------------------------------------------

class mmucfg_bus_monitor extends uvm_monitor;

   typedef mmucfg_bus_monitor mmucfg_bus_monitor_t;
   typedef mmucfg_transfer mmucfg_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmucfg_if mmucfg_mi;

    string v_name;
    mmucfg_transfer_t mmucfg_queue[$];
    event new_trans_detected;
    event pending_trans_is_empty;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmucfg_bus_monitor_t)
        `uvm_field_string(v_name, UVM_ALL_ON)
    `uvm_component_utils_end

    // Analysis ports for the item_collected and state notifier.
    uvm_analysis_port #(mmucfg_transfer_t) item_collected_port;

    // The following property holds the transaction information currently
    // being captured (by the collect_address_phase and data_phase methods).
    protected mmucfg_transfer_t pending_trans[$];

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmucfg_if mmucfg_mi);
        this.mmucfg_mi = mmucfg_mi;
    endfunction

    // run phase
    task run_phase(uvm_phase phase);
        // Implement monitoring and log tasks
      integer fileID;
      mmucfg_transfer_t cur_trans;


        if ((fileID = $fopen($psprintf("mmu_configure_%s.log",v_name), "w")) == 0) begin
            $display($psprintf("Error opening 'mmu_configure_%s.log' file", v_name));
        end
        
        @(negedge mmucfg_mi.reset)
          forever begin
              @(posedge mmucfg_mi.clock)

                if (mmucfg_queue.size == 1) begin
             
                    $fdisplay(fileID, $psprintf("[%0d]: %0d: Debug mode '%0d',Privileged mode '%0d',32b/64b mode 'h%X', One-hot encoding of the smem size '%0d'", $time,mmucfg_queue[0].req_time, mmucfg_queue[0].proc_in_debug, mmucfg_queue[0].priviledge_mode, mmucfg_queue[0].k1_64b_mode, mmucfg_queue[0].smem_ext_cfg));
              mmucfg_queue = {};
                end
          
              if (mmucfg_mi.mmu_enable_m == 1) begin
                  cur_trans = new;
                  cur_trans.req_time = $time;          
                  cur_trans.proc_in_debug = mmucfg_mi.processor_in_debug_m;
                  cur_trans.priviledge_mode = mmucfg_mi.priviledge_mode_m;
                  cur_trans.k1_64b_mode= mmucfg_mi.k1_64_mode_m;
                  cur_trans.smem_ext_cfg= mmucfg_mi.smem_ext_cfg_m;
                  mmucfg_queue = {mmucfg_queue, cur_trans};
   

                  end
              end
   
    endtask : run_phase


endclass : mmucfg_bus_monitor

`endif
