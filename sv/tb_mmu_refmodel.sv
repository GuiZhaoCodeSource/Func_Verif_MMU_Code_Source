/******************************************************************************
 * (C) Copyright 2009 Kalray All Rights Reserved
 *
 * MODULE:name
 * DEVICE:
 * PROJECT:
 * AUTHOR:jbarbiero
 * DATE:
 *
 * ABSTRACT:
 *
 *******************************************************************************/
`ifndef MMU_REFMODEL
 `define MMU_REFMODEL
 `include "tb_mmu_registers.sv"

typedef class tlb_c ;
typedef class mmu_dcache_trans;
typedef class mmu_dcache_reponse;


class tb_mmu_refmodel extends uvm_component;
  

  `uvm_component_param_utils(tb_mmu_refmodel)
  
     
  virtual interface mmucfg_if mmucfg_intf;
  virtual interface mmu_proc_sfrwrites_if mmu_proc_sfrwrites_intf;
  virtual interface mmu_proc_sfrreads_if mmu_proc_sfrreads_intf;
  virtual interface mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_intf;
  virtual interface mmu_proc_dcache_if mmu_proc_dcache_intf;
  virtual interface mmu_dcache_if mmu_dcache_intf;

  tb_mmu_coverage  tb_mmu_coverage_inst;
  
  typedef mmu_proc_sfrreads_transfer mmu_proc_sfrreads_transfer_t;
  
  function new(string name, uvm_component parent);
	  super.new(name, parent);
  endfunction : new

  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  
  function void assign_vi(virtual interface mmucfg_if mmucfg_intf, virtual interface mmu_proc_sfrwrites_if mmu_proc_sfrwrites_intf, virtual interface mmu_proc_sfrreads_if mmu_proc_sfrreads_intf,virtual interface mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_intf, virtual interface mmu_proc_dcache_if mmu_proc_dcache_intf,virtual interface mmu_dcache_if mmu_dcache_intf);
    this.mmucfg_intf = mmucfg_intf;
    this.mmu_proc_sfrwrites_intf = mmu_proc_sfrwrites_intf;
    this.mmu_proc_sfrreads_intf = mmu_proc_sfrreads_intf;
    this.mmu_proc_tlbmaintenance_intf=mmu_proc_tlbmaintenance_intf;
    this.mmu_proc_dcache_intf=mmu_proc_dcache_intf;
    this.mmu_dcache_intf=mmu_dcache_intf;
  endfunction : assign_vi

  // Monitors classes
  extern task mmu_sfrwrites_access_management();
  extern task mmu_sfrreads_access_management();
  extern task instruction_maintenance_management();
  extern task dcache_request_management();
  extern task dcache_reponse_management();
  extern task store_dcache_reponse(int resp_flag);
  extern task trap_protection_management(logic [31:0] virt_addr, int addr_size, logic [31:0] last_line_addr, int second_access, int found, int pre_idx_found,int pre_idx, int es, 
                                         int priviledge_mode_random, int pa, int different_cp_flag, e1_dcache_opc_t opcode, int e2_trap_protection_o, 
                                         int e2_trap_nomapping_o, int trap_nomapping_flag, int e1_non_trapping_i, 
                                         int spe , int idx, output int trap_protection_flag);
  extern task trap_nomapping_management(logic [31:0] virt_addr, int addr_size, logic [31:0] last_line_addr, int es, int found, int sne, int e1_non_trapping_i,int pre_idx_found,
                                        int pre_idx, int e2_trap_nomapping_o, int second_access, e1_dcache_opc_t opcode, output int trap_nomapping_flag);
  integer fileID;
  string  v_name;
  int     traps_disabled;
  integer fileID_address;
  tlb_c   tlb_array[264];
  longint unsigned virt_address_continu[$];
  int     trap_flag,check_mmc_e_flag,index_ltlb_mode;
   
  mmu_reg_blk mmu_registers;

  mmu_proc_sfrreads_transfer_t cur_trans;
  mmu_proc_sfrreads_transfer_t mmu_proc_sfrreads_queue[$];
      
  mmu_dcache_trans dcache_trans;
  mmu_dcache_trans dcache_request_queue[$];

  event   response_done_ev;

    // Called at the end of simulation
  function void check();
      if (mmu_proc_sfrreads_queue.size != 0)
        `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [FINAL_CHECK]: pending transaction in SFRs read queue!"));
      if (dcache_request_queue.size != 0)
        `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [FINAL_CHECK]: pending transaction in Proc Dcache queue!"));

      $display("\n\t\t*********************************\n\t\t     END of Check Detected\n\t\t*********************************");

      // Display some information
      $display("\n\t\t*********************************\n\t\t     Information  \n\t\t*********************************"); 
      for(int i=0;i<264;i++)begin
          if((tlb_array[i].last_addr_is_used == 1) || (tlb_array[i].last_addr_use_times > 0)) begin
              $display("TLB ARRAY[%0d] have used the last address and use time is %0d",i,tlb_array[i].last_addr_use_times);
          end
          if((tlb_array[i].first_addr_is_used == 1) || (tlb_array[i].first_addr_use_times > 0)) begin
              $display("TLB ARRAY[%0d] have used the first address and use time is %0d",i,tlb_array[i].first_addr_use_times);
          end
      end

     
      
  endfunction
  
endclass : tb_mmu_refmodel

function void tb_mmu_refmodel::build_phase(uvm_phase phase);
	super.build_phase(phase);
    mmu_registers = mmu_reg_blk::type_id::create("mmu_reg");
	mmu_registers.build();

    tb_mmu_coverage_inst = tb_mmu_coverage::type_id::create("tb_mmu_coverage_inst", this);

endfunction : build_phase

function void tb_mmu_refmodel::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
endfunction : connect_phase


task tb_mmu_refmodel::run_phase(uvm_phase phase);
    bit check_on_going;
	super.run_phase(phase);

    if ((fileID = $fopen("tb_mppa_logger.log", "w")) == 0) begin
        $display($psprintf("Error opening 'mmu_configure_%s.log' file", v_name));
    end

    mmu_registers.mmu_mmc.reset();
    mmu_registers.mmu_tel.reset();
    mmu_registers.mmu_teh.reset();    
    
	fork
        mmu_sfrwrites_access_management();
        mmu_sfrreads_access_management();     
        instruction_maintenance_management() ;
        dcache_request_management();
        dcache_reponse_management(); 
	join_none
    check_on_going = 0;
	forever begin
		if ((mmu_proc_sfrreads_queue.size() != 0 || dcache_request_queue.size() != 0) && check_on_going == 0) begin
			check_on_going = 1;
			`uvm_info(get_type_name(), $psprintf("Refmodel raising objection"), UVM_HIGH)
			uvm_test_done.raise_objection(this);
		end
		else if (mmu_proc_sfrreads_queue.size() == 0 && dcache_request_queue.size() == 0 && check_on_going == 1) begin
			check_on_going = 0;
            @(posedge mmu_proc_sfrwrites_intf.clock);
			`uvm_info(get_type_name(), $psprintf("Refmodel dropping objection"), UVM_HIGH)
			uvm_test_done.drop_objection(this);
		end
      
		@(posedge mmu_proc_sfrwrites_intf.clock);
	end
endtask : run_phase

/*----------------------------- monitors -----------------------------*/
task tb_mmu_refmodel :: mmu_sfrwrites_access_management();

    @(negedge mmu_proc_sfrwrites_intf.reset)
        
      forever begin
          @(negedge mmu_proc_sfrwrites_intf.clock)
              
            if (mmu_proc_sfrwrites_intf.cpu_wr_reg_en_i_m === 1)begin
                
                if(mmu_proc_sfrwrites_intf.cpu_wr_reg_idx_i_m== MMC)begin 
                    
                    mmu_registers.mmu_mmc.set(mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m);
                    $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_WRITES]: MMC= 'h%0X E:%0X, IDX:%0d, PTC:%0X, SPE:%0d, SNE:%0X, LPS:%0X, DPS:%0X, S:%0X, ASN:%0X ", $time,mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m, mmu_registers.mmu_mmc.e.get(),mmu_registers.mmu_mmc.idx.get(),mmu_registers.mmu_mmc.ptc.get(),mmu_registers.mmu_mmc.spe.get(),mmu_registers.mmu_mmc.sne.get(),mmu_registers.mmu_mmc.lps.get(),mmu_registers.mmu_mmc.dps.get(),mmu_registers.mmu_mmc.s.get(),mmu_registers.mmu_mmc.asn.get() ));
		            `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_WRITES]: MMC= 'h%0X E:%0X, IDX:%0X, PTC:%0X, SPE:%0d, SNE:%0X, LPS:%0X, DPS:%0X, S:%0X, ASN:%0X ", $time,mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m, mmu_registers.mmu_mmc.e.get(),mmu_registers.mmu_mmc.idx.get(),mmu_registers.mmu_mmc.ptc.get(),mmu_registers.mmu_mmc.spe.get(),mmu_registers.mmu_mmc.sne.get(),mmu_registers.mmu_mmc.lps.get(),mmu_registers.mmu_mmc.dps.get(),mmu_registers.mmu_mmc.s.get(),mmu_registers.mmu_mmc.asn.get()), UVM_HIGH)
                end
                
                if(mmu_proc_sfrwrites_intf.cpu_wr_reg_idx_i_m==TEL)begin           
                    mmu_registers.mmu_tel.set(mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m);           
                    $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_WRITES]: TEL= 'h%0X ", $time,mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m));
		            `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_WRITES]: TEL= 'h%0X ", $time,mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m), UVM_HIGH)
                end
                
                if(mmu_proc_sfrwrites_intf.cpu_wr_reg_idx_i_m==TEH)begin
                    mmu_registers.mmu_teh.set(mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m);           
                    $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_WRITES]: TEH= 'h%0X ", $time,mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m));
                    
		            `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_WRITES]: TEH= 'h%0X ", $time,mmu_proc_sfrwrites_intf.cpu_wr_reg_val_i_m), UVM_HIGH)
                    
                end
            end
      end 
    
endtask: mmu_sfrwrites_access_management

task tb_mmu_refmodel::mmu_sfrreads_access_management();
  int index, mmc_e;
  logic [19:0] pn_temp,pn_idx;
    @(negedge mmu_proc_sfrreads_intf.reset)
      forever begin
          @(posedge mmu_proc_sfrreads_intf.clock)
              
            if (mmu_proc_sfrreads_queue.size == 1 && mmu_proc_sfrreads_intf.rr_stall_i_m==0)begin
                
                mmu_proc_sfrreads_queue[0].rr_results_o = mmu_proc_sfrreads_intf.rr_result_o;
                
                index =  mmu_registers.mmu_mmc.idx.get();
             //   tlb_array[index].array_to_reg(mmu_registers);
                
                if(cur_trans.f_sfr_read_idx_i==42)begin   
                    
                    $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_READS]-MMC: DUT= 'h%0X REF= 'h%0X ", $time,mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_mmc.get()));
                    `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_READS]-MMC: DUT= 'h%0X REF= 'h%0X ", $time,mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_mmc.get()), UVM_HIGH)
                    
                  
                    //index = mmu_proc_sfrreads_queue[0].rr_results_o[30:22];
                    mmc_e = mmu_proc_sfrreads_queue[0].rr_results_o[31];
                  
                    if(mmu_registers.mmu_mmc.get() !== mmu_proc_sfrreads_queue[0].rr_results_o && mmc_e == 0 && index_ltlb_mode == 0)begin
                      
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [SFR_READS]: Error on read value of MMC\n\tDUT= 'h%0X\n\tREF= 'h%0X ",mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_mmc.get()));
                    end
                    index_ltlb_mode = 0;
                    $display("GG:index:%0d mmc_e:%0d ",index,mmc_e);                          
                end
                
                if(cur_trans.f_sfr_read_idx_i==43)begin 
                    
                    $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_READS]-TEL: DUT= 'h%0X REF= 'h%0X ", $time,mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_tel.get()));
                    `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_READS]-TEL: DUT= 'h%0X REF= 'h%0X ", $time,mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_tel.get()), UVM_HIGH)
                   // BUG !!!!!! 
                   // if(mmu_registers.mmu_tel.get() !== mmu_proc_sfrreads_queue[0].rr_results_o && mmc_e == 0)
                     // `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [SFR_READS]: Error on read value of TEL\n\tDUT= 'h%0X\n\tREF= 'h%0X ",mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_tel.get()));
                    
                end
                
                if(cur_trans.f_sfr_read_idx_i==44)begin 
                    
                    $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_READS]-TEH: DUT= 'h%0X REF= 'h%0X ", $time,mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_teh.get()));
                    `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [SFR_READS]-TEH: DUT= 'h%0X REF= 'h%0X ", $time,mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_teh.get()), UVM_HIGH)
                    
                    if(mmu_registers.mmu_teh.get() !== mmu_proc_sfrreads_queue[0].rr_results_o && mmc_e == 0)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [SFR_READS]: Error on read value of TEH\n\tDUT= 'h%0X\n\tREF= 'h%0X ",mmu_proc_sfrreads_intf.rr_result_o, mmu_registers.mmu_teh.get()));
                    
                end

                mmu_proc_sfrreads_queue = {};
            end 

          if ((mmu_proc_sfrreads_intf.f_sfr_read_en_i_m == 1) && ( mmu_proc_sfrreads_intf.rr_stall_i_m == 0)) begin
              cur_trans = new;                
              cur_trans.f_sfr_read_idx_i = mmu_proc_sfrreads_intf.f_sfr_read_idx_i_m;
              mmu_proc_sfrreads_queue = {mmu_proc_sfrreads_queue, cur_trans};            

          end
      end
    
endtask : mmu_sfrreads_access_management 



task tb_mmu_refmodel::instruction_maintenance_management();
    
  int unsigned index;
  logic [19:0] pn_temp;
  logic [19:0] pn_idx;
    
    for(int i=0;i<$size(tlb_array);i++)begin 
       
        tlb_array[i]=new;    
        
    end 
    
    @(negedge mmu_proc_tlbmaintenance_intf.reset)
      forever begin
          @(posedge mmu_proc_tlbmaintenance_intf.clock)
            index = mmu_registers.mmu_mmc.idx.get();
          
/******************** Interface tlbwrite *****************************/ 
          
          if(mmu_proc_tlbmaintenance_intf.tlbwrite_i_m === 1)begin

              if(check_mmc_e_flag == 1)begin

                  tlb_array[index].reg_to_array(mmu_registers);
                  mmu_registers.mmu_mmc.e.set(1);
                  
                  $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_WRITES] No_Avail_Value into TLB_ARRAY[%0d]: PN='h%0X S='h%0X G='h%0X ASN='h%0X FN='h%0X AE='h%0X PA='h%0X CP='h%0X ES='h%0X Page Size:%0d", $time, index, tlb_array[index].pn, tlb_array[index].s,tlb_array[index].g,tlb_array[index].asn,tlb_array[index].fn, tlb_array[index].ae,tlb_array[index].pa,tlb_array[index].cp,tlb_array[index].es,tlb_array[index].page_size));           
                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_WRITES] No_Avail_Value into TLB_ARRAY[%0d]: PN='h%0X S='h%0X G='h%0X ASN='h%0X FN='h%0X AE='h%0X PA='h%0X CP='h%0X ES='h%0X Page Size:%0d", $time, index, tlb_array[index].pn, tlb_array[index].s,tlb_array[index].g,tlb_array[index].asn,tlb_array[index].fn, tlb_array[index].ae,tlb_array[index].pa,tlb_array[index].cp,tlb_array[index].es, tlb_array[index].page_size), UVM_HIGH)
              end              
              else begin
                  
                  tlb_array[index].reg_to_array(mmu_registers);
                  mmu_registers.mmu_mmc.e.set(0);
                  
                  $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_WRITES] into TLB_ARRAY[%0d]: PN='h%0X S='h%0X G='h%0X ASN='h%0X FN='h%0X AE='h%0X PA='h%0X CP='h%0X ES='h%0X Page Size:%0d", $time, index, tlb_array[index].pn, tlb_array[index].s,tlb_array[index].g,tlb_array[index].asn,tlb_array[index].fn, tlb_array[index].ae,tlb_array[index].pa,tlb_array[index].cp,tlb_array[index].es,tlb_array[index].page_size));           
                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_WRITES] into TLB_ARRAY[%0d]: PN='h%0X S='h%0X G='h%0X ASN='h%0X FN='h%0X AE='h%0X PA='h%0X CP='h%0X ES='h%0X Page Size:%0d", $time, index, tlb_array[index].pn, tlb_array[index].s,tlb_array[index].g,tlb_array[index].asn,tlb_array[index].fn, tlb_array[index].ae,tlb_array[index].pa,tlb_array[index].cp,tlb_array[index].es, tlb_array[index].page_size), UVM_HIGH)
              end
                

 /*----------------------------------  Checker of the MMC_E  ---------------------------*/               
              @(posedge mmu_proc_tlbmaintenance_intf.clock)
                  
                pn_temp = tlb_array[index].pn >> (tlb_array[index].no_usefull_bit - 1);
              pn_idx = tlb_array[index].pn >> tlb_array[index].no_usefull_bit;
              
              if (index > $size(tlb_array) || (index > 127 && index < 256))begin
                  if(mmu_proc_tlbmaintenance_intf.mmc_e != 1)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The MMC_E must be 1 when the index is not correct ", $time,index))
                  end
              end                
              else if((pn_temp << (tlb_array[index].no_usefull_bit - 1)) != tlb_array[index].pn)begin
                  if(mmu_proc_tlbmaintenance_intf.mmc_e != 1)begin
                      if(tlb_array[index].page_size != 4096 && mmu_registers.mmu_tel.es.get != 0)
                        `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The MMC_E must be 1 when the pn did not respect the page size ", $time,index))
                      //It s a bug, must contact with Vincent
                  end  
              end
              else if(tlb_array[index].pn == 0 && tlb_array[index].s == 0)begin
                  $display("GG:tlb_array[index].pn:%0X",tlb_array[index].pn);
                  if(mmu_proc_tlbmaintenance_intf.mmc_e != 1)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The MMC_E must be 1 when pn and s is 0 ", $time,index))                        
                  end 
              end
              else if(pn_idx[5:0] != index/2)begin
                  if(index >=0 && index <= 127)begin
                      if(mmu_proc_tlbmaintenance_intf.mmc_e != 1  && mmu_registers.mmu_tel.es.get != 0)begin
                          `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The MMC_E must be 1 when the pn is not correct with the IDX ", $time,index))
                      end
                  end
              end
              else if(index >=0 && index <= 127)begin
                  if(index[0] == 0)begin
                      $display("GG:idx:%0d no_usefull_bit:%0d dps:%0d lps:%0d",index,tlb_array[index].no_usefull_bit,mmu_registers.mmu_mmc.dps.get,mmu_registers.mmu_mmc.lps.get);
                      if(pn_temp[0] != 1)begin
                          if(mmu_proc_tlbmaintenance_intf.mmc_e != 1)begin
                              `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The MMC_E must be 1 when the pn is not correct with the DPS ", $time,index))
                          end
                      end
                  end
                  else begin
                      // The calculation is very complecated, do it later if I have the enough time 
                  end

              end                    
              else begin
                  if(mmu_proc_tlbmaintenance_intf.mmc_e != 0)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The MMC_E must be 0 when the TLB Write is correct ", $time,index))
                  end
              end

              
              $display("GG:mmc_e:%0d [%0d]",  mmu_proc_tlbmaintenance_intf.mmc_e,$time);
          end // if (mmu_proc_tlbmaintenance_intf.tlbwrite_i_m === 1)
          
          
