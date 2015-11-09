/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrreads.svh
* DEVICE:    MMU_PROC_SFRREADS VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRREADS_SVH
`define MMU_PROC_SFRREADS_SVH

// Include
`include "mmu_proc_sfrreads_transfer.sv"
`include "mmu_proc_sfrreads_master_sequencer.sv"
`include "mmu_proc_sfrreads_master_driver.sv"
`include "mmu_proc_sfrreads_master_agent.sv"
`include "mmu_proc_sfrreads_slave_sequencer.sv"
`include "mmu_proc_sfrreads_slave_driver.sv"
`include "mmu_proc_sfrreads_slave_agent.sv"
`include "mmu_proc_sfrreads_bus_monitor.sv"
`include "mmu_proc_sfrreads_env.sv"
`endif
