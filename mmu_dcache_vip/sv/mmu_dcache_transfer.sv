/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_transfer.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_TRANSFER_SV
`define MMU_DCACHE_TRANSFER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_dcache_transfer
//
//------------------------------------------------------------------------------

class mmu_dcache_transfer extends uvm_sequence_item;

    typedef mmu_dcache_transfer mmu_dcache_transfer_t;

    string v_name;
    
    //For monitor
    longint            req_time;
    rand logic [21:12] e2_dcache_phys_addr_m;
    rand logic         e2_dcache_cluster_per_acc_m;
    rand logic         e2_dcache_policy_m;

    // Add items of the transfer
    rand int unsigned req_lat;
    rand int unsigned grant_lat;
    
    rand logic dcache_second_acc_d_i;
    
    rand logic dcache_e1_grant_i;
    rand logic dcache_e3_stall_i;

    rand logic [40:0] e1_dcache_virt_addr_m;
    rand logic [3:0]  e1_dcache_size_m;
    rand e1_dcache_opc_t   e1_dcache_opc_i;

    rand int unsigned e2_working_cycles;

   
    rand logic [1:0]   e2_trap_nomapping_o;       
    rand logic [1:0]   e2_trap_protection_o;       
    rand logic [1:0]   e2_trap_writetoclean_o;    
    rand logic [1:0]   e2_trap_atomictoclean_o;    
    rand logic         e2_trap_dmisalign_o;        
    rand logic [1:0]   e2_trap_dsyserror_o;

    // rand logic wen;
    // rand logic [(mmu_dcache_ADDR_WIDTH - 1):0] addr;

    `uvm_object_utils_begin(mmu_dcache_transfer_t)
        
        `uvm_field_int(grant_lat, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(req_lat, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(dcache_second_acc_d_i, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(dcache_e1_grant_i, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(dcache_e3_stall_i, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e1_dcache_virt_addr_m, UVM_ALL_ON|UVM_NOPACK) 
        `uvm_field_int(e1_dcache_size_m, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_enum(e1_dcache_opc_t,e1_dcache_opc_i, UVM_ALL_ON|UVM_NOPACK)
        
        `uvm_field_int(e2_dcache_phys_addr_m , UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e2_dcache_cluster_per_acc_m , UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e2_dcache_policy_m , UVM_ALL_ON|UVM_NOPACK)

        `uvm_field_int(e2_trap_nomapping_o, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e2_trap_protection_o, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e2_trap_writetoclean_o, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e2_trap_atomictoclean_o, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e2_trap_dmisalign_o, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(e2_trap_dsyserror_o, UVM_ALL_ON|UVM_NOPACK) 
    
        
    `uvm_object_utils_end
    function new(string name = "mmu_dcache_transfer_inst");
        super.new(name);
    endfunction : new

endclass : mmu_dcache_transfer

`endif