/****************************** Interface tlbread ******************************/
          
          if(mmu_proc_tlbmaintenance_intf.tlbread_i_m == 1)begin
              
              if((index > $size(tlb_array)) || (index > 127 && index < 256))   begin
                  mmu_registers.mmu_mmc.e.set(1);
                  `uvm_info(get_type_name(), $psprintf("[MMU_REFMODEL]: [TLB_READS]: Error: MMC.IDX value is out of the architectual TLB ranges"), UVM_HIGH)
              end              
              else begin
                  tlb_array[index].array_to_reg(mmu_registers);
                  mmu_registers.mmu_mmc.e.set(0);
              end
              
              $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_READS]  from TLB_ARRAY[%0d]: TEH= 'h%0X TEL= 'h%0X ", $time, index, mmu_registers.mmu_teh.get(), mmu_registers.mmu_tel.get()));
              `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_READS]  from TLB_AARAY[%0d]: TEH= 'h%0X TEL= 'h%0X ", $time, index, mmu_registers.mmu_teh.get(), mmu_registers.mmu_tel.get()), UVM_HIGH) 
          end 
          
          
/****************** Interface tlbprobe *****************************/
          
          if(mmu_proc_tlbmaintenance_intf.tlbprobe_i_m == 1)begin 
            int i;
            int unsigned tlb_found = 0;
              index_ltlb_mode = 1;
              for(i=0;i<264;i++)begin
                  
                  if(mmucfg_intf.k1_64_mode_m == 0 && mmu_registers.mmu_teh.g.get() == 1 )begin //in the k1_32_mode

                      if((mmu_registers.mmu_teh.pn.get() == tlb_array[i].pn) && (tlb_array[i].es !=0))begin
                          mmu_registers.mmu_mmc.idx.set(tlb_array[i].idx);
                          $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_PROBE] 32b_mode SUCCESS match TLB_ARRAY[%0d]: TEH.PN='h%0X TLB_ARRAY.PN='h%0X", $time, i, mmu_registers.mmu_teh.pn.get(),tlb_array[i].pn)); 
                          `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_PROBE] k1_32_mode SUCCESS match TLB_ARRAY[%0d]: TEH.PN='h%0X TLB_ARRAY.PN='h%0X", $time,i, mmu_registers.mmu_teh.pn.get(),tlb_array[i].pn), UVM_HIGH)
                          tlb_found = 1;
                          break;
                      end                        
                  end
                  
                  else begin//in the k1_64_mode

                      if(mmu_registers.mmu_teh.pn.get() == tlb_array[i].pn && mmu_registers.mmu_teh.asn.get() == tlb_array[i].asn && (tlb_array[i].es !=0))begin 
                          mmu_registers.mmu_mmc.idx.set(tlb_array[i].idx);
                          $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_PROBE] 32b_mode SUCCESS match TLB_ARRAY[%0d]: TEH.PN='h%0X TLB_ARRAY.PN='h%0X TEH.ASN='h%0X TLB_ARRAY.ASN='h%0X", $time, i, mmu_registers.mmu_teh.pn.get(),tlb_array[i].pn,mmu_registers.mmu_teh.asn.get(),tlb_array[i].asn)); 
                          `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_PROBE] k1_32_mode SUCCESS match TLB_ARRAY[%0d]: TEH.PN='h%0X TLB_ARRAY.PN='h%0X TEH.ASN='h%0X TLB_ARRAY.ASN='h%0X", $time, i, mmu_registers.mmu_teh.pn.get(),tlb_array[i].pn,mmu_registers.mmu_teh.asn.get(),tlb_array[i].asn), UVM_HIGH)
                          tlb_found = 1;
                          break;
                      end                                                       
                  end                                                                                            
              end 
              if(tlb_found == 0)begin              
                  $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_PROBE] DO NOT SUCCESS match in the TLB and MMC_E is 1", $time)); 
                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]:  [TLB_PROBE] DO NOT SUCCESS match in the TLB and MMC_E is %0d ", $time,mmu_proc_tlbmaintenance_intf.mmc_e), UVM_HIGH)
              end
              
 /*----------------------------------  Checker of the MMC_E  ---------------------------*/ 
              repeat(3)begin 
                  @(posedge mmu_proc_tlbmaintenance_intf.clock) ;
              end          
              if(tlb_found == 1)begin
                  if(mmu_registers.mmu_mmc.idx.get() !=  tlb_array[i].idx || mmu_proc_tlbmaintenance_intf.mmc_e != 0)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The two values : mmc of the DUT and the REF must be same when the TLB found after the TLB PROBE Instrucion and the mmc_e must be 0", $time,i))
                  end
              end
              else begin
                  if(mmu_proc_tlbmaintenance_intf.mmc_e != 1)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The mmc_e must be set when the TLB is not found after the TLB PROBE Instrucion ", $time,i))
                  end    
              end          
          end
            
