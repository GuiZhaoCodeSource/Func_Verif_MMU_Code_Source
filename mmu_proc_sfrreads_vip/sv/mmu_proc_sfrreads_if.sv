/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrreads_if.sv
* DEVICE:    MMU_PROC_SFRREADS VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRREADS_IF_SV
`define MMU_PROC_SFRREADS_IF_SV

//------------------------------------------------------------------------------
//
// INTERFACE: mmu_proc_sfrreads_if
//
//------------------------------------------------------------------------------

interface mmu_proc_sfrreads_if;

   logic  clock;
   logic  reset;

   logic        f_sfr_read_en_i_m;
   logic [7:0]  f_sfr_read_idx_i_m;
   logic        rr_stall_i_m;
   logic [31:0] rr_result_o;
   
   
endinterface : mmu_proc_sfrreads_if

`endif
