/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_if.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_IF_SV
`define MMUCFG_IF_SV

//------------------------------------------------------------------------------
//
// INTERFACE: mmucfg_if
//
//------------------------------------------------------------------------------

interface mmucfg_if;

    logic clock;
    logic reset;

    logic mmu_enable_m;
    logic processor_in_debug_m;
    logic priviledge_mode_m;
    logic k1_64_mode_m;
    logic [4:0] smem_ext_cfg_m;

    

endinterface : mmucfg_if

`endif
