/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_tlbmaintenance_slave_sequencer.sv
* DEVICE:    MMU_PROC_TLBMAINTENANCE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_TLBMAINTENANCE_SLAVE_SEQUENCER_SV
`define MMU_PROC_TLBMAINTENANCE_SLAVE_SEQUENCER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_tlbmaintenance_slave_sequencer
//
//------------------------------------------------------------------------------

class mmu_proc_tlbmaintenance_slave_sequencer extends uvm_sequencer #(mmu_proc_tlbmaintenance_transfer);

    typedef mmu_proc_tlbmaintenance_slave_sequencer mmu_proc_tlbmaintenance_slave_sequencer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_si;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils(mmu_proc_tlbmaintenance_slave_sequencer_t)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_si);
        this.mmu_proc_tlbmaintenance_si = mmu_proc_tlbmaintenance_si;
    endfunction : assign_vi

endclass : mmu_proc_tlbmaintenance_slave_sequencer

`endif
