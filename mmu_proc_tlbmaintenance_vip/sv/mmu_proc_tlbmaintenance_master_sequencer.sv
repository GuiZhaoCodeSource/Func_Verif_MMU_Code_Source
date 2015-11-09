/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_tlbmaintenance_master_sequencer.sv
* DEVICE:    MMU_PROC_TLBMAINTENANCE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_TLBMAINTENANCE_MASTER_SEQUENCER_SV
`define MMU_PROC_TLBMAINTENANCE_MASTER_SEQUENCER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_tlbmaintenance_master_sequencer
//
//------------------------------------------------------------------------------

class mmu_proc_tlbmaintenance_master_sequencer extends uvm_sequencer #(mmu_proc_tlbmaintenance_transfer);

    typedef mmu_proc_tlbmaintenance_master_sequencer mmu_proc_tlbmaintenance_master_sequencer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_mi;

    // Provide implementations of virtual methods such as get_type_name and create
    //`uvm_sequencer_utils(mmu_proc_tlbmaintenance_master_sequencer_t)
    `uvm_component_utils(mmu_proc_tlbmaintenance_master_sequencer_t)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        //`uvm_update_sequence_lib_and_item(mmu_proc_tlbmaintenance_transfer_t)
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_mi);
        this.mmu_proc_tlbmaintenance_mi = mmu_proc_tlbmaintenance_mi;
    endfunction : assign_vi

endclass : mmu_proc_tlbmaintenance_master_sequencer

`endif