/************************ Inferface tlbindexl ***************************/
              
          if(mmu_proc_tlbmaintenance_intf.tlbindexl_i_m == 1)begin
            int ltlb, ltlb_found = 0;
              $display("GG:PAss index ltlb");
              for(ltlb=256;ltlb<$size(tlb_array);ltlb++)begin                                          
                  if(tlb_array[ltlb].es == 0 || tlb_array[ltlb].page_size == 0 )begin
                      mmu_registers.mmu_mmc.idx.set(ltlb);
                      ltlb_found=1;     
                      
                      $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_INDEXL] FOUND Invalid LTLB:  Update the mmc_idx with the invalid idx of TLB_ARRAY[%0d]", $time,ltlb));
                      `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_INDEXL] FOUND Invalid LTLB: Update the mmc_idx with the invalid idx of TLB_ARRAY[%0d]", $time,ltlb), UVM_HIGH) 
                      break;
                  end                              
              end 
              
              if(ltlb_found==0)begin
                  // mmu_registers.mmu_mmc.e.set(1);                  
                  $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_INDEXL] NO FOUND Invalid LTLB", $time));
                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_INDEXL] NO FOUND Invalid LTLB", $time), UVM_HIGH) 
              end                           
              
/*-------------------------- Check of the mmc_e-------------------------------*/
              repeat(3)begin 
                  @(posedge mmu_proc_tlbmaintenance_intf.clock) ;
              end          
              if(ltlb_found == 1)begin
                  $display("idx:%0d idx2:%0d E:%0d",mmu_registers.mmu_mmc.idx.get(), ltlb, mmu_proc_tlbmaintenance_intf.mmc_e);
                  if(mmu_registers.mmu_mmc.idx.get() !=  ltlb || mmu_proc_tlbmaintenance_intf.mmc_e != 0)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The two values : mmc of the DUT and the REF must be same when the LTLB found after the TLB INDEX LTLB Instrucion and the mmc_e must be 0", $time,ltlb))
                  end                  
              end
              else begin
                  if(mmu_proc_tlbmaintenance_intf.mmc_e != 1)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The mmc_e must be set when the LTLB is not found after the TLB INDEX LTLB Instrucion ", $time,ltlb))
                  end
              end
          end 

              
/********************************* Interface tlbindexj *********************************/
          if(mmu_proc_tlbmaintenance_intf.tlbindexj_i_m == 1)begin             
            int jtlb, jtlb_found = 0;
              for(jtlb=0;jtlb<128;jtlb++)begin
                  
                  if(mmucfg_intf.k1_64_mode_m == 0 && mmu_registers.mmu_teh.g.get() != 0 )begin //in the k1_32_mode
                      
                      if(mmu_registers.mmu_teh.pn.get() == tlb_array[jtlb].pn)begin 
                          if(jtlb[0] == 0)begin
                              if(tlb_array[jtlb].es == 0 && tlb_array[jtlb+1].es != 0)begin
                                  mmu_registers.mmu_mmc.idx.set(jtlb);
                                  
                              end
                              else if(tlb_array[jtlb].es != 0 && tlb_array[jtlb+1].es == 0)begin
                                  
                                  mmu_registers.mmu_mmc.idx.set(jtlb+1);
                              end
                              else if(tlb_array[jtlb].es != 0 && tlb_array[jtlb+1].es != 0 &&  tlb_array[jtlb].lrw_index_mode == 0)begin
                                  
                                  mmu_registers.mmu_mmc.idx.set(jtlb);
                                  break;
                                  
                              end
                              else if (tlb_array[jtlb].es == 0 && tlb_array[jtlb+1].es == 0) begin
                                  mmu_registers.mmu_mmc.idx.set(jtlb);
                     
                              end
                              else begin  
                                  break;
                              end
                              
                          end
                          else begin
                              if(tlb_array[jtlb-1].es == 0 && tlb_array[jtlb].es != 0)begin
                                  
                                  mmu_registers.mmu_mmc.idx.set(jtlb-1);
                                  
                              end
                              else if(tlb_array[jtlb-1].es != 0 && tlb_array[jtlb].es == 0)begin
                                  mmu_registers.mmu_mmc.idx.set(jtlb);
                              end
                              else if(tlb_array[jtlb].es != 0 && tlb_array[jtlb-1].es != 0 &&  tlb_array[jtlb].lrw_index_mode == 0)begin
                                  mmu_registers.mmu_mmc.idx.set(jtlb -1); 
                                  break;
                                  
                              end
                              else if(tlb_array[jtlb-1].es == 0 && tlb_array[jtlb].es == 0) begin
                                  mmu_registers.mmu_mmc.idx.set(jtlb-1);                                  
                              end
                              else begin
                                  break;
                              end
                          end 
                          
                          $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_PROBE] 32b_mode SUCCESS match TLB_ARRAY[%0d]: TEH.PN='h%0X TLB_ARRAY.PN='h%0X", $time, jtlb, mmu_registers.mmu_teh.pn.get(),tlb_array[jtlb].pn)); 
                          `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_PROBE] k1_32_mode SUCCESS match TLB_ARRAY[%0d]: TEH.PN='h%0X TLB_ARRAY.PN='h%0X", $time,jtlb, mmu_registers.mmu_teh.pn.get(),tlb_array[jtlb].pn), UVM_HIGH)
                          jtlb_found = 1;
                          break;
                      end                        
                  end
                  
                  else begin//in the k1_64_mode or k1 32 mode with global 0
                      if(mmu_registers.mmu_teh.pn.get() == tlb_array[jtlb].pn && mmu_registers.mmu_teh.asn.get() == tlb_array[jtlb].asn && (tlb_array[jtlb].es !=0))begin 
                          mmu_registers.mmu_mmc.idx.set(tlb_array[jtlb].idx);
                          $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_INDEX_JTLB]  SUCCESS match TLB_ARRAY[%0d]: TEH.PN='h%0X TLB_ARRAY.PN='h%0X TEH.ASN='h%0X TLB_ARRAY.ASN='h%0X", $time, jtlb, mmu_registers.mmu_teh.pn.get(),tlb_array[jtlb].pn,mmu_registers.mmu_teh.asn.get(),tlb_array[jtlb].asn)); 
                          `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_INDEX_JTLB]  SUCCESS match TLB_ARRAY[%0d]: TEH.PN='h%0X TLB_ARRAY.PN='h%0X TEH.ASN='h%0X TLB_ARRAY.ASN='h%0X", $time, jtlb, mmu_registers.mmu_teh.pn.get(),tlb_array[jtlb].pn,mmu_registers.mmu_teh.asn.get(),tlb_array[jtlb].asn), UVM_HIGH)
                          jtlb_found = 1;
                          break;
                      end                                                       
                  end                                                                                            
              end 
              if(jtlb_found == 0)begin              
                  $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [TLB_INDEX_JTLB] DO NOT SUCCESS match in the TLB and MMC_E is 1", $time)); 
                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]:  [TLB_INDEX_JTLB] DO NOT SUCCESS match in the TLB and MMC_E is %0d ", $time,mmu_proc_tlbmaintenance_intf.mmc_e), UVM_HIGH)
              end
              
 /*----------------------------------  Checker of the MMC_E  ---------------------------*/ 
              repeat(3)begin 
                  @(posedge mmu_proc_tlbmaintenance_intf.clock) ;
              end          
              if(jtlb_found == 1)begin
                  if(mmu_registers.mmu_mmc.idx.get() !=  mmu_proc_tlbmaintenance_intf.mmc_idx || mmu_proc_tlbmaintenance_intf.mmc_e != 0)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The two values : mmc of the DUT and the REF must be same when the TLB found after the TLB Index JTLB Instrucion and the mmc_e must be 0", $time,jtlb))
                  end
              end
              else begin
                  if(mmu_proc_tlbmaintenance_intf.mmc_e != 1)begin
                      `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU REFMODEL]: TLB[%0d] The mmc_e must be set when the TLB is not found after the TLB Index JTLB Instrucion ", $time,jtlb))
                  end    
              end        
      
          end
          
      end // forever begin
    
   
endtask : instruction_maintenance_management


task tb_mmu_refmodel :: store_dcache_reponse(int resp_flag);
   
    mmu_dcache_reponse reponse;
    int found = 0;
    int trap_count = 0;
    int fn_temp;
    int pre_idx_found = 0;
    int aligned_mode_flag;
    int trap_protection_flag;
    int trap_nomapping_flag;
    int different_cp_flag;
  
    reponse = new;
    
    reponse.e2_dcache_phys_addr_m       =  mmu_dcache_intf.e2_dcache_phys_addr_m;
    reponse.e2_dcache_cluster_per_acc_m =  mmu_dcache_intf.e2_dcache_cluster_per_acc_m;   
    reponse.e2_dcache_policy_m          =  mmu_dcache_intf.e2_dcache_policy_m;
    reponse.dcache_second_acc_d_i       =  mmu_dcache_intf.dcache_second_acc_d_i_s;
    
    reponse.e2_non_trapping_id_cancel_o =  mmu_dcache_intf.e2_non_trapping_id_cancel_o;
  //  trap_count +=  mmu_dcache_intf.e2_non_trapping_id_cancel_o;
    reponse.e2_trap_nomapping_o         =  mmu_dcache_intf.e2_trap_nomapping_o;
    
    if( reponse.e2_trap_nomapping_o  == 1)  trap_count +=  mmu_dcache_intf.e2_trap_nomapping_o;
    
    reponse.e2_trap_protection_o        =  mmu_dcache_intf.e2_trap_protection_o;
    trap_count +=  mmu_dcache_intf.e2_trap_protection_o;
    reponse.e2_trap_writetoclean_o      =  mmu_dcache_intf.e2_trap_writetoclean_o;
    trap_count +=  mmu_dcache_intf.e2_trap_writetoclean_o;
    reponse.e2_trap_atomictoclean_o     =  mmu_dcache_intf.e2_trap_atomictoclean_o;
    trap_count +=  mmu_dcache_intf.e2_trap_atomictoclean_o;
    reponse.e2_trap_dmisalign_o         =  mmu_dcache_intf.e2_trap_dmisalign_o;
    trap_count +=  mmu_dcache_intf.e2_trap_dmisalign_o;
    reponse.e2_trap_dsyserror_o         =  mmu_dcache_intf.e2_trap_dsyserror_o;
//    trap_count +=  mmu_dcache_intf.e2_trap_dsyserror_o;// Not consider for now
    

    if(( reponse.e2_trap_protection_o != 0) || ( reponse.e2_trap_nomapping_o != 0) || (  reponse.e2_trap_writetoclean_o != 0) || ( reponse.e2_trap_atomictoclean_o != 0) || ( reponse.e2_trap_dmisalign_o != 0) || ( reponse.e2_trap_dsyserror_o != 0))begin              
        trap_flag  = 1;
    end

   
    
    for(int i=0;i<264;i++)begin
      logic [19:0] pn_temp;
      logic [19:0] virt_page_temp;
        
        pn_temp = tlb_array[i].pn;
        virt_page_temp =  dcache_request_queue[0].virt_page;
        pn_temp = pn_temp >> tlb_array[i].no_usefull_bit;
        pn_temp = pn_temp << tlb_array[i].no_usefull_bit;
        virt_page_temp = virt_page_temp >> tlb_array[i].no_usefull_bit;
        virt_page_temp = virt_page_temp << tlb_array[i].no_usefull_bit;
        //$display("GG:pn_temp:%0X virt_page_temp:%0X pn_temp:%0X virt_page_temp:%0X index:%0d TLB_ASN:%0X MMC_ASN:%0X",pn_temp,virt_page_temp,pn_temp, virt_page_temp,i,tlb_array[i].asn, mmu_registers.mmu_mmc.asn.get());
        if( (pn_temp == virt_page_temp)/* && (tlb_array[i].es != 0) */&& (tlb_array[i].g == 1 || ((tlb_array[i].asn == /*tlb_array[i].asn_mmc*/ mmu_registers.mmu_mmc.asn.get()))) )begin
            
            reponse.fn = tlb_array[i].fn;
            reponse.pn = tlb_array[i].pn;
            reponse.cp = tlb_array[i].cp;
            reponse.es = tlb_array[i].es;
            reponse.pa = tlb_array[i].pa;
            reponse.g  = tlb_array[i].g;
            reponse.asn= tlb_array[i].asn;
        
            reponse.idx = i;

            reponse.no_usefull_bit = tlb_array[i].no_usefull_bit;
            reponse.page_size = tlb_array[i].page_size; 
            reponse.first_line_addr_of_page = tlb_array[i].first_line_addr_of_page;
            reponse.last_line_addr_of_page = tlb_array[i].last_line_addr_of_page;

           
            found = 1;
            
            `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE]: TLB match found in TLB[%0d]: %s", $time, i, tlb_array[i].print), UVM_FULL)
            
/******************************  Coverage Configuration *************************/
            
            tb_mmu_coverage_inst.index_cov = i;
            tb_mmu_coverage_inst.s_cov   = tlb_array[i].s;
            tb_mmu_coverage_inst.g_cov   = tlb_array[i].g;
            tb_mmu_coverage_inst.asn_cov = tlb_array[i].asn;
            
           // tb_mmu_coverage_inst.page_size_tlb_cov = tlb_array[i].page_size;

            tb_mmu_coverage_inst.dps_cov =mmu_registers.mmu_mmc.dps.get();
            tb_mmu_coverage_inst.lps_cov = mmu_registers.mmu_mmc.lps.get();

            
            tb_mmu_coverage_inst.ae_cov = tlb_array[i].ae;
            tb_mmu_coverage_inst.pa_cov = tlb_array[i].pa;
            tb_mmu_coverage_inst.cp_cov = tlb_array[i].cp;
            tb_mmu_coverage_inst.es_cov = tlb_array[i].es;
            
            tb_mmu_coverage_inst.pn_cov = tlb_array[i].pn;
            tb_mmu_coverage_inst.fn_cov = tlb_array[i].fn;

         
            if((dcache_request_queue[0].e1_dcache_virt_addr_i - tlb_array[i].first_line_addr_of_page) <= 64)begin
                tb_mmu_coverage_inst.page_position_cov = 1;
            end
            else if((tlb_array[i].last_line_addr_of_page - dcache_request_queue[0].e1_dcache_virt_addr_i) <= 64)begin
                tb_mmu_coverage_inst.page_position_cov = 3;
            end
            else begin
                tb_mmu_coverage_inst.page_position_cov = 2;
            end
                                                                     
            break;
        end                  
    end // for (int i=0;i<264;i++)
    
    // Search the continueus page
    for(int i=0;i<264;i++)begin
        if(tlb_array[i].check_mmc_error_mode == 0)begin
            if((tlb_array[i].first_line_addr_of_page)== ( reponse.last_line_addr_of_page + 1) && (tlb_array[i].g == 1 || (tlb_array[i].asn == mmu_registers.mmu_mmc.asn.get())))begin
              //  if(reponse.last_line_addr_of_page + 1 !=0)begin // Avoid the next page of 'hFFFFFFFF is 0
                    reponse.pre_idx = i; 
                    pre_idx_found = 1;
                    break;        
              //  end
            end
        end
    end
    // Ensure the different_cp_flag with the two continueus page if the virt adress pass page.
    if((dcache_request_queue[0].e1_dcache_virt_addr_i + dcache_request_queue[0].e1_dcache_size_i - 1) > reponse.last_line_addr_of_page) begin
        if(pre_idx_found == 1)begin
            if(tlb_array[reponse.pre_idx].cp != reponse.cp)begin                     
                different_cp_flag = 1;
            end
            else begin              
                different_cp_flag = 0;
            end
        end
    end

    
    if(found == 1)begin
        if( reponse.es == 0)begin
            tb_mmu_coverage_inst.page_size_tlb_cov = 0;
            if(pre_idx_found == 1)begin
                tb_mmu_coverage_inst.next_page_size_tlb_cov = tlb_array[reponse.pre_idx].page_size;
            end
            else begin
                tb_mmu_coverage_inst.next_page_size_tlb_cov = 0;
            end
        end
        else begin
            tb_mmu_coverage_inst.page_size_tlb_cov = tlb_array[reponse.idx].page_size;
            if(pre_idx_found == 1)begin
                tb_mmu_coverage_inst.next_page_size_tlb_cov = tlb_array[reponse.pre_idx].page_size;
            end
            else begin
                tb_mmu_coverage_inst.next_page_size_tlb_cov = 0;
            end
        end
    end

    tb_mmu_coverage_inst.UsedTLB_cov.sample();
    tb_mmu_coverage_inst.PageSize_cov.sample();
    tb_mmu_coverage_inst.DpsLps_cov.sample();           
    tb_mmu_coverage_inst.UsedTLBPnFn_cov.sample();
    tb_mmu_coverage_inst.PageContinu_cov.sample();


     $display("GG:TLBMatch[%0d] priviledge_mode_m:%0d pa:%0d e1_dcache_opc:%s trap_protection_flag:%0d trap_nomapping_flag:%0d pre_idx_found:%0d reponse.pre_idx:%0d sne:%0d",reponse.idx, mmucfg_intf.priviledge_mode_m, reponse.pa,dcache_request_queue[0].e1_dcache_opc, trap_protection_flag, trap_nomapping_flag, pre_idx_found, reponse.pre_idx,  reponse.sne);

/******************* Check the multi mapping for the same PN ****************************************/    
 
    for(int i=0;i<264;i++)begin
      int four_k = 2**12;
      logic [19:0] pn_temp_i;
      logic [19:0] pn_temp_j;
        pn_temp_i = tlb_array[i].pn;
        pn_temp_i = (( pn_temp_i >> tlb_array[i].no_usefull_bit) << tlb_array[i].no_usefull_bit);
        for(int j=0;j<264;j++)begin
            if(!(tlb_array[i].check_mmc_error_mode == 1 || tlb_array[j].check_mmc_error_mode == 1))begin // Not check when the check_mmc_error_mode is 1
                if(( tlb_array[i].page_size !=0) && (tlb_array[j].page_size !=0) && (i != j) ) begin
                    
                    pn_temp_j = tlb_array[j].pn;
                    pn_temp_j = (( pn_temp_j >> tlb_array[j].no_usefull_bit) << tlb_array[j].no_usefull_bit);
                    

                    if(((pn_temp_i > pn_temp_j ) && ((pn_temp_i + tlb_array[i].page_size/four_k - 1) < (pn_temp_j + tlb_array[j].page_size/four_k - 1)))
                       || (((pn_temp_i + tlb_array[i].page_size/four_k - 1 ) > pn_temp_j ) && ((pn_temp_i + tlb_array[i].page_size/four_k - 1 ) < (pn_temp_j + tlb_array[j].page_size/four_k - 1))) 
                       || ((pn_temp_i > pn_temp_j ) && ( pn_temp_i < (pn_temp_j + tlb_array[j].page_size/four_k - 1)))
                       || (pn_temp_i == pn_temp_j)
                       || (pn_temp_i == (pn_temp_j + tlb_array[j].page_size/four_k - 1))   
                       || ((pn_temp_i + tlb_array[i].page_size/four_k - 1)==  pn_temp_j)     
                       || ((pn_temp_i + tlb_array[i].page_size/four_k - 1)==  pn_temp_j + ( tlb_array[j].page_size/four_k - 1)) )begin          
                        
                        if (tlb_array[i].multi_mapping_en == 0 && tlb_array[j].multi_mapping_en)begin
                            `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: TLB[%0d] Size:%0d who has PN:%0X and End PN: %0X can not use the same PN of the TLB[%0d] who has the start PN:%0X,the end PN:%0X and the size page:%0d ", 
                                                                  $time, i,tlb_array[i].page_size , pn_temp_i, pn_temp_i + tlb_array[i].page_size/2**12 - 1 ,j, 
                                                                  pn_temp_j , 
                                                                  (pn_temp_j + tlb_array[j].page_size/four_k - 1),
                                                                  tlb_array[j].page_size));                
                        end
                    end
                end
            end 
        end
    end 
     
         if(tlb_array[reponse.idx].check_mmc_error_mode == 0 || mmucfg_intf.processor_in_debug_m == 0 )begin            
       
   
       trap_nomapping_management(dcache_request_queue[0].e1_dcache_virt_addr_i, dcache_request_queue[0].e1_dcache_size_i, reponse.last_line_addr_of_page, reponse.es, found, mmu_registers.mmu_mmc.sne.get(),dcache_request_queue[0].e1_non_trapping_i, pre_idx_found, reponse.pre_idx, reponse.e2_trap_nomapping_o, reponse.dcache_second_acc_d_i, dcache_request_queue[0].e1_dcache_opc, trap_nomapping_flag);
       trap_protection_management(dcache_request_queue[0].e1_dcache_virt_addr_i, dcache_request_queue[0].e1_dcache_size_i, reponse.last_line_addr_of_page,  reponse.dcache_second_acc_d_i, found, pre_idx_found, reponse.pre_idx, reponse.es, mmucfg_intf.priviledge_mode_m, reponse.pa, different_cp_flag, dcache_request_queue[0].e1_dcache_opc,  reponse.e2_trap_protection_o,  reponse.e2_trap_nomapping_o,trap_nomapping_flag, dcache_request_queue[0].e1_non_trapping_i, mmu_registers.mmu_mmc.spe.get(),  reponse.idx, trap_protection_flag);
       
