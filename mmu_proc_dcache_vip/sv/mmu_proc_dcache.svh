/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_dcache.svh
* DEVICE:    MMU_PROC_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_DCACHE_SVH
`define MMU_PROC_DCACHE_SVH

// Include
`include "mmu_proc_dcache_transfer.sv"
`include "mmu_proc_dcache_master_sequencer.sv"
`include "mmu_proc_dcache_master_driver.sv"
`include "mmu_proc_dcache_master_agent.sv"
`include "mmu_proc_dcache_slave_sequencer.sv"
`include "mmu_proc_dcache_slave_driver.sv"
`include "mmu_proc_dcache_slave_agent.sv"
`include "mmu_proc_dcache_bus_monitor.sv"
`include "mmu_proc_dcache_env.sv"
`endif
