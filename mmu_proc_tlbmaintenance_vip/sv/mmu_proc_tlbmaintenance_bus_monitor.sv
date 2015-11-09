/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_tlbmaintenance_bus_monitor.sv
* DEVICE:    MMU_PROC_TLBMAINTENANCE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_TLBMAINTENANCE_BUS_MONITOR_SV
`define MMU_PROC_TLBMAINTENANCE_BUS_MONITOR_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_tlbmaintenance_bus_monitor
//
//------------------------------------------------------------------------------

class mmu_proc_tlbmaintenance_bus_monitor extends uvm_monitor;

    typedef mmu_proc_tlbmaintenance_bus_monitor mmu_proc_tlbmaintenance_bus_monitor_t;
    typedef mmu_proc_tlbmaintenance_transfer mmu_proc_tlbmaintenance_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_mi;

    string v_name;
    mmu_proc_tlbmaintenance_transfer_t mmu_proc_tlbmaintenance_last_trans;
    event new_trans_detected;
    event pending_trans_is_empty;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_tlbmaintenance_bus_monitor_t)
        `uvm_field_string(v_name, UVM_ALL_ON)
    `uvm_component_utils_end

    // Analysis ports for the item_collected and state notifier.
    uvm_analysis_port #(mmu_proc_tlbmaintenance_transfer_t) item_collected_port;

    // The following property holds the transaction information currently
    // being captured (by the collect_address_phase and data_phase methods).
    protected mmu_proc_tlbmaintenance_transfer_t pending_trans[$];

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_mi);
        this.mmu_proc_tlbmaintenance_mi = mmu_proc_tlbmaintenance_mi;
    endfunction

    // run phase
    task run_phase(uvm_phase phase);
        // Implement monitoring and log tasks
    endtask : run_phase


endclass : mmu_proc_tlbmaintenance_bus_monitor

`endif
