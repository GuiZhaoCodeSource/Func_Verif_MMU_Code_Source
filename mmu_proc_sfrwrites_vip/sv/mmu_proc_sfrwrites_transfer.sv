/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrwrites_transfer.sv
* DEVICE:    MMU_PROC_SFRWRITES VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRWRITES_TRANSFER_SV
`define MMU_PROC_SFRWRITES_TRANSFER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_sfrwrites_transfer
//
//------------------------------------------------------------------------------

//typedef enum logic[1:0] {SET='b00,HFXB='b01,HFXT='b10,reserved='b11} cpu_wr_reg_cmd_t;

class mmu_proc_sfrwrites_transfer extends uvm_sequence_item;

   typedef mmu_proc_sfrwrites_transfer mmu_proc_sfrwrites_transfer_t;
   
   string v_name;
   longint req_time;

   rand int unsigned req_lat;
   rand cpu_wr_reg_cmd_t cmd;
   rand  logic [7:0] cpu_wr_reg_idx_i;
   rand  logic [31:0] cpu_wr_reg_val_i;

   `uvm_object_utils_begin(mmu_proc_sfrwrites_transfer_t)
      `uvm_field_enum(cpu_wr_reg_cmd_t, cmd,  UVM_ALL_ON|UVM_NOPACK)
      `uvm_field_int (req_lat, UVM_ALL_ON|UVM_NOPACK)
      `uvm_field_int(cpu_wr_reg_idx_i, UVM_ALL_ON|UVM_NOPACK)
      `uvm_field_int(cpu_wr_reg_val_i, UVM_ALL_ON|UVM_NOPACK)       
   `uvm_object_utils_end
    function new(string name = "mmu_proc_sfrwrites_transfer_inst");
        super.new(name);
    endfunction : new

endclass : mmu_proc_sfrwrites_transfer

`endif
