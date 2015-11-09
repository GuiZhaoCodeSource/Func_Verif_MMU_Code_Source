/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrreads_transfer.sv
* DEVICE:    MMU_PROC_SFRREADS VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRREADS_TRANSFER_SV
`define MMU_PROC_SFRREADS_TRANSFER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_sfrreads_transfer
//
//------------------------------------------------------------------------------

class mmu_proc_sfrreads_transfer extends uvm_sequence_item;

    typedef mmu_proc_sfrreads_transfer mmu_proc_sfrreads_transfer_t;

    string v_name;
    // For monitoring
    longint  req_time;

    // Add items of the transfer
    rand int unsigned req_lat;
    rand logic [7:0]  f_sfr_read_idx_i;
    rand logic        rr_stall_i;
    rand logic [31:0] rr_results_o;

    `uvm_object_utils_begin(mmu_proc_sfrreads_transfer_t)
        `uvm_field_int(req_lat, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(f_sfr_read_idx_i, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(rr_stall_i, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(rr_results_o, UVM_ALL_ON|UVM_NOPACK)
    `uvm_object_utils_end
    
    function new(string name = "mmu_proc_sfrreads_transfer_inst");
        super.new(name);
    endfunction : new


endclass : mmu_proc_sfrreads_transfer

`endif
