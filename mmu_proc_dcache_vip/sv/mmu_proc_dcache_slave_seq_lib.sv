/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_dcache_slave_seq_lib.sv
* DEVICE:    MMU_PROC_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_DCACHE_SLAVE_SEQ_LIB_SV
`define MMU_PROC_DCACHE_SLAVE_SEQ_LIB_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_dcache_slave_seq_example
//
//------------------------------------------------------------------------------

class mmu_proc_dcache_slave_seq_example extends uvm_sequence #(mmu_proc_dcache_transfer);

    typedef mmu_proc_dcache_slave_sequencer mmu_proc_dcache_slave_sequencer_t;
    typedef mmu_proc_dcache_transfer mmu_proc_dcache_transfer_t;

    `uvm_object_param_utils(mmu_proc_dcache_slave_seq_example)

    // new - constructor
    function new(string name="mmu_proc_dcache_slave_seq_example");
        super.new(name);
    endfunction : new

    mmu_proc_dcache_transfer_t util_transfer;

     virtual task body();
        `uvm_do_with(req, {} );
    endtask : body

endclass : mmu_proc_dcache_slave_seq_example

`endif
