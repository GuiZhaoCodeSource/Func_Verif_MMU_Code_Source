/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_if.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_IF_SV
`define MMU_DCACHE_IF_SV

//------------------------------------------------------------------------------
//
// INTERFACE: mmu_dcache_if
//
//------------------------------------------------------------------------------
//#define pa_nbbits  36

interface mmu_dcache_if;

  logic clock;
  logic reset;

  // drived by D$
  logic         dcache_second_acc_d_i_s;
  logic         dcache_e3_stall_i_s;
  logic         dcache_e1_grant_i_s;

  // drived by proc
  logic         e1_dcache_req_m;
  logic [40:0]  e1_dcache_virt_addr_m;
  logic [3:0]   e1_dcache_size_m;
  e1_dcache_opc_t e1_dcache_opc_i_m;

  // drived by MMU
  logic         e2_stall_m;
  logic [21:12] e2_dcache_phys_addr_m;
  logic         e2_dcache_cluster_per_acc_m;
  logic         e2_dcache_policy_m;
  logic         e2_non_trapping_id_cancel_o;
  logic [1:0]   e2_trap_nomapping_o;       
  logic [1:0]   e2_trap_protection_o;       
  logic [1:0]   e2_trap_writetoclean_o;    
  logic [1:0]   e2_trap_atomictoclean_o;    
  logic         e2_trap_dmisalign_o;        
  logic [1:0]   e2_trap_dsyserror_o;


endinterface : mmu_dcache_if

`endif
