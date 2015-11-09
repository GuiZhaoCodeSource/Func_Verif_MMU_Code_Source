/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_master_sequencer.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_MASTER_SEQUENCER_SV
`define MMU_DCACHE_MASTER_SEQUENCER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_dcache_master_sequencer
//
//------------------------------------------------------------------------------

class mmu_dcache_master_sequencer extends uvm_sequencer #(mmu_dcache_transfer);

    typedef mmu_dcache_master_sequencer mmu_dcache_master_sequencer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_dcache_if mmu_dcache_mi;

    // Provide implementations of virtual methods such as get_type_name and create
    //`uvm_sequencer_utils(mmu_dcache_master_sequencer_t)
    `uvm_component_utils(mmu_dcache_master_sequencer_t)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        //`uvm_update_sequence_lib_and_item(mmu_dcache_transfer_t)
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_dcache_if mmu_dcache_mi);
        this.mmu_dcache_mi = mmu_dcache_mi;
    endfunction : assign_vi

endclass : mmu_dcache_master_sequencer

`endif
