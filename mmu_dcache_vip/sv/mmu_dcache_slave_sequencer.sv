/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_slave_sequencer.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_SLAVE_SEQUENCER_SV
`define MMU_DCACHE_SLAVE_SEQUENCER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_dcache_slave_sequencer
//
//------------------------------------------------------------------------------

class mmu_dcache_slave_sequencer extends uvm_sequencer #(mmu_dcache_transfer);

    typedef mmu_dcache_slave_sequencer mmu_dcache_slave_sequencer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_dcache_if mmu_dcache_si;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils(mmu_dcache_slave_sequencer_t)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_dcache_if mmu_dcache_si);
        this.mmu_dcache_si = mmu_dcache_si;
    endfunction : assign_vi

endclass : mmu_dcache_slave_sequencer

`endif
