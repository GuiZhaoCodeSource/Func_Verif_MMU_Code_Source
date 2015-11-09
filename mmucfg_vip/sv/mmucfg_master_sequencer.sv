/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_master_sequencer.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_MASTER_SEQUENCER_SV
`define MMUCFG_MASTER_SEQUENCER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_master_sequencer
//
//------------------------------------------------------------------------------

class mmucfg_master_sequencer extends uvm_sequencer #(mmucfg_transfer);

   typedef mmucfg_master_sequencer mmucfg_master_sequencer_t;
   typedef mmucfg_transfer mmucfg_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmucfg_if mmucfg_mi;

    // Provide implementations of virtual methods such as get_type_name and create
    //`uvm_sequencer_utils(mmucfg_master_sequencer_t)
    `uvm_component_utils(mmucfg_master_sequencer_t)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        //`uvm_update_sequence_lib_and_item(mmucfg_transfer_t)
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmucfg_if mmucfg_mi);
        this.mmucfg_mi = mmucfg_mi;
    endfunction : assign_vi

endclass : mmucfg_master_sequencer

`endif
