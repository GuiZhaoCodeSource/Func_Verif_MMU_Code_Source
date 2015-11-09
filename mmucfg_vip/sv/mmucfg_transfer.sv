
/* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_transfer.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_TRANSFER_SV
`define MMUCFG_TRANSFER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_transfer
//
//------------------------------------------------------------------------------
  
class mmucfg_transfer extends uvm_sequence_item;

    typedef mmucfg_transfer mmucfg_transfer_t;

    string v_name;
    longint  req_time;

    // Add items of the transfer
    rand bit mmu_enable;
    rand int proc_in_debug;
    rand int priviledge_mode;
    rand int k1_64b_mode;
    rand logic[4:0] smem_ext_cfg;

   
    `uvm_object_utils_begin(mmucfg_transfer_t)
        `uvm_field_int(mmu_enable, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(proc_in_debug, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(priviledge_mode, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(k1_64b_mode, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(smem_ext_cfg, UVM_ALL_ON|UVM_NOPACK)
       
    `uvm_object_utils_end
   
    function new(string name = "mmucfg_transfer_inst");
        super.new(name);
    endfunction : new

endclass : mmucfg_transfer

`endif