/**************** Check a trap occur *******************************/
    
    if (traps_disabled == 1 && trap_count !== 0)
      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: A trap occurs but test should prevented it!"));
   // $display("GZ:NOMAP found:%0d,trap nomapping:%0d,opcode:%s  ",found,reponse.e2_trap_nomapping_o,dcache_request_queue[0].e1_dcache_opc );

  

/******************** Check The Trap No Mapping ***************************/
    
    if((dcache_request_queue[0].e1_dcache_opc != WPURGE) && (dcache_request_queue[0].e1_dcache_opc != DINVAL) && (reponse.dcache_second_acc_d_i == 0))begin
        
        if(reponse.e2_trap_nomapping_o == 0)begin
            
            if(!(found == 1 && reponse.es != 0))begin
                if(dcache_request_queue[0].e1_non_trapping_i == 1)begin
                    if(reponse.sne !== 0)begin
                        `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface no mapping MUST be set when found is 1 and e1_no_trapping is 0"));  
                    end
                end
                else begin                 
                    `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface no mapping MUST be set when found is 1 and e1_no_trapping is 0"));  
                end
            end       
        end
        else if( reponse.e2_trap_nomapping_o == 1)begin
            
            if(!(found == 0 || reponse.es == 0))           
              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface no mapping can not be set when found is 1"));          
        end
        else if(reponse.e2_trap_nomapping_o == 2)begin
            
            if(!((found == 1 && reponse.es != 0) && (pre_idx_found == 0 || tlb_array[reponse.pre_idx].es == 0)))begin
                `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface no mapping can not be set when found is 1 pre_idx_found is not 0"));
            end
        end
        else begin // Trap nomapping is 3  
            
            if (!(((found == 0 || reponse.es == 0) && (pre_idx_found == 0 || tlb_array[reponse.pre_idx].es == 0))))begin

                if( ((dcache_request_queue[0].e1_dcache_virt_addr_i + dcache_request_queue[0].e1_dcache_size_i)>>12) < tlb_array[reponse.pre_idx].first_line_addr_of_page)begin
                    
                    if(!((dcache_request_queue[0].e1_dcache_virt_addr_i<<20 + dcache_request_queue[0].e1_dcache_size_i) >= 'h1000))begin
                        `uvm_fatal(get_type_name(), $psprintf(("[%0d] [MMU_REFMODEL]: [DCACHE_REPONSE]: The ES of the precedent tlb[%0d] must 0 when the no mapping trap is 3"),$time,reponse.pre_idx))
                    end
                end
                else begin
                    `uvm_fatal(get_type_name(), $psprintf(("[%0d] [MMU_REFMODEL]: [DCACHE_REPONSE]: The ES of the precedent tlb[%0d] must 0 when the no mapping trap is 3"),$time,reponse.pre_idx))
                end                
            end
        end

        

/********************* Check the interface e2_non_trapping_id_cancel_o with the Trap Nomapping, Trap Protection, SPE, SNE ***********************/
     //Bug !!  the e2_non_trapping_id_cancel_o is 1 when the SPE and SNE is 1 so it is impossible
    // Need to implant the checker of e2_non_trapping_id_cancel_o with the trap protection
    /*   if(dcache_request_queue[0].e1_non_trapping_i == 1)begin            
            if(found == 0)begin
                if(reponse.e2_trap_nomapping_o == 0)
                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_trap_nomapping_o MUST be set when found is 0"));
                if(reponse.e2_non_trapping_id_cancel_o == 1)
                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o can NOT be set when found is 0"));
            end
            else begin                   
                if(reponse.es == 0)begin
                    if(mmu_registers.mmu_mmc.sne.get() == 0)begin
                        if(reponse.e2_trap_nomapping_o != 0)
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_trap_nomapping_o MUST be 0 when found is 1, SNE is 0 and ES is 0"));                           
                        if(reponse.e2_non_trapping_id_cancel_o != 1)
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o MUST be set when e1_non_trapping_i is 1, SNE is 0, found is 1 and ES is 0"));
                    end
                    else begin //SNE is 1
                        if(reponse.e2_trap_nomapping_o == 0)
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_trap_nomapping_o MUST be set when found is 1, SNE is 1 and ES is 0"));
                        if(reponse.e2_trap_nomapping_o == 0)begin
                            if(trap_protection_flag == 0)begin
                                if(reponse.e2_non_trapping_id_cancel_o == 1)
                                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o can NOT be set when e1_non_trapping_i is 1, SNE is 1, found is 1, ES is 1 and trap protection is 0"));
                            end
                            else begin
                                if(mmu_registers.mmu_mmc.spe.get() == 0)begin
                                    if(reponse.e2_non_trapping_id_cancel_o != 1)
                                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o MUST be set when e1_non_trapping_i is 1, SNE is 1, found is 1, ES is 1 and SPE is 1 "));
                                end
                                else begin
                                    if(reponse.e2_non_trapping_id_cancel_o != 0)
                                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o can NOT be set when e1_non_trapping_i is 1, SNE is 1, found is 1, ES is 1 and SPE is 1"));
                                end
                            end 
                        end
                    end
                end
                else begin //ES is 1
                    
                    if(mmu_registers.mmu_mmc.sne.get() == 0) begin
                        if(reponse.e2_trap_nomapping_o != 0)// It also includes the trap nomapping is 2 and 3 
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_trap_nomapping_o MUST be 0 when found is 1, SNE is 0 and ES is 1"));
                        if(trap_nomapping_flag == 1)begin
                            if(reponse.e2_non_trapping_id_cancel_o != 1)
                              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o MUST be set when e1_non_trapping_i is 1, SNE is 0, found is 1, ES is 1 and trap nomapping is 2 or 3"));
                        end
                        else begin
                            if(reponse.e2_trap_nomapping_o == 0)begin
                                if(trap_protection_flag == 0)begin                               
                                    if(reponse.e2_non_trapping_id_cancel_o != 0)begin                                
                                        `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o can NOT be set when e1_non_trapping_i is 1, SNE is 0, found is 1 and ES is 1"));
                                    end
                                end
                                else begin
                                    if(mmu_registers.mmu_mmc.spe.get() == 0)begin
                                        if(reponse.e2_non_trapping_id_cancel_o != 1)
                                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o MUST be set when e1_non_trapping_i is 1, SNE is 0, found is 1 and ES is 1, SPE is 0 "));
                                    end
                                    else begin
                                        if(reponse.e2_non_trapping_id_cancel_o != 0)
                                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o can NOT be set when e1_non_trapping_i is 1, SNE is 0, found is 1, ES is 1 and SPE is 1 "));
                                    end
                                end 
                            end
                        end
                    end                                                
                    else begin //SNE is 1
                        if(reponse.e2_trap_nomapping_o != 0)begin
                            if(reponse.e2_trap_nomapping_o == 1)begin
                                `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_trap_nomapping_o can NOT be 0 when found is 1, SNE is 0 and ES is 1"));               
                            end                          
                            else begin
                                //If the trap nomapping is 2 or 3,it is correct
                                
                            end                                
                            if(reponse.e2_trap_nomapping_o == 0)begin
                                if(trap_protection_flag == 0)begin
                                    if(reponse.e2_non_trapping_id_cancel_o == 1)
                                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o can NOT be set when e1_non_trapping_i is 1, SNE is 1, found is 1, ES is 1 and trap protection is 0"));
                                end
                                else begin
                                    if(mmu_registers.mmu_mmc.spe.get() == 0)begin
                                        if(reponse.e2_non_trapping_id_cancel_o != 1)
                                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o MUST be set when e1_non_trapping_i is 1, SNE is 0, found is 1, ES is 1 and SPE is 0 !"));
                                    end
                                    else begin
                                        if(reponse.e2_non_trapping_id_cancel_o != 0)
                                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o can NOT be set when e1_non_trapping_i is 1, SNE is 0, found is 1, ES is 1 and SPE is 1 !"));
                                    end
                                end
                            end
                        end                   
                    end                         
                end                  
            end                       
        end               
        else begin
            if(reponse.e2_non_trapping_id_cancel_o == 1) 
              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! The interface e2_non_trapping_id_cancel_o can NOT be set when e1_non_trapping_i is 0"));           
        end
     
*/
      
    end // if ((dcache_request_queue[0].e1_dcache_opc != WPURGE) && (dcache_request_queue[0].e1_dcache_opc != DINVAL) && (reponse.dcache_second_acc_d_i == 0))
 
/*************** Check No found TLB , SNE, the interface e1_non_trapping_i with the interface trap nomapping ********************************/
    
    if((dcache_request_queue[0].e1_dcache_opc != WPURGE) && (dcache_request_queue[0].e1_dcache_opc != DINVAL) && (reponse.dcache_second_acc_d_i == 0))begin
        if(found==0)begin
            if (reponse.e2_trap_nomapping_o != 1)begin
                if(reponse.e2_trap_nomapping_o == 3)begin
                    if((tlb_array[reponse.pre_idx].es !=0) && (pre_idx_found == 1))begin
                        `uvm_fatal(get_type_name(), $psprintf(("[%0d] [MMU_REFMODEL]: [DCACHE_REPONSE]: The ES of the precedent tlb[%0d] must 0 when the no mapping trap is 3"),$time,reponse.pre_idx))
                    end 
                    else begin
                        `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE]: Not found TLB[%0d] trap no mapping:%0d ", $time, reponse.idx, reponse.e2_trap_nomapping_o), UVM_FULL)
                    end 
                end  
                else if(reponse.e2_trap_nomapping_o == 2)begin
                     `uvm_fatal(get_type_name(), $psprintf(("[%0d] [MMU_REFMODEL]: [DCACHE_REPONSE]: The no mapping trap is 2 !!"),$time))                    
                end                           
                else begin  
                    // Trap Nomapping is 0            
                    if(dcache_request_queue[0].e1_non_trapping_i == 1)begin
                        if(mmu_registers.mmu_mmc.sne.get() == 1)begin
                            `uvm_fatal(get_type_name(), $psprintf(("[%0d] [MMU_REFMODEL]: [DCACHE_REPONSE]: The no mapping trap must be 0 when the flag found is 1 , SNE is set and the interface Non Trapping is 1 - found:%0d, trap no mapping: %0d,opcode: %s "),$time,found,reponse.e2_trap_nomapping_o,dcache_request_queue[0].e1_dcache_opc ))
                        end
                        else begin                            
                            `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE]: It is normal that the no mapping is 0 when the found is 0 and SNE is 0 with the interface e1_no_trapping is 1 ", $time), UVM_FULL)
                            if(reponse.e2_non_trapping_id_cancel_o == 1)begin
                                `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE]: It is normal that the interface no mapping is 0 and the interface e2_non_trapping_id_cancel_o is 1 when the found is 0 and SNE is 0 with the interface e1_no_trapping is 1 ", $time), UVM_FULL)
                            end
                            else begin
                                `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE]: The interface no mapping is 0 and the interface e2_non_trapping_id_cancel_o MUST be 1 when the found is 0 and SNE is 0 with the interface e1_no_trapping is 1 ", $time))
                            end
                        end                       
                    end
                    else begin
                        `uvm_fatal(get_type_name(), $psprintf(("[%0d] [MMU_REFMODEL]: [DCACHE_REPONSE]: The no mapping trap must be 0 when the flag found is 1 - found:%0d,trap no mapping: %0d,opcode: %s "),$time,found,reponse.e2_trap_nomapping_o,dcache_request_queue[0].e1_dcache_opc ))
                    end
                end 
            end 
            else begin
                `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE]: Not found TLB[%0d] trap no mapping:%0d ", $time, reponse.idx, reponse.e2_trap_nomapping_o), UVM_FULL)              
            end
        end
        else begin
            //found = 1
            if(reponse.es != 0)begin             
                if(reponse.e2_trap_nomapping_o == 1)
                  `uvm_fatal(get_type_name(), $psprintf(("[%0d] [MMU_REFMODEL]: [DCACHE_REPONSE]: The no mapping trap must be 0 when the flag found is 1 - found:%0d,trap no mapping: %0d,opcode: %s "),$time,found,reponse.e2_trap_nomapping_o,dcache_request_queue[0].e1_dcache_opc ))
            end
        end
    end

        
/*********************  Check the implementation of Trap Nomapping  ************************/
    
    if((reponse.es != 0) && (found == 0) && (reponse.e2_trap_nomapping_o !== 1) && (dcache_request_queue[0].e1_dcache_opc != WPURGE) && (dcache_request_queue[0].e1_dcache_opc != DINVAL))
      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: No match in TLB => NoMapping trap management is not implemented"));
    
/*******************************************************************/
   
    if((found == 1) && (reponse.es != 0))begin
     
        dcache_request_queue[0].resp = {dcache_request_queue[0].resp, reponse};
        
        if(resp_flag == 0)begin
            
            $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE] TLB ARRAY[%0d] Page Size: %0d No Usefull Bit: %0d Virtual Address: 'h%0X, Virtual Page: 'h%0X, PN: h'%0X FN: 'h%0X, Physique Address: 'h%0X, Size of address: %0d,Second access: %0d,Cluster: %0d, Policy: %0d, E1-Non-Trapping-EN: %0d, E2-Non-trapping-ID-cancel: %0d, Trap nomapping: %0d,  Trap protection: %0d, Trap writetoclean: %0d, Trap atomictoclean: %0d, Trap dmisalign: %0d,Trap dsyserror: %0d", $time, dcache_request_queue[0].resp[resp_flag].idx, dcache_request_queue[0].resp[resp_flag].page_size, dcache_request_queue[0].resp[resp_flag].no_usefull_bit,dcache_request_queue[0].e1_dcache_virt_addr_i, dcache_request_queue[0].virt_page,dcache_request_queue[0].resp[resp_flag].pn, dcache_request_queue[0].resp[resp_flag].fn, dcache_request_queue[0].resp[resp_flag].e2_dcache_phys_addr_m, dcache_request_queue[0].e1_dcache_size_i, dcache_request_queue[0].resp[resp_flag].dcache_second_acc_d_i, dcache_request_queue[0].resp[resp_flag].e2_dcache_cluster_per_acc_m, dcache_request_queue[0].resp[resp_flag].e2_dcache_policy_m,  dcache_request_queue[0].e1_non_trapping_i, dcache_request_queue[0].resp[resp_flag].e2_non_trapping_id_cancel_o, dcache_request_queue[0].resp[resp_flag].e2_trap_nomapping_o, dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o,dcache_request_queue[0].resp[resp_flag].e2_trap_writetoclean_o, dcache_request_queue[0].resp[resp_flag].e2_trap_atomictoclean_o, dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o, dcache_request_queue[0].resp[resp_flag].e2_trap_dsyserror_o));

            `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE] TLB ARRAY[%0d] Page Size: %0d No Usefull Bit: %0d Virtual Address: 'h%0X, Virtual Page: 'h%0X, FN: 'h%0X, Physique Address: 'h%0X, Size of address: %0d,Second access: %0d,Cluster: %0d, Policy: %0d, E1-Non-Trapping-EN: %0d, E2-Non-trapping-ID-cancel: %0d, Trap nomapping: %0d,  Trap protection: %0d, Trap writetoclean: %0d, Trap atomictoclean: %0d, Trap dmisalign: %0d,Trap dsyserror: %0d", $time, dcache_request_queue[0].resp[resp_flag].idx, dcache_request_queue[0].resp[resp_flag].page_size, dcache_request_queue[0].resp[resp_flag].no_usefull_bit,dcache_request_queue[0].e1_dcache_virt_addr_i, dcache_request_queue[0].virt_page,dcache_request_queue[0].resp[resp_flag].fn, dcache_request_queue[0].resp[resp_flag].e2_dcache_phys_addr_m, dcache_request_queue[0].e1_dcache_size_i, dcache_request_queue[0].resp[resp_flag].dcache_second_acc_d_i, dcache_request_queue[0].resp[resp_flag].e2_dcache_cluster_per_acc_m, dcache_request_queue[0].resp[resp_flag].e2_dcache_policy_m,  dcache_request_queue[0].e1_non_trapping_i, dcache_request_queue[0].resp[resp_flag].e2_non_trapping_id_cancel_o, dcache_request_queue[0].resp[resp_flag].e2_trap_nomapping_o, dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o,dcache_request_queue[0].resp[resp_flag].e2_trap_writetoclean_o, dcache_request_queue[0].resp[resp_flag].e2_trap_atomictoclean_o, dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o, dcache_request_queue[0].resp[resp_flag].e2_trap_dsyserror_o), UVM_HIGH) 
        end

        else if(resp_flag == 1)begin
            
              $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE] TLB ARRAY[%0d] Page Size: %0d No Usefull Bit: %0d Virtual Address: 'h%0X, Virtual Page: 'h%0X, FN: 'h%0X, Physique Address: 'h%0X, Size of address: %0d,Second access: %0d,Cluster: %0d, Policy: %0d, E1-Non-Trapping-EN: %0d, E2-Non-trapping-ID-cancel: %0d, Trap nomapping: %0d,  Trap protection: %0d, Trap writetoclean: %0d, Trap atomictoclean: %0d, Trap dmisalign: %0d,Trap dsyserror: %0d", $time, dcache_request_queue[0].resp[resp_flag].idx, dcache_request_queue[0].resp[resp_flag].page_size, dcache_request_queue[0].resp[resp_flag].no_usefull_bit,dcache_request_queue[0].e1_dcache_virt_addr_i, dcache_request_queue[0].virt_page,dcache_request_queue[0].resp[resp_flag].fn, dcache_request_queue[0].resp[resp_flag].e2_dcache_phys_addr_m, dcache_request_queue[0].e1_dcache_size_i, dcache_request_queue[0].resp[resp_flag].dcache_second_acc_d_i, dcache_request_queue[0].resp[resp_flag].e2_dcache_cluster_per_acc_m, dcache_request_queue[0].resp[resp_flag].e2_dcache_policy_m,  dcache_request_queue[0].e1_non_trapping_i, dcache_request_queue[0].resp[resp_flag].e2_non_trapping_id_cancel_o, dcache_request_queue[0].resp[resp_flag].e2_trap_nomapping_o, dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o,dcache_request_queue[0].resp[resp_flag].e2_trap_writetoclean_o, dcache_request_queue[0].resp[resp_flag].e2_trap_atomictoclean_o, dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o, dcache_request_queue[0].resp[resp_flag].e2_trap_dsyserror_o));

            `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REPONSE] TLB ARRAY[%0d] Page Size: %0d No Usefull Bit: %0d Virtual Address: 'h%0X, Virtual Page: 'h%0X, FN: 'h%0X, Physique Address: 'h%0X, Size of address: %0d,Second access: %0d,Cluster: %0d, Policy: %0d, E1-Non-Trapping-EN: %0d, E2-Non-trapping-ID-cancel: %0d, Trap nomapping: %0d,  Trap protection: %0d, Trap writetoclean: %0d, Trap atomictoclean: %0d, Trap dmisalign: %0d,Trap dsyserror: %0d", $time, dcache_request_queue[0].resp[resp_flag].idx, dcache_request_queue[0].resp[resp_flag].page_size, dcache_request_queue[0].resp[resp_flag].no_usefull_bit,dcache_request_queue[0].e1_dcache_virt_addr_i, dcache_request_queue[0].virt_page,dcache_request_queue[0].resp[resp_flag].fn, dcache_request_queue[0].resp[resp_flag].e2_dcache_phys_addr_m, dcache_request_queue[0].e1_dcache_size_i, dcache_request_queue[0].resp[resp_flag].dcache_second_acc_d_i, dcache_request_queue[0].resp[resp_flag].e2_dcache_cluster_per_acc_m, dcache_request_queue[0].resp[resp_flag].e2_dcache_policy_m,  dcache_request_queue[0].e1_non_trapping_i, dcache_request_queue[0].resp[resp_flag].e2_non_trapping_id_cancel_o, dcache_request_queue[0].resp[resp_flag].e2_trap_nomapping_o, dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o,dcache_request_queue[0].resp[resp_flag].e2_trap_writetoclean_o, dcache_request_queue[0].resp[resp_flag].e2_trap_atomictoclean_o, dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o, dcache_request_queue[0].resp[resp_flag].e2_trap_dsyserror_o), UVM_HIGH) 
            
        end

        
                /****************************************************************************************************************************
                *************************************************   Checker  ****************************************************************
                ****************************************************************************************************************************/

/**********  Check Physique Address ****************/
        //The physique address is combinaision with the the no usefull bit of fn repaced by the no usefull bit of the virt page  
        if(resp_flag == 0)begin    
            if((dcache_request_queue[0].e1_dcache_opc != WPURGE) && (dcache_request_queue[0].e1_dcache_opc != DINVAL))begin        
                if(dcache_request_queue[0].resp[resp_flag].e2_trap_nomapping_o == 0)begin
                  logic [19:0] fn_temp;
                  logic [19:0] virt_address_temp;
                    fn_temp = dcache_request_queue[0].resp[resp_flag].fn;
                    virt_address_temp = dcache_request_queue[0].virt_page;

                    fn_temp = fn_temp >> dcache_request_queue[0].resp[resp_flag].no_usefull_bit;
                    fn_temp = fn_temp << dcache_request_queue[0].resp[resp_flag].no_usefull_bit;
                    
                    virt_address_temp = virt_address_temp << (20 - dcache_request_queue[0].resp[resp_flag].no_usefull_bit);
                    virt_address_temp = virt_address_temp >> (20 - dcache_request_queue[0].resp[resp_flag].no_usefull_bit);
                    
                    fn_temp = fn_temp + virt_address_temp;
                                                         
                    if(( fn_temp[9:0] ) !== dcache_request_queue[0].resp[resp_flag].e2_dcache_phys_addr_m)begin                    
                        `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Physique Address['h%0X] do not match the calculation FN['h%0X] ", dcache_request_queue[0].resp[resp_flag].e2_dcache_phys_addr_m, fn_temp ));
                    end                    
                end     
            end
        end
        
               
