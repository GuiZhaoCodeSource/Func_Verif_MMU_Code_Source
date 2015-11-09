/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_dcache_if.sv
* DEVICE:    MMU_PROC_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_DCACHE_IF_SV
`define MMU_PROC_DCACHE_IF_SV

//------------------------------------------------------------------------------
//
// INTERFACE: mmu_proc_dcache_if
//
//------------------------------------------------------------------------------
typedef enum logic[5:0] {LOAD='b000001,STORE='b000010,DZEROL='b100000,DINVALL='b011000,DTOUCHL='b011100,DINVAL='b111000,WPURGE='b001000, LDC='b000011, FDA='b000111, CWS='b001111} e1_dcache_opc_t;

interface mmu_proc_dcache_if;

  logic       clock;
  logic       reset;
 
  logic       e1_dcache_req_i_m;
  logic [40:0]e1_dcache_virt_addr_i_m;
  logic       e1_glob_acc_i_m;
  logic [3:0] e1_dcache_size_i_m;
  logic       e1_non_trapping_i_m;
  e1_dcache_opc_t e1_dcache_opc_i_m;

  logic       dcache_e1_grant_i_o;
  logic       dcache_e3_stall_i_o;
  logic       e2_stall_o;
  
  logic       e2_non_trapping_id_cancel_o;
  logic [1:0] e2_trap_nomapping_o;
  logic [1:0] e2_trap_protection_o;
  logic [1:0] e2_trap_writetoclean_o;
  logic [1:0] e2_trap_atomictoclean_o;
  logic       e2_trap_dmisalign_o;
  logic [1:0] e2_trap_dsyserror_o;

  
endinterface : mmu_proc_dcache_if

`endif
