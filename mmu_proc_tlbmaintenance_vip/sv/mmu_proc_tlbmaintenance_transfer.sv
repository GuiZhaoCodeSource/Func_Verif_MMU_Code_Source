/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_tlbmaintenance_transfer.sv
* DEVICE:    MMU_PROC_TLBMAINTENANCE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_TLBMAINTENANCE_TRANSFER_SV
`define MMU_PROC_TLBMAINTENANCE_TRANSFER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_tlbmaintenance_transfer
//
//------------------------------------------------------------------------------
typedef enum byte {TLBREAD=1,TLBWRITE=2,TLBPROBE=3,TLBINDEXL=4,TLBINDEXJ=5,TLBINVALD=6,TLBINVALI=7} tlb_maintenance_cmd_t;

class mmu_proc_tlbmaintenance_transfer extends uvm_sequence_item;

    typedef mmu_proc_tlbmaintenance_transfer mmu_proc_tlbmaintenance_transfer_t;
    protected virtual mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_mi;
    string v_name;
    rand int unsigned req_lat;
    rand int unsigned cancel_lat;
    
    // Add items of the transfer 
    rand tlb_maintenance_cmd_t cmd;
    rand cancel_mode_t cancel_mode;
    rand logic    f_stall_mmu_o;
    rand logic    rr_stall_mmu_o;
    rand logic    mmc_e;
    rand logic    mmc_idx;
     
    `uvm_object_utils_begin(mmu_proc_tlbmaintenance_transfer_t)
        `uvm_field_enum(tlb_maintenance_cmd_t,cmd, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_enum(cancel_mode_t,cancel_mode, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int( req_lat, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int( f_stall_mmu_o, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int( rr_stall_mmu_o, UVM_ALL_ON|UVM_NOPACK)     
        `uvm_field_int( cancel_lat, UVM_ALL_ON|UVM_NOPACK)  
        `uvm_field_int( mmc_e, UVM_ALL_ON|UVM_NOPACK)  
        `uvm_field_int( mmc_idx, UVM_ALL_ON|UVM_NOPACK)  
    `uvm_object_utils_end
    function new(string name = "mmu_proc_tlbmaintenance_transfer_inst");
        super.new(name);
    endfunction : new
   

    
endclass : mmu_proc_tlbmaintenance_transfer

`endif