/************* Check Cluster Periph **************/ 
        if (resp_flag == 0)  begin 
        // ===========>>>>>>>>>> TBD     
   /*     $display("GZFN: %X",dcache_request_queue[0].resp[resp_flag].fn );
        if(('h2000 < dcache_request_queue[0].resp[resp_flag].fn) && (dcache_request_queue[0].resp[resp_flag].fn < 'h3FFF))begin
            
            if( dcache_request_queue[0].resp[resp_flag].e2_dcache_cluster_per_acc_m == 0)
              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Cluster periph access must be 1 when the physique address between 0x200_0000 and 0x3FF_FFFF"));
        end
        else begin
            if( dcache_request_queue[0].resp[resp_flag].e2_dcache_cluster_per_acc_m == 1)
              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Cluster periph access must be 0 when the physique address is not between 0x200_0000 and 0x3FF_FFFF"));
        end
       
        */
/*************** Check Dcache Policy CP *******************/
                         
            if((dcache_request_queue[0].e1_dcache_opc != WPURGE) && (dcache_request_queue[0].e1_dcache_opc != DINVAL))begin
                if(dcache_request_queue[0].resp[resp_flag].cp == 2)begin 
                    if(dcache_request_queue[0].resp[resp_flag].e2_dcache_policy_m == 0)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Dcache policy must be 1 when TLB.CP is WRITE THROUGH"));
                end  
                else begin
                    if(dcache_request_queue[0].resp[resp_flag].e2_dcache_policy_m == 1)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Dcache policy must be 0 when TLB.CP is not WRITE THROUGH"));
                end              
            end                         
            
