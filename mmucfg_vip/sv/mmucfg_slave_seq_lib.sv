/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_slave_seq_lib.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_SLAVE_SEQ_LIB_SV
`define MMUCFG_SLAVE_SEQ_LIB_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_slave_seq_example
//
//------------------------------------------------------------------------------

class mmucfg_slave_seq_example extends uvm_sequence #(mmucfg_transfer);

   typedef mmucfg_slave_sequencer mmucfg_slave_sequencer_t;
   typedef mmucfg_transfer mmucfg_transfer_t;

    `uvm_object_param_utils(mmucfg_slave_seq_example)

    // new - constructor
    function new(string name="mmucfg_slave_seq_example");
        super.new(name);
    endfunction : new

    mmucfg_transfer_t util_transfer;

     virtual task body();
        `uvm_do_with(req, {} );
    endtask : body

endclass : mmucfg_slave_seq_example

`endif
