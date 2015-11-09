/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrwrites.svh
* DEVICE:    MMU_PROC_SFRWRITES VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRWRITES_SVH
`define MMU_PROC_SFRWRITES_SVH

// Include
`include "mmu_proc_sfrwrites_transfer.sv"
`include "mmu_proc_sfrwrites_master_sequencer.sv"
`include "mmu_proc_sfrwrites_master_driver.sv"
`include "mmu_proc_sfrwrites_master_agent.sv"
`include "mmu_proc_sfrwrites_slave_sequencer.sv"
`include "mmu_proc_sfrwrites_slave_driver.sv"
`include "mmu_proc_sfrwrites_slave_agent.sv"
`include "mmu_proc_sfrwrites_bus_monitor.sv"
`include "mmu_proc_sfrwrites_env.sv"
`endif