/***************** Check Trap WriteToClean, only done on the first access, no meaning on the second access *************/
              
            
            if ((dcache_request_queue[0].e1_dcache_opc == STORE)|| (dcache_request_queue[0].e1_dcache_opc == DZEROL) || (dcache_request_queue[0].e1_dcache_opc == LDC) || (dcache_request_queue[0].e1_dcache_opc == FDA) || (dcache_request_queue[0].e1_dcache_opc == CWS)) begin
                // On STORE and DZEROL
                if ((dcache_request_queue[0].resp[resp_flag].es == 2) || (dcache_request_queue[0].resp[resp_flag].es == 3)) begin
                    // WriteToClean not allowed
                    if (dcache_request_queue[0].resp[resp_flag].e2_trap_writetoclean_o === 1)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Writetoclean should not be set when TLB<i>.ES in [2,3]"));
                end
                else begin
                    // WriteToClean
                    if (dcache_request_queue[0].resp[resp_flag].e2_trap_writetoclean_o === 0)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Writetoclean should be set when TLB<i>.ES == 1"));
                end
            end
            else begin
                if (dcache_request_queue[0].resp[resp_flag].e2_trap_writetoclean_o === 1)
                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Writetoclean should not be set when the opcode is not STORE or DZEROL, LDC, FDA, CWS"));
            end
            
            
/************** Check Trap Atomictoclean and Entry Status ES **********************/
            
            if ((dcache_request_queue[0].e1_dcache_opc == LDC) || (dcache_request_queue[0].e1_dcache_opc == FDA) || (dcache_request_queue[0].e1_dcache_opc == CWS)) begin
                // On LDC, FDA, CWS
                if ((dcache_request_queue[0].resp[resp_flag].es == 3)) begin
                    // Atomictoclean not allowed
                    if (dcache_request_queue[0].resp[resp_flag].e2_trap_atomictoclean_o === 1)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap AtomicToClean should not be set when TLB<i>.ES == 3"));
                end
                else begin
                    // Atomictoclean
                    if (dcache_request_queue[0].resp[resp_flag].e2_trap_atomictoclean_o === 0)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap AtomicToClean should be set when TLB<i>.ES in [1,2]"));
                end
                if ((dcache_request_queue[0].resp[resp_flag].e2_trap_writetoclean_o === 1) && (dcache_request_queue[0].resp[resp_flag].e2_trap_atomictoclean_o === 0))
                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! WriteToClean detected on LDC, FDA, CWS but no AtomicToClean detected"));
            end
            else begin
                if (dcache_request_queue[0].resp[resp_flag].e2_trap_atomictoclean_o === 1)
                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap AtomicToClean should not be set when the opcode is not LDC, FDA, CWS"));
            end
            
                
/************** Check Trap Protecion // PA 11-13: X(Execute) is ignored in the mode cluster.// It is just for the first access *********/
             
            if((dcache_request_queue[0].e1_non_trapping_i !=1) && (dcache_request_queue[0].e1_dcache_opc != WPURGE) && (dcache_request_queue[0].e1_dcache_opc != DINVAL))begin
              int unsigned write_en;
              int unsigned read_en;
          
                if((dcache_request_queue[0].e1_dcache_opc == LDC) || (dcache_request_queue[0].e1_dcache_opc == FDA) || (dcache_request_queue[0].e1_dcache_opc == CWS)  || (dcache_request_queue[0].e1_dcache_opc == STORE)  || (dcache_request_queue[0].e1_dcache_opc == DZEROL))begin
                    write_en = 1;
                end
                else begin
                    write_en = 0;
                end
                if((dcache_request_queue[0].e1_dcache_opc == LOAD) || (dcache_request_queue[0].e1_dcache_opc == DINVALL) || (dcache_request_queue[0].e1_dcache_opc == DTOUCHL))begin
                    read_en = 1;
                end
                else begin
                    read_en = 0;
                end
                
           
                if(mmucfg_intf.priviledge_mode_m == 0)begin //In the priviledge  mode 0
                    
                    if(dcache_request_queue[0].resp[resp_flag].pa <= 4)begin
                        if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 0) 
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must be set 1 when the PA is No Access(NA:0,1,2,3,4)", dcache_request_queue[0].resp[resp_flag].idx));
                    end
                    else begin
                        
                        if((read_en == 1) && (write_en == 0))begin
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 1)begin                              
                                if(different_cp_flag == 1)begin
                                    `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_CHECKER_TRAP_PROTECTION_CP]: [MATCH_TLB %0d]: It is normal that the trap protection is set when the precedent or after tlb.cp is not as same as the actuel tlb.cp ", $time, dcache_request_queue[0].resp[resp_flag].idx), UVM_HIGH)   
                                end
                                else begin
                                   
                                    `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must not be set when the PA is not No Access(NA:0,1,2,3,4) with the instruction read but without instruction write", dcache_request_queue[0].resp[resp_flag].idx));
                                end
                            end
                        end
                    end
                    if((dcache_request_queue[0].resp[resp_flag].pa == 5) || (dcache_request_queue[0].resp[resp_flag].pa == 6) || (dcache_request_queue[0].resp[resp_flag].pa == 7) || (dcache_request_queue[0].resp[resp_flag].pa == 8) || (dcache_request_queue[0].resp[resp_flag].pa == 11) || (dcache_request_queue[0].resp[resp_flag].pa == 12))begin
                        if(write_en == 1)begin
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 0)
                              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must be set when the PA is Read Only(5,6,7,8)", dcache_request_queue[0].resp[resp_flag].idx));
                        end                      
                        else begin
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 1)
                              if(different_cp_flag == 1)begin
                                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_CHECKER_TRAP_PROTECTION_CP]: [MATCH_TLB %0d]: It is normal that the trap protection is set when the precedent or after tlb.cp is not as same as the actuel tlb.cp ", $time, dcache_request_queue[0].resp[resp_flag].idx), UVM_HIGH)   
                              end
                              else begin   
                                  
                                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must not be set when the PA is Read Only(5,6,7,8) and write en is disable", dcache_request_queue[0].resp[resp_flag].idx));
                              end
                        end
                    end
                    if((dcache_request_queue[0].resp[resp_flag].pa == 9) || (dcache_request_queue[0].resp[resp_flag].pa == 10) || (dcache_request_queue[0].resp[resp_flag].pa == 13))begin
                        if((write_en == 1) || (read_en == 1))begin
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 1)
                              if(different_cp_flag == 1)begin
                                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_CHECKER_TRAP_PROTECTION_CP]: [MATCH_TLB %0d]: It is normal that the trap protection is set when the precedent or after tlb.cp is not as same as the actuel tlb.cp ", $time, dcache_request_queue[0].resp[resp_flag].idx), UVM_HIGH)   
                              end
                              else begin
                                 
                                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must not be set when the PA is Read Write(9,10,13)", dcache_request_queue[0].resp[resp_flag].idx)); 
                              end
                        end
                        else begin// It is not very useful
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 1)
                              if(different_cp_flag == 1)begin
                                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_CHECKER_TRAP_PROTECTION_CP]: [MATCH_TLB %0d]: It is normal that the trap protection is set when the precedent or after tlb.cp is not as same as the actuel tlb.cp ", $time, dcache_request_queue[0].resp[resp_flag].idx), UVM_HIGH)   
                              end
                              else begin
                                  
                                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must not be set when the PA is Read Write(9,10,13) and have not Write or Read instructions", dcache_request_queue[0].resp[resp_flag].idx));
                              end
                        end
                    end                                                                       
                end                 
                else begin
                    //In the priviledge  mode 1
                    if(dcache_request_queue[0].resp[resp_flag].pa == 0)begin 
                        if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 0)
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must be set when the PA is No Access(NA:0)", dcache_request_queue[0].resp[resp_flag].idx));
                    end
                    else begin
                        if((read_en == 1) && (write_en == 0))begin
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 1)
                              if(different_cp_flag == 1)begin
                                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_CHECKER_TRAP_PROTECTION_CP]: [MATCH_TLB %0d]: It is normal that the trap protection is set when the precedent or after tlb.cp is not as same as the actuel tlb.cp ", $time, dcache_request_queue[0].resp[resp_flag].idx), UVM_HIGH)   
                              end
                              else begin
                                 
                                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must not be set when the PA is not No Access(NA:0) on read access in priviledge mode", dcache_request_queue[0].resp[resp_flag].idx));
                              end
                        end
                    end
                    if((dcache_request_queue[0].resp[resp_flag].pa == 1) || (dcache_request_queue[0].resp[resp_flag].pa == 3) || (dcache_request_queue[0].resp[resp_flag].pa == 5) || (dcache_request_queue[0].resp[resp_flag].pa == 7) || (dcache_request_queue[0].resp[resp_flag].pa == 11))begin
                        
                        if(write_en == 1)begin
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 0)
                              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must be set when the PA is Read Only(1,3,5,7,11)", dcache_request_queue[0].resp[resp_flag].idx));
                        end
                        else begin
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 1)
                              if(different_cp_flag == 1)begin
                                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_CHECKER_TRAP_PROTECTION_CP]: [MATCH_TLB %0d]: It is normal that the trap protection is set when the precedent or after tlb.cp is not as same as the actuel tlb.cp ", $time, dcache_request_queue[0].resp[resp_flag].idx), UVM_HIGH)   
                              end
                              else begin
                                 
                                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must not be set when the PA is Read Only(1,3,5,7,11) without the write instruction", dcache_request_queue[0].resp[resp_flag].idx));
                              end
                        end
                    end
                    if((dcache_request_queue[0].resp[resp_flag].pa == 2) || (dcache_request_queue[0].resp[resp_flag].pa == 4) || (dcache_request_queue[0].resp[resp_flag].pa == 6) || (dcache_request_queue[0].resp[resp_flag].pa == 8) || (dcache_request_queue[0].resp[resp_flag].pa == 9) || (dcache_request_queue[0].resp[resp_flag].pa == 10) || (dcache_request_queue[0].resp[resp_flag].pa == 12) || (dcache_request_queue[0].resp[resp_flag].pa == 13))begin                       
                        if((write_en == 1) || (read_en == 1))begin
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 1)
                              if(different_cp_flag == 1)begin
                                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_CHECKER_TRAP_PROTECTION_CP]: [MATCH_TLB %0d]: It is normal that the trap protection is set when the precedent or after tlb.cp is not as same as the actuel tlb.cp ", $time, dcache_request_queue[0].resp[resp_flag].idx), UVM_HIGH)   
                              end
                              else begin                                 
                                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must not be set when the PA is Read Write(2,4,6,8,9,10,12,13)", dcache_request_queue[0].resp[resp_flag].idx)); 
                              end
                        end
                        else begin // It is not very useful
                            if(dcache_request_queue[0].resp[resp_flag].e2_trap_protection_o == 1)
                              if(different_cp_flag == 1)begin
                                  `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_CHECKER_TRAP_PROTECTION_CP]: [MATCH_TLB %0d]: It is normal that the trap protection is set when the precedent or after tlb.cp is not as same as the actuel tlb.cp ", $time, dcache_request_queue[0].resp[resp_flag].idx), UVM_HIGH)   
                              end
                              else begin                                   
                                  `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: [MATCH_TLB %0d]: ERROR! Trap Protection must not be set when the PA is Read Write(2,4,6,8,9,10,12,13) without the instructions Write or Read", dcache_request_queue[0].resp[resp_flag].idx)); 
                              end
                        end
                    end                    
                end                
            end 
            
           

            
     


/************************* Check the Trap Dmisalign ***************************/
        
        if((dcache_request_queue[0].e1_dcache_size_i == 2) && (dcache_request_queue[0].e1_dcache_virt_addr_i[0] != 0) ||  (dcache_request_queue[0].e1_dcache_size_i == 4) && (dcache_request_queue[0].e1_dcache_virt_addr_i[1:0] != 0) || (dcache_request_queue[0].e1_dcache_size_i == 8) && (dcache_request_queue[0].e1_dcache_virt_addr_i[2:0] != 0))begin
            aligned_mode_flag = 0;
        end
        else begin
            aligned_mode_flag = 1;
        end

       // if(dcache_request_queue[0].resp[resp_flag].cp != 0)begin
            if ((dcache_request_queue[0].e1_dcache_opc == LDC) || (dcache_request_queue[0].e1_dcache_opc == FDA)) begin
              int aligned_mode_flag_local;
                if(dcache_request_queue[0].e1_dcache_virt_addr_i[2:0] == 0)begin
                    aligned_mode_flag_local = 1;
                end
                else begin
                    aligned_mode_flag_local = 0;
                end
                
                if(aligned_mode_flag_local == 1)begin
                    if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 1)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Dmisalign can NOT be generated when we access the instructions LDC or FDA with the aligned address on the 64bit"));
                end
                else begin
                    if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 0)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Dmisalign MUST be generated when we access the instructions LDC or FDA with the aligned address on the 64bit"));
                end
            end         
            else if(dcache_request_queue[0].e1_dcache_opc == CWS && dcache_request_queue[0].resp[resp_flag].cp != 0) begin
              int aligned_mode_flag_local;
                if(dcache_request_queue[0].e1_dcache_virt_addr_i[1:0] == 0)begin
                    aligned_mode_flag_local = 1;
                end
                else begin
                    aligned_mode_flag_local = 0;
                end
                
                if(aligned_mode_flag_local == 1)begin
                    if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 1)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Dmisalign can NOT be generated when we access the instructions CWC with the aligned address on the 32bit"));
                end
                else begin
                    if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 0)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Dmisalign MUST be generated when we access the instructions CWC with the no aligned address on the 32bit"));
                end
            end    
            else if (((dcache_request_queue[0].e1_dcache_opc == LOAD) || (dcache_request_queue[0].e1_dcache_opc == STORE)) && (dcache_request_queue[0].resp[resp_flag].cp != 0)) begin
                if(dcache_request_queue[0].resp[resp_flag].cp != 0)begin
                    //$display("GG:pre_idx:%0d pre_idx_found:%0d cp:%0d",reponse.pre_idx,pre_idx_found,tlb_array[reponse.pre_idx].cp);
                    if(!(tlb_array[reponse.pre_idx].cp ==0 && pre_idx_found == 1))begin
                        if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 1)
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Dmisalign can NOT be generated when we access the instructions LOAD or STORE with the CP is not 0(Device Access)"));
                    end
                end            
                else begin
                    if(aligned_mode_flag == 1)begin
                        if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 1)
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Dmisalign can NOT be generated when we access the instructions LOAD or STORE with the CP is 0(Device Access) and aligned address"));
                    end
                    else begin
                        if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 0 )
                          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Dmisalign MUST be generated when we access the instructions LOAD or STORE with the CP is 0(Device Access) and no aligned address"));
                    end
                end
            end
            else begin
                if((dcache_request_queue[0].e1_dcache_opc != DINVAL) && (dcache_request_queue[0].e1_dcache_opc != WPURGE) && dcache_request_queue[0].resp[resp_flag].cp != 0)begin                 
                    if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 1)begin                  
                        `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Trap Dmisalign can NOT be generated when we did not access the instructions LOAD, STORE, LDC, FDA, CWS with the CP is 0(Device Access) and no aligned address"));
                    end
                    
                end
            end
       // end  
            
      /*  else begin          
            //Must consider later
            if((dcache_request_queue[0].e1_dcache_opc != DINVAL) && (dcache_request_queue[0].e1_dcache_opc != WPURGE))begin
                if(dcache_request_queue[0].resp[resp_flag].e2_trap_dmisalign_o == 1)begin
                    if(aligned_mode_flag == 1)begin
                        $display("GG:Opcode[%0s], cp:%0d, pre_found:%0d, pre_index:%0d aligned_mode_flag:%0d",dcache_request_queue[0].e1_dcache_opc, dcache_request_queue[0].resp[resp_flag].cp, pre_idx_found,tlb_array[reponse.pre_idx].cp , aligned_mode_flag);
                    end
                end
                else begin
                    if(aligned_mode_flag == 0)begin
                        $display("GG:Opcode2[%0s], cp:%0d, pre_found:%0d, pre_index:%0d aligned_mode_flag:%0d",dcache_request_queue[0].e1_dcache_opc, dcache_request_queue[0].resp[resp_flag].cp, pre_idx_found,tlb_array[reponse.pre_idx].cp ,aligned_mode_flag);
                    end
                end
            end
        end
            */


        end // if (resp_flag == 0)
/************************ Check the instruction DZEROL and Second Access **********************/
        
        if((dcache_request_queue[0].e1_dcache_opc == DZEROL) && ( dcache_request_queue[0].resp[resp_flag].dcache_second_acc_d_i == 1))
          `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REPONSE]: ERROR! Second access can not happen when opcode is DZEROL "));

    
