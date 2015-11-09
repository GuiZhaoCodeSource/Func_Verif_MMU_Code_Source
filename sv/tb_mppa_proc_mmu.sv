/******************************************************************************
 *
 * MODULE:name
 * DEVICE:MMU
 * PROJECT:Functional Verification of the MMU of a multiprocessor 
 * AUTHOR:Gui ZHAO
 * DATE: 01/04/2015
 *
 * ABSTRACT:
 *
 *******************************************************************************/
`ifndef TB_MPPA_PROC_MMU
`define TB_MPPA_PROC_MMU

`timescale 1ns/1ps
        
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "mmu_proc_sfrwrites_if.sv"
`include "mmu_proc_sfrwrites.svh"
`include "mmucfg_if.sv"
`include "mmucfg.svh"
`include "mmu_proc_sfrreads_if.sv"
`include "mmu_proc_sfrreads.svh"
`include "mmu_proc_tlbmaintenance_if.sv"
`include "mmu_proc_tlbmaintenance.svh"
`include "mmu_proc_dcache_if.sv"
`include "mmu_proc_dcache.svh"
`include "mmu_dcache_if.sv"
`include "mmu_dcache.svh"

module tb_mppa_proc_mmu;
  
	`include "tb_mppa_proc_mmu_tests.sv"

	reg clock;
	reg reset;
  logic [31:0]  mmc_reg;
	initial begin
		uvm_top.run_test();
	end

	// MMU CFG interface declaration
	mmucfg_if mmucfg_intf();

	// MMU SFR Write interface declaration
	mmu_proc_sfrwrites_if mmu_proc_sfrwrites_intf();
   
    // MMU SFR Read interface declaration
	mmu_proc_sfrreads_if mmu_proc_sfrreads_intf();
  
    // MMU TLB maintenance interface declaration
    mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_intf();
  
    // MMU PROC DCACHE interface declaration
    mmu_proc_dcache_if mmu_proc_dcache_intf();
  
  // MMU DCACHE interface declaration
    mmu_dcache_if mmu_dcache_intf();


  
	// trial of MMUCFG
   
/*    bit         mmu_enable;
    bit         proc_in_debug;
    bit 	    priviledge_mode;
    bit 	    k1_64_mode;
    logic [4:0] smem_ext_cfg;

    //  trial of MMU_SFR_WRITE
    cpu_wr_reg_cmd_t cpu_wr_reg_cmd_i;
    bit          cpu_wr_reg_en_i;
    logic   [7:0] cpu_wr_reg_idx_i;
    logic  [31:0] cpu_wr_reg_val_i;
   
    // trial of MMU_SFR_READ
    logic        f_sfr_read_en_i;
    logic [7:0]  f_sfr_read_idx_i;
    logic        rr_stall_i;
    logic [31:0] rr_result_o;*/

	assign mmucfg_intf.reset = reset;
	assign mmucfg_intf.clock = clock;
   
   	assign mmu_proc_sfrwrites_intf.reset = reset;
	assign mmu_proc_sfrwrites_intf.clock = clock;
   
	assign mmu_proc_sfrreads_intf.reset = reset;
	assign mmu_proc_sfrreads_intf.clock = clock;
  
    assign mmu_proc_tlbmaintenance_intf.reset = reset;
	assign mmu_proc_tlbmaintenance_intf.clock = clock;
  
    assign mmu_proc_dcache_intf.reset = reset;
    assign mmu_proc_dcache_intf.clock = clock;
  
    assign mmu_dcache_intf.reset = reset;
    assign mmu_dcache_intf.clock = clock;
  
  /*
   assign mmu_enable       = mmucfg_intf.mmu_enable_m;
   assign proc_in_debug    = mmucfg_intf.processor_in_debug_m;
   assign priviledge_mode  = mmucfg_intf.priviledge_mode_m;
   assign k1_64_mode       = mmucfg_intf.k1_64_mode_m;
   assign smem_ext_cfg     = mmucfg_intf.smem_ext_cfg_m;
   
   assign cpu_wr_reg_cmd_i    = mmu_proc_sfrwrites_intf.cpu_wr_reg_cmd_i_m;
   assign cpu_wr_reg_idx_i    = mmu_proc_sfrwrites_intf.cpu_wr_reg_idx_i_m;
   assign cpu_wr_reg_val_i    = mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m;
   assign cpu_wr_reg_en_i     = mmu_proc_sfrwrites_intf.cpu_wr_reg_en_i_m;
   
   assign f_sfr_read_idx_i    = mmu_proc_sfrreads_intf.f_sfr_read_idx_i_m;
   assign rr_stall_i          = mmu_proc_sfrreads_intf.rr_stall_i_m;
   assign f_sfr_read_en_i     = mmu_proc_sfrreads_intf.f_sfr_read_en_i_m;
   assign mmu_proc_sfrreads_intf.rr_result_o = rr_result_o;
    
  
   assign tlbread_i    = mmu_proc_tlbmaintenance_intf.tlbread_i_m;
   assign tlbwrite_i   = mmu_proc_tlbmaintenance_intf.tlbwrite_i_m;
   assign tlbprobe_i   = mmu_proc_tlbmaintenance_intf.tlbprobe_i_m;
   assign tlbindexl_i  = mmu_proc_tlbmaintenance_intf.tlbindexl_i_m;
   assign tlbindexj_i  = mmu_proc_tlbmaintenance_intf.tlbindexj_i_m;
   assign tlbinvald_i  = mmu_proc_tlbmaintenance_intf.tlbinvald_i_m;    
   assign tlbinvali_i  = mmu_proc_tlbmaintenance_intf.tlbinvali_i_m;
   assign f_stall_mmu_o= mmu_proc_tlbmaintenance_intf.f_stall_mmu_o;
   assign rr_stall_mmu_o = mmu_proc_tlbmaintenance_intf.rr_stall_mmu_o;

   */
  
  assign mmu_proc_dcache_intf.dcache_e3_stall_i_o = mmu_dcache_intf.dcache_e3_stall_i_s;
  assign mmu_proc_dcache_intf.dcache_e1_grant_i_o = mmu_dcache_intf.dcache_e1_grant_i_s;
  assign mmu_proc_dcache_intf.e2_stall_o          = mmu_dcache_intf.e2_stall_m;
  assign mmu_dcache_intf.e1_dcache_req_m          = mmu_proc_dcache_intf.e1_dcache_req_i_m;


  assign mmu_dcache_intf.e1_dcache_virt_addr_m    = mmu_proc_dcache_intf.e1_dcache_virt_addr_i_m;
  assign mmu_dcache_intf.e1_dcache_size_m         = mmu_proc_dcache_intf.e1_dcache_size_i_m;
  assign mmu_dcache_intf.e1_dcache_opc_i_m         = mmu_proc_dcache_intf.e1_dcache_opc_i_m;

  assign mmu_dcache_intf.e2_non_trapping_id_cancel_o = mmu_proc_dcache_intf.e2_non_trapping_id_cancel_o; 
  assign mmu_dcache_intf.e2_trap_nomapping_o         = mmu_proc_dcache_intf.e2_trap_nomapping_o;       
  assign mmu_dcache_intf.e2_trap_protection_o        = mmu_proc_dcache_intf.e2_trap_protection_o;       
  assign mmu_dcache_intf.e2_trap_writetoclean_o      = mmu_proc_dcache_intf.e2_trap_writetoclean_o;    
  assign mmu_dcache_intf.e2_trap_atomictoclean_o     = mmu_proc_dcache_intf.e2_trap_atomictoclean_o;    
  assign mmu_dcache_intf.e2_trap_dmisalign_o         = mmu_proc_dcache_intf.e2_trap_dmisalign_o;        
  assign mmu_dcache_intf.e2_trap_dsyserror_o         = mmu_proc_dcache_intf.e2_trap_dsyserror_o;


  //$display("GG:k1_mmu_wrapper_0:%0X",k1_mmu_wrapper_0.k1_mmu_0.mmc_d);
  //assign  mmc_reg = k1_mmu_wrapper_0.k1_mmu_0.mmc_q;
  
  assign mmu_proc_tlbmaintenance_intf.mmc_e   = k1_mmu_wrapper_0.k1_mmu_0.mmc_q.ERROR;
  assign mmu_proc_tlbmaintenance_intf.mmc_idx   = k1_mmu_wrapper_0.k1_mmu_0.mmc_q.INDEX;
   
	initial begin
		clock <= 1'b0;
		forever #5 clock <= !clock;
	end

	initial begin
		reset = 1;
		#100;
		reset = 0;
	end

  //  assign rr_result_o = 'hA55A_FF00;


  

   k1_mmu_wrapper k1_mmu_wrapper_0 (
                                     
        .clk(clock),
        .reset(reset),
                                    
        .mmu_enable_i(mmucfg_intf.mmu_enable_m),
     	.processor_in_debug_i(mmucfg_intf.processor_in_debug_m),
    	.privilege_mode_i(mmucfg_intf.priviledge_mode_m),
	    .k1_64_mode_i (mmucfg_intf.k1_64_mode_m),
	    .smem_ext_cfg_i (mmucfg_intf.smem_ext_cfg_m),
   
// maintenance instructions interface with core
        .tlbread_i(mmu_proc_tlbmaintenance_intf.tlbread_i_m),
        .tlbwrite_i(mmu_proc_tlbmaintenance_intf.tlbwrite_i_m),
        .tlbprobe_i(mmu_proc_tlbmaintenance_intf.tlbprobe_i_m),
        .tlbindexl_i(mmu_proc_tlbmaintenance_intf.tlbindexl_i_m),
        .tlbindexj_i(mmu_proc_tlbmaintenance_intf.tlbindexj_i_m),
        .tlbinvald_i(mmu_proc_tlbmaintenance_intf.tlbinvald_i_m),    
        .tlbinvali_i(mmu_proc_tlbmaintenance_intf.tlbinvali_i_m),  
        .f_stall_mmu_o(mmu_proc_tlbmaintenance_intf.f_stall_mmu_o),
        .rr_stall_mmu_o(mmu_proc_tlbmaintenance_intf.rr_stall_mmu_o),
// data side proc interface
        .e1_dcache_req_i(mmu_proc_dcache_intf.e1_dcache_req_i_m),
        .dcache_e3_stall_i(mmu_dcache_intf.dcache_e3_stall_i_s),
        .e1_dcache_virt_addr_i(mmu_proc_dcache_intf.e1_dcache_virt_addr_i_m),
        .e1_dcache_opc_i(6'(mmu_proc_dcache_intf.e1_dcache_opc_i_m)),
        .e1_glob_acc_i(mmu_proc_dcache_intf.e1_glob_acc_i_m),
        .e1_dcache_size_i(mmu_proc_dcache_intf.e1_dcache_size_i_m),
        .e1_non_trapping_i(mmu_proc_dcache_intf.e1_non_trapping_i_m),
    
        .e2_non_trapping_ld_cancel_o(mmu_proc_dcache_intf.e2_non_trapping_id_cancel_o),
        .e2_trap_nomapping_o(mmu_proc_dcache_intf.e2_trap_nomapping_o),
        .e2_trap_protection_o(mmu_proc_dcache_intf.e2_trap_protection_o),
        .e2_trap_writetoclean_o(mmu_proc_dcache_intf.e2_trap_writetoclean_o),
        .e2_trap_atomictoclean_o(mmu_proc_dcache_intf.e2_trap_atomictoclean_o),
        .e2_trap_dmisalign_o(mmu_proc_dcache_intf.e2_trap_dmisalign_o),
        .e2_trap_dsyserror_o(mmu_proc_dcache_intf.e2_trap_dsyserror_o),
//interface with dcache
        .e2_dcache_phys_addr_o(mmu_dcache_intf.e2_dcache_phys_addr_m),
        .e2_dcache_cluster_per_acc_o(mmu_dcache_intf.e2_dcache_cluster_per_acc_m),
        .e2_dcache_policy_o(mmu_dcache_intf.e2_dcache_policy_m),
        .e2_stall_o(mmu_dcache_intf.e2_stall_m),
        .dcache_e1_grant_i(mmu_dcache_intf.dcache_e1_grant_i_s),
        .dcache_second_acc_d_i(mmu_dcache_intf.dcache_second_acc_d_i_s),
// instruction side proc/cache interface
        .icache_req_i(1'b0),
        .icache_cancel_i(1'b0),
        .icache_virt_addr_i(39'b0),
        .icache_phys_addr_o(),
        .icache_cluster_per_acc_o(),

        .icache_datar_v_hacked_o(),
        .gate_icache_req_o(),
        .gate_icache_grant_o(),
        .ins_trap_nomapping_o(),
        .ins_trap_protection_o(),
        .ins_trap_psyserror_o(),
//interface with icache
        .icache_grant_i(1'b0),
        .icache_datar_v_i(4'b0),
        .icache_replay_req_o(),
        .icache_replay_addr_o(),
        .force_i_hit_o(),
        .i_cached_acc_o(),

/* -- Far SFR interface
-----------------------------------------------------------------------
-- Core write interface
-----------------------------------------------------------------------*/                                       
        .cpu_wr_reg_cmd_i(2'(mmu_proc_sfrwrites_intf.cpu_wr_reg_cmd_i_m)),// force to change the type string to the type bit                           
        .cpu_wr_reg_idx_i (mmu_proc_sfrwrites_intf.cpu_wr_reg_idx_i_m),
        .cpu_wr_reg_val_i (mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m),
        .cpu_wr_reg_en_i  (mmu_proc_sfrwrites_intf.cpu_wr_reg_en_i_m),

/*-----------------------------------------------------------------------
-- Core mmc HW updates interface
-----------------------------------------------------------------------*/
        .e3_update_mmc_ptc_i(1'b0),
        .e3_update_mmc_S_i(1'b0),
        .e3_mmc_ptc_i(2'b0),
        .e3_mmc_S_i(1'b0),
/*-----------------------------------------------------------------------
-- Core read interface
-----------------------------------------------------------------------*/                                   
        .f_sfr_read_idx_i(mmu_proc_sfrreads_intf.f_sfr_read_idx_i_m),
        .rr_stall_i (mmu_proc_sfrreads_intf.rr_stall_i_m),
        .f_sfr_read_en_i (mmu_proc_sfrreads_intf.f_sfr_read_en_i_m),
        .rr_result_o (mmu_proc_sfrreads_intf.rr_result_o)
        
    );



endmodule

`endif





