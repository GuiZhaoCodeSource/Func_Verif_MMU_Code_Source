/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrwrites_if.sv
* DEVICE:    MMU_PROC_SFRWRITES VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRWRITES_IF_SV
`define MMU_PROC_SFRWRITES_IF_SV

//------------------------------------------------------------------------------
//
// INTERFACE: mmu_proc_sfrwrites_if
//
//------------------------------------------------------------------------------

typedef enum logic[1:0] {SET='b00,HFXB='b01,HFXT='b10,RES='b11} cpu_wr_reg_cmd_t;

interface mmu_proc_sfrwrites_if;

    logic clock;
    logic reset;
   
    cpu_wr_reg_cmd_t cpu_wr_reg_cmd_i_m;
    logic        cpu_wr_reg_en_i_m;
    logic [7:0]  cpu_wr_reg_idx_i_m;
    logic [31:0] cpu_wr_reg_val_i_m;

endinterface : mmu_proc_sfrwrites_if

`endif