/************************  Info: current addr is in last page address or in the first page address ***********************/

      
        if((dcache_request_queue[0].e1_dcache_opc != WPURGE) && (dcache_request_queue[0].e1_dcache_opc != DINVAL))begin
            if (dcache_request_queue[0].e1_dcache_virt_addr_i >= (tlb_array[ dcache_request_queue[0].resp[resp_flag].idx].last_line_addr_of_page - 64))begin
                tlb_array[dcache_request_queue[0].resp[resp_flag].idx].last_addr_is_used = 1;
                tlb_array[dcache_request_queue[0].resp[resp_flag].idx].last_addr_use_times += 1;
            end
            if (dcache_request_queue[0].e1_dcache_virt_addr_i <= (tlb_array[ dcache_request_queue[0].resp[resp_flag].idx].first_line_addr_of_page + 64))begin
                tlb_array[dcache_request_queue[0].resp[resp_flag].idx].first_addr_is_used = 1;
                tlb_array[dcache_request_queue[0].resp[resp_flag].idx].first_addr_use_times += 1;
            end         
        end

        
    end // if ((found == 1) && (reponse.es != 0))
    

   end // if (tlb_array[reponse.idx].check_mmc_error_mode == 0)
    
    

    
    
  
      
endtask : store_dcache_reponse 

