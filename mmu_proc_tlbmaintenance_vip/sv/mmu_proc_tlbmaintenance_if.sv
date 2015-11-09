/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_tlbmaintenance_if.sv
* DEVICE:    MMU_PROC_TLBMAINTENANCE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_TLBMAINTENANCE_IF_SV
`define MMU_PROC_TLBMAINTENANCE_IF_SV

//------------------------------------------------------------------------------
//
// INTERFACE: mmu_proc_tlbmaintenance_if
//
//------------------------------------------------------------------------------


typedef enum logic {NO_CANCEL,CANCEL_ALLOWED} cancel_mode_t;

interface mmu_proc_tlbmaintenance_if;

  logic clock;
  logic reset;
  
  
  cancel_mode_t cancel_mode_i_m;

  logic tlbread_i_m;
  logic tlbwrite_i_m;
  logic tlbprobe_i_m;
  logic tlbindexl_i_m;
  logic tlbindexj_i_m;
  logic tlbinvald_i_m;
  logic tlbinvali_i_m;
  logic f_stall_mmu_o;
  logic rr_stall_mmu_o;

  logic mmc_e;
  logic [8:0] mmc_idx;
endinterface : mmu_proc_tlbmaintenance_if

`endif
