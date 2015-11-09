/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_slave_sequencer.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_SLAVE_SEQUENCER_SV
`define MMUCFG_SLAVE_SEQUENCER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_slave_sequencer
//
//------------------------------------------------------------------------------

class mmucfg_slave_sequencer extends uvm_sequencer #(mmucfg_transfer);

    typedef mmucfg_slave_sequencer mmucfg_slave_sequencer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmucfg_if mmucfg_si;

    // Provide implementations of virtual methods such as get_type_name and create
    //`uvm_sequencer_utils(mmucfg_slave_sequencer_t)
    `uvm_component_utils(mmucfg_slave_sequencer_t)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        //`uvm_update_sequence_lib_and_item(mmucfg_transfer_t)
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmucfg_if mmucfg_si);
        this.mmucfg_si = mmucfg_si;
    endfunction : assign_vi

endclass : mmucfg_slave_sequencer

`endif