task tb_mmu_refmodel :: trap_protection_management(logic [31:0] virt_addr, int addr_size, logic [31:0] last_line_addr, int second_access, int found, int pre_idx_found,int pre_idx, int es, int priviledge_mode_random, int pa, int different_cp_flag, e1_dcache_opc_t opcode, int e2_trap_protection_o, int e2_trap_nomapping_o, int trap_nomapping_flag,int e1_non_trapping_i, int spe ,int idx, output int trap_protection_flag);
    

    
  int unsigned rd_allowed,pre_rd_allowed;
  int unsigned wr_allowed,pre_wr_allowed;
  int unsigned write_access;
  int unsigned read_access;
  int unsigned trap_protection, pre_trap_protection, trap_protection_2bits;
  int unsigned pa_authorised, pre_pa_authorised; 
    rd_allowed = 0;
    wr_allowed = 0;
    pre_rd_allowed = 0;
    pre_wr_allowed = 0;
    
    if (priviledge_mode_random == 0) begin
        if (pa >= 5 && pa < 14)
          rd_allowed = 1;
        if (pa == 9 || pa == 10 || pa == 13)
          wr_allowed = 1;
    end
    else begin
        if (pa >= 1 && pa < 14)
          rd_allowed = 1;
        if (pa == 2 || pa == 4 || pa == 6 || pa == 8 || pa == 9 ||  pa == 10 || pa == 12 || pa == 13)
          wr_allowed = 1;
    end 

    if(pre_idx_found == 1)begin
        if (priviledge_mode_random == 0) begin
            if (tlb_array[pre_idx].pa >= 5 && tlb_array[pre_idx].pa < 14)
              pre_rd_allowed = 1;
            if (tlb_array[pre_idx].pa == 9 || tlb_array[pre_idx].pa == 10 || tlb_array[pre_idx].pa == 13)
              pre_wr_allowed = 1;
        end
        else begin
            if (tlb_array[pre_idx].pa >= 1 && tlb_array[pre_idx].pa < 14)
              pre_rd_allowed = 1;
            if (tlb_array[pre_idx].pa == 2 || tlb_array[pre_idx].pa == 4 || tlb_array[pre_idx].pa == 6 || tlb_array[pre_idx].pa == 8 || tlb_array[pre_idx].pa == 9 || tlb_array[pre_idx].pa == 10 || tlb_array[pre_idx].pa == 12 || tlb_array[pre_idx].pa == 13)
              pre_wr_allowed = 1;
        end        
    end
    
    if((opcode == LDC) || (opcode == FDA) || (opcode == CWS) || (opcode == STORE) || (opcode == DZEROL))begin
        write_access = 1;
    end
    else begin
        write_access = 0;
    end
    if((opcode == LOAD) || (opcode == DINVALL) || (opcode == DTOUCHL))begin
        read_access = 1;
    end
    else begin
        read_access = 0;
    end

    if(write_access == 1)begin        
        if(wr_allowed == 0)begin            
            pa_authorised = 0;             
        end
        else begin
            pa_authorised = 1;           
        end    

        if(pre_idx_found == 1)begin
            if(pre_wr_allowed == 0)begin
                pre_pa_authorised = 0;
            end
            else begin
                pre_pa_authorised = 1;           
            end        
        end
        else begin          
                pre_pa_authorised = 0;                  
        end       
    end
    else if(read_access == 1)begin
        if(rd_allowed == 0)begin
            pa_authorised = 0;
        end
        else begin
            pa_authorised = 1;           
        end             
        if(pre_idx_found == 1)begin
            if(pre_rd_allowed == 0)begin
                pre_pa_authorised = 0;
            end
            else begin
                pre_pa_authorised = 1;           
            end        
        end
        else begin
             pre_pa_authorised = 0;        
        end   
    end
    
    if((opcode != DINVAL) && (opcode != WPURGE) && (second_access == 0))begin

        if(found == 0)begin
            if(e2_trap_protection_o !=0)
              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [Trap_Protection_check]: e2_trap_protection_o must 0 when spe is 0 and e1_non_trapping_i is 1"));            
        end
        
        //Generate the simulation value of the trap protection 0-3              
        if(((virt_addr + addr_size - 1) > last_line_addr) || (last_line_addr == 'hFFFFFFFF && ((virt_addr + addr_size - 1) < 10) ))begin
            //Trap protection 1
            if(pa_authorised == 0)begin
                trap_protection = 1;
            end
          
            if(opcode == LOAD || opcode == STORE)begin

                if(different_cp_flag == 1 && pa_authorised == 1)begin
                    trap_protection = 1;
                end      
                //Trap protection 2          
                if(pre_idx_found == 1 && pa_authorised == 1 && pre_pa_authorised == 0)begin
                    if(different_cp_flag == 1)begin
                        trap_protection = 3;
                    end
                    else begin
                        trap_protection = 2;
                    end
                end
                //Trap protection 3
                if(pa_authorised == 0 && ((pre_pa_authorised == 0 && pre_idx_found == 1) || pre_idx_found == 0))begin
                    trap_protection = 3;
                end
            end  
            $display("GG:trap_protection:%0d",trap_protection);                      
        end
        else begin
          int unsigned last_lign_addr_4K;
            last_lign_addr_4K = virt_addr + 4096;
            last_lign_addr_4K[11:0] = 0;     
                    
            if(pa_authorised == 0)begin
                trap_protection = 1;
            end
            else begin
                trap_protection = 0;
            end
            if(((virt_addr + addr_size) > last_lign_addr_4K) && (virt_addr < last_lign_addr_4K))begin
             
                if(last_line_addr != 'hFFFFFFFF)begin
                    if(pa_authorised == 0)begin
                        
                        if(opcode == LOAD || opcode == STORE)begin
                            trap_protection = 3;
                        end
                        else begin
                            trap_protection = 1;
                        end                   
                    end 
                end
                else begin
                    if((virt_addr + addr_size) < last_line_addr)begin
                        if(pa_authorised == 0)begin
                            
                            if(opcode == LOAD || opcode == STORE)begin
                                trap_protection = 3;
                            end
                            else begin
                                trap_protection = 1;
                            end
                        end
                    end
                end
            end           
        end 
        // When the trap nomappin is not 0, not consider trap nomapping is 1 and 3 
        if(e2_trap_nomapping_o == 2)begin
            if(pa_authorised == 1)begin
                trap_protection = 0;
            end
            if(pa_authorised == 0 && (pre_pa_authorised == 0 || (pre_idx_found == 1 &&  tlb_array[pre_idx].es == 0)))begin
                trap_protection = 3;
            end

        end
           
        if(trap_protection > 0)begin
            trap_protection_flag = 1;
        end
        else begin
            trap_protection_flag = 0;
        end
        
        /*************** Check ****************/
        // Generate the correct trap protection to correspondant the interface trap protection
        // mmucfg_intf.processor_in_debug_m == 0 
        if(e1_non_trapping_i == 0)begin
            if(e2_trap_nomapping_o != 1 && e2_trap_nomapping_o != 3)begin //Not consider the trap nomaiing is 1 beacause trap protection is random
                if(trap_protection != e2_trap_protection_o)begin
                    $display("GG:pa_authorised :%0d pre_pa_authorised :%0d",pa_authorised,pre_pa_authorised);
                    $display("GG:virt address:%0X last line:%0X trap_protection :%0d  e2_trap_protection_o: %0d found :%0d Trap_Nomapping:%0d ES:%0d opcode:%s pre_idx_found:%0d pre_idex  :%0d  pre_idx.es :%0d [%0d]", virt_addr, last_line_addr, trap_protection,e2_trap_protection_o,found, e2_trap_nomapping_o,es, opcode, pre_idx_found,pre_idx, tlb_array[pre_idx].es, $time);
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [Trap_Protection_check]:[%0d] the trap protection[%0d] must be the same value[%0d] of the interface of e2_trap_protection_o when e1_non_trapping_i is 0", $time, trap_protection, e2_trap_protection_o));
                end  
            end      
        end
        else begin
         /*   if(e2_trap_nomapping_o == 0 || trap_nomapping_flag == 0)begin
                if(spe == 1)begin
                    if(trap_protection != e2_trap_protection_o)
                      `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [Trap_Protection_check]: the trap protection[%0d] must be the same value[%0d] of the interface of e2_trap_protection_o when e1_non_trapping_i is 1 and spe is 1",trap_protection, e2_trap_protection_o));
                end
                else begin
                    if(e2_trap_protection_o != 0)begin
                        $display("GG:Trap_Protection_flag :%0d e2_trap_protection_o: %0d",trap_protection_flag, e2_trap_protection_o );
                        `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [Trap_Protection_check]: e2_trap_protection_o must 0 when spe is 0 and e1_non_trapping_i is 1"));
                    end               
                end
            end*/
        end
        
    end
    
endtask :  trap_protection_management


task tb_mmu_refmodel :: trap_nomapping_management(logic [31:0] virt_addr, int addr_size, logic [31:0] last_line_addr, int es, int found, int sne, int e1_non_trapping_i,int pre_idx_found,int pre_idx, int e2_trap_nomapping_o, int second_access, e1_dcache_opc_t opcode, output int trap_nomapping_flag);
    
  int  trap_nomapping;

    if((opcode != DINVAL) && (opcode != WPURGE) && (second_access == 0))begin
        
        if((found == 1 && es == 0) || found == 0)begin      
            trap_nomapping = 1;        
        end
        else begin
            trap_nomapping = 0;      
        end 
        if(((virt_addr + addr_size - 1) > last_line_addr) || (last_line_addr == 'hFFFFFFFF && ((virt_addr + addr_size - 1) < 10) ))begin
                        
            if(opcode == LOAD || opcode == STORE)begin
                if((found == 1 && es !=0) && ( pre_idx_found == 0 || (pre_idx_found == 1 && tlb_array[pre_idx].es == 0)))begin
                    trap_nomapping = 2;   
                    
                end     
                else if((found == 0 || (found == 1 && es == 0)) && (pre_idx_found == 0 || (pre_idx_found == 1 && tlb_array[pre_idx].es == 0))) begin
                   /* if(last_line_addr == 'hFFFFFFFF)begin
                        trap_nomapping = 1;   
                    end
                    else begin*/
                        trap_nomapping = 3;   
                   // end
                                        
                end
                else if((found == 0 || (found == 1 && es == 0)) && (pre_idx_found == 1 && tlb_array[pre_idx].es != 0)) begin
                    trap_nomapping = 1;
                end
                else begin
                    trap_nomapping = 0; 
                end
            end
        end
        else begin
            if((found == 0 || (found == 1 && es == 0)) && (last_line_addr != 'hFFFFFFFF))begin             
              int unsigned last_lign_addr_4K;
                last_lign_addr_4K = virt_addr + 4096;
                last_lign_addr_4K[11:0] = 0;     
                $display("GG:last_lign_addr_4K:%0X last_line_addr:%0X",last_lign_addr_4K,last_line_addr);
                if((virt_addr + addr_size) > last_lign_addr_4K)begin
                    if(opcode == LOAD || opcode == STORE)begin
                        trap_nomapping = 3;
                    end
                    else begin
                        trap_nomapping = 1;
                    end
                end               
            end
        end
        if(trap_nomapping > 0)begin
            trap_nomapping_flag = 1;
        end
        else begin
            trap_nomapping_flag = 0;
        end
          
/********************* Check Trap Nomapping without the condition e1_non_trapping_i 1 and SNE is 0 ***************/         
         
        if(e1_non_trapping_i == 0)begin 
           
            if(e2_trap_nomapping_o != trap_nomapping)begin
                `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [Trap_Protection_check]: the trap nomapping[%0d] must be %0d when e2_trap_nomapping_o is %0d",trap_nomapping,e2_trap_nomapping_o,e2_trap_nomapping_o));
            end
                                                  
        end
        else begin
            if(sne == 1)begin
               
                if(e2_trap_nomapping_o != trap_nomapping)begin
                    `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [Trap_Protection_check]: the trap nomapping[%0d] must be %0d when e2_trap_nomapping_o is %0d",trap_nomapping,e2_trap_nomapping_o,e2_trap_nomapping_o));
                end                          
                
            end
            else begin                 
                //SNE 0
                if(e2_trap_nomapping_o != 0)begin                      
                    `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [Trap_Protection_check]: e2_trap_protection_o must 0 when spe is 0 and e1_non_trapping_i is 1"));
                end                  
            end
        end
    end // if ((opcode != DINVAL) && (opcode != WPURGE) && (second_access == 0))
    
    
endtask : trap_nomapping_management
  
task tb_mmu_refmodel::dcache_request_management(); 
 
    
    @(negedge mmu_proc_dcache_intf.reset);
    forever begin
        @(posedge mmu_proc_dcache_intf.clock);
        wait(response_done_ev.triggered);          
        
        if ((mmu_proc_dcache_intf.e1_dcache_req_i_m == 1) && (mmu_proc_dcache_intf.dcache_e1_grant_i_o == 1) && (mmu_proc_dcache_intf.dcache_e3_stall_i_o == 0) && (mmu_proc_dcache_intf.e2_stall_o == 0)) begin
            
            dcache_trans = new();  
            dcache_trans.get_request();            
            dcache_request_queue = {dcache_request_queue, dcache_trans};          
            
            //Check and ensure the precedent element of queue is deleted successfully          
            if (dcache_request_queue.size > 1)
              `uvm_fatal(get_type_name(), $psprintf("[MMU_REFMODEL]: [DCACHE_REQUEST]: 2 pending request, the element of queue is not deleted successfully!"));

            virt_address_continu={virt_address_continu,dcache_request_queue[0].e1_dcache_virt_addr_i};
            $fdisplay(fileID, $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REQUEST] [%s] virtual address: 'h%0X, Size of address: %0d, Global access: %0d", $time, dcache_request_queue[0].e1_dcache_opc, dcache_request_queue[0].e1_dcache_virt_addr_i, dcache_request_queue[0].e1_dcache_size_i, dcache_request_queue[0].e1_glob_acc_i ));

            `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_REFMODEL]: [DCACHE_REQUEST] [%s] virtual address: 'h%0X, Size of address: %0d, Global access: %0d", $time, dcache_request_queue[0].e1_dcache_opc, dcache_request_queue[0].e1_dcache_virt_addr_i, dcache_request_queue[0].e1_dcache_size_i, dcache_request_queue[0].e1_glob_acc_i), UVM_HIGH)      
            
            if (( dcache_request_queue[0].e1_dcache_virt_addr_i[40:6]) != ( dcache_request_queue[0].page_of_last_byte_access[40:6]) && (dcache_request_queue[0].e1_dcache_opc != DZEROL))begin               
                dcache_request_queue[0].second_access_flag = 1;                
            end          
        end      
    end


endtask : dcache_request_management


  
task tb_mmu_refmodel:: dcache_reponse_management();
    
    int          reponse_flag;
    @(negedge mmu_dcache_intf.reset)
      forever begin
          @(posedge mmu_dcache_intf.clock);        

          if(( dcache_request_queue.size !== 0) && (mmu_dcache_intf.e2_stall_m === 0)) begin
                                                   
              reponse_flag=0;
              
              store_dcache_reponse(reponse_flag);
              
              if((trap_flag == 1) && (dcache_request_queue[0].second_access_flag = 1)) begin                 
                  dcache_request_queue[0].second_access_flag = 0;
                  trap_flag = 0;
              end                       
              
              // check for second access 
              
              if(dcache_request_queue[0].second_access_flag == 1) begin                
                  reponse_flag=1;
                  // Wait second_access signal
                  while (mmu_dcache_intf.dcache_second_acc_d_i_s === 0) begin
                      ->response_done_ev;
                      @(posedge mmu_dcache_intf.clock);
                  end
              
               // wait(mmu_dcache_intf.dcache_second_acc_d_i_s == 1);
               
                  store_dcache_reponse(reponse_flag);                                    
              end
              
              dcache_request_queue.delete(0);
                   
          end
          
          ->response_done_ev;
      end 
    
endtask : dcache_reponse_management
  
class mmu_dcache_trans;

    
  logic [40:0]e1_dcache_virt_addr_i;
  logic       e1_glob_acc_i;
  logic [3:0] e1_dcache_size_i;
  logic       e1_non_trapping_i;
  e1_dcache_opc_t e1_dcache_opc;    
  mmu_dcache_reponse resp[$];
  logic [28:0]  virt_page;

  bit           second_access_flag;
  logic [40:0]  page_of_last_byte_access;
 
    function new();             
    endfunction : new

    function void  get_request();
        
     
        this.e1_dcache_virt_addr_i  =   mmu_proc_dcache_intf.e1_dcache_virt_addr_i_m;
        this.virt_page              =   this.e1_dcache_virt_addr_i >> 12;
        this.e1_glob_acc_i          =   mmu_proc_dcache_intf.e1_glob_acc_i_m;
        this.e1_dcache_size_i       =   mmu_proc_dcache_intf.e1_dcache_size_i_m;
        this.e1_non_trapping_i      =   mmu_proc_dcache_intf.e1_non_trapping_i_m;
        this.e1_dcache_opc          =   mmu_proc_dcache_intf.e1_dcache_opc_i_m; 
       
        this.page_of_last_byte_access     =   mmu_proc_dcache_intf.e1_dcache_virt_addr_i_m + mmu_proc_dcache_intf.e1_dcache_size_i_m - 1;
    endfunction : get_request
    
    
endclass :  mmu_dcache_trans

class mmu_dcache_reponse;

  logic [21:12] e2_dcache_phys_addr_m;
  logic         e2_dcache_cluster_per_acc_m;
  logic         e2_dcache_policy_m;
  logic         dcache_second_acc_d_i;


  logic       e2_non_trapping_id_cancel_o;
  logic [1:0] e2_trap_nomapping_o;
  logic [1:0] e2_trap_protection_o;
  logic [1:0] e2_trap_writetoclean_o;
  logic [1:0] e2_trap_atomictoclean_o;
  logic       e2_trap_dmisalign_o;
  logic [1:0] e2_trap_dsyserror_o;
    
  logic [19:0] fn;
  logic [19:0] pn;
  logic [1:0]  cp;
  logic [1:0]  es;
  logic [1:0]  ptc;
  logic [3:0]  pa;
  logic [8:0]  asn;
  logic [8:0]  asn_mmc;
  int          spe;
  int          sne;
  int          g;
  int          idx;
  int          pre_idx;
  int          no_usefull_bit;
  longint unsigned page_size;
  logic [31:0] last_line_addr_of_page;
  logic [31:0] first_line_addr_of_page;
  
    function new();
        
    endfunction : new
 
    
    
endclass: mmu_dcache_reponse
  
  
class tlb_c ;
    
    //For TLB 
  logic [19:0] pn_full; // always related to 4K pages
  logic [19:0] pn; // written
  logic        s;
  logic        g;
  logic [8:0]  asn;
  logic [19:0] fn;
  logic [3:0]  ae;
  logic [3:0]  pa;
  logic [1:0]  cp;
  logic [1:0]  es;

  //For storing the whole value of the three registers
  logic [31:0] mmc;
  logic [31:0] teh;
  logic [31:0] tel;
    
  //For MMC
    //logic        e;
  logic [8:0]  idx;
    //logic [1:0]  ptc;
    //logic        spe;
    //logic        sne;
    //logic [3:0]  lps;
    //logic [3:0]  dps;
    //logic        s_mmc;
    logic [8:0]  asn_mmc;
    
    //For Micro TLB 
  int          udtlb;
  int          uitlb;

  // Information to help tests generation
  int          next_page_is_used = 0;
  int          previous_page_is_used = 0;
    
  int unsigned page_size;
  int          last_addr_is_used = 0;
  logic [31:0] last_line_addr_of_page;
  int          last_addr_use_times;
    
  int          first_addr_is_used = 0;
  logic [31:0] first_line_addr_of_page;
  int          first_addr_use_times;

  int          no_usefull_bit;
  int          check_mmc_error_mode;
  int unsigned multi_mapping_en;
  //Flag for the idx of the tlb array
  int          unsigned idx_origin_w0;
  int          unsigned idx_origin_w1;

  // The parameters for the continueuse page
  int          unsigned continueus_flag;  
  int          unsigned Pre_Continu_Page_Index;
  int          unsigned After_Continu_Page_Index;
  // The least recently written flag to help verify the tlb maintenance index jtlb          
  int          unsigned lrw_index_mode;       
      
                          
    function new();
        this.pn=0;
        this.s=0;
        this.g=0;
        this.asn=0;
        
        this.fn=0;
        this.ae=0;
        this.pa=0;
        this.cp=0;
        this.es=0;
        this.mmc = 0;
        this.teh = 0;
        this.tel = 0;
     //   this.e=0;
        this.idx=0;
      /*  this.ptc=0;
        this.spe=0;
        this.sne=0;
        this.lps=0;
        this.dps=0;
        this.s_mmc=0;*/
        this.asn_mmc=0;
        
        this.udtlb=0; 
        this.uitlb=0;
    endfunction : new

    function void reg_to_array(mmu_reg_blk mmu_registers);           
        int   ratio_page_temp;
        this.pn   =  mmu_registers.mmu_teh.pn.get();
        this.s    =  mmu_registers.mmu_teh.s.get();
        this.g    =  mmu_registers.mmu_teh.g.get();
        this.asn  =  mmu_registers.mmu_teh.asn.get();
        
        this.fn   =  mmu_registers.mmu_tel.fn.get();
        this.ae   =  mmu_registers.mmu_tel.ae.get();
        this.pa   =  mmu_registers.mmu_tel.pa.get();
        this.cp   =  mmu_registers.mmu_tel.cp.get();
        this.es   =  mmu_registers.mmu_tel.es.get();

   //     this.e       = mmu_registers.mmu_mmc.e.get();
        this.idx     = mmu_registers.mmu_mmc.idx.get();
   /*     this.ptc     = mmu_registers.mmu_mmc.ptc.get();
        this.spe     = mmu_registers.mmu_mmc.spe.get();
        this.sne     = mmu_registers.mmu_mmc.sne.get();
        this.lps     = mmu_registers.mmu_mmc.lps.get();
        this.dps     = mmu_registers.mmu_mmc.dps.get();
        this.s_mmc   = mmu_registers.mmu_mmc.s.get();*/
        this.asn_mmc = mmu_registers.mmu_mmc.asn.get();    

        this.mmc  =   mmu_registers.mmu_mmc.get();
        this.teh  =   mmu_registers.mmu_teh.get();
        this.tel  =   mmu_registers.mmu_tel.get();
        
    endfunction : reg_to_array      
    
    function void array_to_reg(mmu_reg_blk mmu_registers);
          
        mmu_registers.mmu_teh.pn.set(this.pn);
        mmu_registers.mmu_teh.s.set(this.s);
        mmu_registers.mmu_teh.g.set(this.g);
        mmu_registers.mmu_teh.asn.set(this.asn);
        
        mmu_registers.mmu_tel.fn.set(this.fn);
        mmu_registers.mmu_tel.ae.set(this.ae);
        mmu_registers.mmu_tel.pa.set(this.pa);
        mmu_registers.mmu_tel.cp.set(this.cp);
        mmu_registers.mmu_tel.es.set(this.es);

     //   mmu_registers.mmu_mmc.e.set(this.e);
        mmu_registers.mmu_mmc.idx.set(this.idx);
     /*   mmu_registers.mmu_mmc.ptc.set(this.ptc);
        mmu_registers.mmu_mmc.spe.set(this.spe);
        mmu_registers.mmu_mmc.sne.set(this.sne);
        mmu_registers.mmu_mmc.lps.set(this.lps);
        mmu_registers.mmu_mmc.dps.set(this.dps);
        mmu_registers.mmu_mmc.s.set(this.s_mmc);
        mmu_registers.mmu_mmc.asn.set(this.asn_mmc);
       */
    endfunction : array_to_reg

    function string print();
        return $psprintf("PN= 'h%0X, S= %0d, G= %0d, ASN= 'h%0X, FN= 'h%0X, AE= %0d, PA= %0d, CP= %0d, ES= %0d", pn, s, g, asn, fn, ae, pa, cp, es);
    endfunction     
        
endclass: tlb_c


`endif

