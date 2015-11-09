/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_slave_seq_lib.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_SLAVE_SEQ_LIB_SV
`define MMU_DCACHE_SLAVE_SEQ_LIB_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_dcache_slave_seq_example
//
//------------------------------------------------------------------------------

class mmu_dcache_slave_seq_default extends uvm_sequence #(mmu_dcache_transfer);

    typedef mmu_dcache_slave_sequencer mmu_dcache_slave_sequencer_t;
    typedef mmu_dcache_transfer mmu_dcache_transfer_t;

    `uvm_object_param_utils(mmu_dcache_slave_seq_default)

    // new - constructor
    function new(string name="mmu_dcache_slave_seq_example");
        super.new(name);
    endfunction : new

    mmu_dcache_transfer_t util_transfer;

     virtual task body();
        forever begin
            `uvm_do_with(req, {} );
        end
    endtask : body

endclass : mmu_dcache_slave_seq_default

`endif
