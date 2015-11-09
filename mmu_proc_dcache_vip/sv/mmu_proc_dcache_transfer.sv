/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_dcache_transfer.sv
* DEVICE:    MMU_PROC_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_DCACHE_TRANSFER_SV
`define MMU_PROC_DCACHE_TRANSFER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_dcache_transfer
//
//------------------------------------------------------------------------------

class mmu_proc_dcache_transfer extends uvm_sequence_item;

    typedef mmu_proc_dcache_transfer mmu_proc_dcache_transfer_t;

    string v_name;
    //For monitor
    longint  req_time;
    rand logic   e1_glob_acc_i;  
    rand logic   e2_non_trapping_id_cancel_o;
    rand logic   e2_trap_nomapping_o ;   
    rand logic   e2_trap_protection_o;
    rand logic   e2_trap_writetoclean_o ;
    rand logic   e2_trap_atomictoclean_o;
    rand logic   e2_trap_dmisalign_o;
    rand logic   e2_trap_dsyserror_o; 
    
    // Add items of the transfer
    rand int  unsigned req_lat;
    rand logic  [40:0] e1_dcache_virt_addr_i;
    rand e1_dcache_opc_t e1_dcache_opc;
    rand logic  [3:0]  e1_dcache_size_i;
    rand logic         e1_non_trapping_i;

   


    
   

    `uvm_object_utils_begin(mmu_proc_dcache_transfer_t)
    
        `uvm_field_int(req_lat, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e1_dcache_virt_addr_i, UVM_ALL_ON|UVM_NOPACK)       
        `uvm_field_int(e1_dcache_size_i, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e1_non_trapping_i, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_enum(e1_dcache_opc_t,e1_dcache_opc, UVM_ALL_ON|UVM_NOPACK)
       
    `uvm_object_utils_end
    function new(string name = "mmu_proc_dcache_transfer_inst");
        super.new(name);
    endfunction : new

endclass : mmu_proc_dcache_transfer

`endif
