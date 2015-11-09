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
`ifndef DMA_CLUSTER_TESTS
`define DMA_CLUSTER_TESTS

`include "mmucfg_master_seq_lib.sv"
`include "mmu_proc_sfrwrites_master_seq_lib.sv"
`include "mmu_proc_sfrreads_master_seq_lib.sv"
`include "tb_mmu_registers.sv"
`include "tb_mmu_coverage.sv"
`include "tb_mmu_refmodel.sv"
`include "mmu_proc_tlbmaintenance_master_seq_lib.sv"
`include "mmu_proc_dcache_master_seq_lib.sv"
`include "mmu_dcache_slave_seq_lib.sv"
virtual class mppa_proc_mmu_tests extends uvm_test;
	`uvm_component_param_utils(mppa_proc_mmu_tests)

	typedef mmucfg_env mmucfg_env_t;
	typedef mmu_proc_sfrwrites_env mmu_proc_sfrwrites_env_t;
	typedef mmu_proc_sfrreads_env mmu_proc_sfrreads_env_t;
    typedef mmu_proc_tlbmaintenance_env mmu_proc_tlbmaintenance_env_t;
    typedef mmu_proc_dcache_env mmu_proc_dcache_env_t;
    typedef mmu_dcache_env mmu_dcache_env_t;
   
	mmucfg_env_t mmucfg;
    mmu_proc_sfrwrites_env_t mmu_proc_sfrwrites;
    mmu_proc_sfrreads_env_t mmu_proc_sfrreads;
    mmu_proc_tlbmaintenance_env_t mmu_proc_tlbmaintenance;
    mmu_proc_dcache_env_t mmu_proc_dcache;
    mmu_dcache_env_t mmu_dcache;
    
    tb_mmu_refmodel mmu_refmodel;
   
	uvm_table_printer printer;

    //Declaration the parameters for test
    string reg_name;
   
    int available_tlb[$] = {/*JTLB*/0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,/*LTLB*/256, 257, 258, 259, 260, 261, 262, 263};
    
   int  no_available_tlb[$] = {128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255};
    
    int available_valid_page_nb[$];
    int available_not_valid_page_nb[$];
    int unsigned min_page_address[int];
    int unsigned max_page_address[int];
    int   used_tlbs_nb[$];
    
    longint unsigned virt_address_jtlb[$];
    
    typedef enum longint unsigned {FOUR_K=2**12,EIGHT_K=2**13,SIXTEEN_K=2**14,THIRTY_TWO_K=2**15,SIXTY_FOUR_K=2**16,OTHERS_RANDOM_K} size_tlb_t;
    typedef enum {TRAP_ALL, TRAP_WTC, TRAP_ATC, TRAP_PROTECT, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP } exception_t;
    typedef enum {NO_TRAP, FEW_TRAP, FULL_TRAP} trap_t;
    typedef enum {GLOBAL_ONE,GLOBAL_ZERO,GLOBAL_RANDOM } global_mode_t;
    typedef enum {ALIGNED,NO_ALIGNED,ALIGNED_RANDOM} aligned_mode_t;
    typedef enum {PROGRAM_LTLB,PROGRAM_JTLB,PROGRAM_VIDE_TLB,PROGRAM_TLB_RANDOM} program_tlb_mode_t;
    typedef enum {TLB_MAINTENANCE_DISABLE,TLB_WRITE_MODE,TLB_READ_MODE,TLB_PROBE_MODE,LTLB_INDEX_MODE,JTLB_INDEX_MODE,CHECK_TLB_WRITE_CODE,TLB_MAINTENANCE_MODE_RANDOM} tlb_mantenance_mode_t;
    size_tlb_t size_ltlb;
    size_tlb_t small_size_jtlb;
    size_tlb_t large_size_jtlb;
    program_tlb_mode_t program_tlb_mode;
   

    
	mmucfg_configure   configure_seq;
	sfrwrites_seq      sfrwrites_sequence;
	sfrreads_seq       sfrreads_sequence;
    tlbmaintenance_seq tlbmaintenance_sequence;
    proc_dcache_seq    proc_dcache_sequence;
    mmu_dcache_slave_seq_default mmu_dcache_default_slave_seq;
    
   
    
	function new(string name = "mppa_proc_mmu_tests", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
	   super.build_phase(phase);
	   //build environment
	   
	   // Configure MMUCFG VIPs
	   mmucfg = mmucfg_env_t::type_id::create("mmucfg", this);
	   uvm_config_db#(int)::set(this,"mmucfg", "vip_is_master",  1);
 	   uvm_config_db#(string)::set(this,"mmucfg", "v_name", "MMUCFG");
	   
	   // Configure MMU_PROC_SFR_WR VIPs
	   mmu_proc_sfrwrites = mmu_proc_sfrwrites_env_t::type_id::create("mmu_proc_sfrwrites", this);
	   uvm_config_db#(int)::set(this,"mmu_proc_sfrwrites", "vip_is_master",  1);
	   uvm_config_db#(string)::set(this,"mmu_proc_sfrwrites", "v_name", "MMU_SFR_WRITE");

	   // Configure MMU_PROC_SFR_READ VIPs
	   mmu_proc_sfrreads = mmu_proc_sfrreads_env_t::type_id::create("mmu_proc_sfrreads", this);
	   uvm_config_db#(int)::set(this,"mmu_proc_sfrreads", "vip_is_master",  1);
	   uvm_config_db#(string)::set(this,"mmu_proc_sfrreads", "v_name", "MMU_SFR_READ");

       // Configure MMU_PROC_TLB_MAINTENANCE VIPs
	   mmu_proc_tlbmaintenance = mmu_proc_tlbmaintenance_env_t::type_id::create("mmu_proc_tlbmaintenance", this);
	   uvm_config_db#(int)::set(this,"mmu_proc_tlbmaintenance", "vip_is_master",  1);
	   uvm_config_db#(string)::set(this,"mmu_proc_tlbmaintenance", "v_name", "MMU_TLB_MAINTENANCE");
        
       //configure MMU_PROC_DCACHE VIPs
       mmu_proc_dcache = mmu_proc_dcache_env_t::type_id::create("mmu_proc_dcache", this);
	   uvm_config_db#(int)::set(this,"mmu_proc_dcache", "vip_is_master",  1);
	   uvm_config_db#(string)::set(this,"mmu_proc_dcache", "v_name", "MMU_PROC_DCACHE");
        
       //configure MMU_DCACHE VIPs
       mmu_dcache = mmu_dcache_env_t::type_id::create("mmu_dcache", this);
	   uvm_config_db#(int)::set(this,"mmu_dcache", "vip_is_master",  0);
	   uvm_config_db#(string)::set(this,"mmu_dcache", "v_name", "MMU_DCACHE");
        
       // Configure MMU_REFMODEL
       mmu_refmodel = tb_mmu_refmodel::type_id::create("mmu_refmodel", this);
        
	   printer = new();
	   printer.knobs.depth = 3;
	endfunction : build_phase

	virtual function void end_of_elaboration();
	    super.end_of_elaboration();

	endfunction : end_of_elaboration

	function void connect();
		super.connect();
		//Connect interfaces
		mmucfg.assign_vi(tb_mppa_proc_mmu.mmucfg_intf);
		mmu_proc_sfrwrites.assign_vi(tb_mppa_proc_mmu.mmu_proc_sfrwrites_intf);
	    mmu_proc_sfrreads.assign_vi(tb_mppa_proc_mmu.mmu_proc_sfrreads_intf);
        mmu_proc_tlbmaintenance.assign_vi(tb_mppa_proc_mmu.mmu_proc_tlbmaintenance_intf);
        mmu_proc_dcache.assign_vi(tb_mppa_proc_mmu.mmu_proc_dcache_intf);
        mmu_dcache.assign_vi(tb_mppa_proc_mmu.mmu_dcache_intf);

        mmu_refmodel.assign_vi(tb_mppa_proc_mmu.mmucfg_intf, tb_mppa_proc_mmu.mmu_proc_sfrwrites_intf, tb_mppa_proc_mmu.mmu_proc_sfrreads_intf,tb_mppa_proc_mmu.mmu_proc_tlbmaintenance_intf,tb_mppa_proc_mmu.mmu_proc_dcache_intf,tb_mppa_proc_mmu.mmu_dcache_intf);
	   
	endfunction : connect

	task StandbyMasters();
		// MMUCFG in standby
	   mmucfg.master.sequencer.count = 0;
	   mmu_proc_sfrwrites.master.sequencer.count = 0;
	   mmu_proc_sfrreads.master.sequencer.count = 0;
	   mmu_proc_tlbmaintenance.master.sequencer.count = 0;
       mmu_proc_dcache.master.sequencer.count = 0;
       mmu_dcache.master.sequencer.count = 0;
        
	endtask : StandbyMasters
    
/************************ Program_TLB *********************************************/
    
    task Program_TLB( mmu_mmc_reg mmu_mmc, mmu_teh_reg mmu_teh,mmu_tel_reg mmu_tel);
        
      int unsigned  mmc,tel,teh;
        
        
        mmc = mmu_mmc.get();
        teh = mmu_teh.get();
        tel = mmu_tel.get();
        
        sfrwrites_sequence = sfrwrites_seq::type_id::create($psprintf("sfrwrites_sequence"));        
		mmu_proc_sfrwrites.master.sequencer.count = 1;        
		sfrwrites_sequence.v_name = "MMU_SFR_WRITE";
	    sfrwrites_sequence.lreq_lat = $urandom_range(5,10);
	    sfrwrites_sequence.lcmd = SET;
	    sfrwrites_sequence.sfr_name = MMC;    
	    sfrwrites_sequence.lcpu_wr_reg_val_i = mmc;
		sfrwrites_sequence.start(mmu_proc_sfrwrites.master.sequencer); 
     
        sfrwrites_sequence = sfrwrites_seq::type_id::create($psprintf("sfrwrites_sequence"));      
		mmu_proc_sfrwrites.master.sequencer.count = 1;      
		sfrwrites_sequence.v_name = "MMU_SFR_WRITE";      
	    sfrwrites_sequence.lreq_lat = $urandom_range(5,10);     
	    sfrwrites_sequence.lcmd = SET;
	    sfrwrites_sequence.sfr_name = TEH;           
	    sfrwrites_sequence.lcpu_wr_reg_val_i = teh;
		sfrwrites_sequence.start(mmu_proc_sfrwrites.master.sequencer);
 	
        sfrwrites_sequence = sfrwrites_seq::type_id::create($psprintf("sfrwrites_sequence"));   
		mmu_proc_sfrwrites.master.sequencer.count = 1;
		sfrwrites_sequence.v_name = "MMU_SFR_WRITE";
	    sfrwrites_sequence.lreq_lat = $urandom_range(5,10);
	    sfrwrites_sequence.lcmd = SET;
	    sfrwrites_sequence.sfr_name = TEL;     
	    sfrwrites_sequence.lcpu_wr_reg_val_i = tel; 
		sfrwrites_sequence.start(mmu_proc_sfrwrites.master.sequencer);
      
        
    endtask : Program_TLB


    function void PN_Page_Size_Management( size_tlb_t size_tlb, longint unsigned page_size_tlb ,logic [19:0] pn_full,output logic [19:0] pn);
        
        case(size_tlb)
          
          FOUR_K : begin             
              pn = pn_full;
          end
          EIGHT_K : begin
              pn_full[0] = 0;
              pn = pn_full + 1;
          end
          SIXTEEN_K : begin
              pn_full[1:0] = 0;
              pn = pn_full + 2;
          end 
          THIRTY_TWO_K : begin
              pn_full[2:0] = 0;
              pn = pn_full + 4;
          end
          SIXTY_FOUR_K : begin
              pn_full[3:0] = 0;
              pn = pn_full + 8;
          end
          OTHERS_RANDOM_K : begin          
            int unsigned no_usefull_bit;
              if(page_size_tlb == 2**12)begin
                  pn = pn_full;
              end
              else begin             
                  no_usefull_bit_PN_management( page_size_tlb, no_usefull_bit);           
                  pn_full = pn_full >> (no_usefull_bit - 1) ;           
                  pn_full[0] = 1;          
                  pn_full = pn_full << (no_usefull_bit - 1);            
                  pn = pn_full; 
              end
              
          end
        endcase 
        
    endfunction : PN_Page_Size_Management


    
/************************* Generate the continuous or no continuouse pages ************************************/
    
    function void no_multi_map_pn(size_tlb_t size_tlb,program_tlb_mode_t  program_tlb_mode, int idx, int check_mmc_e_mode, longint unsigned page_size_ltlb,longint unsigned small_size_jtlb,longint unsigned large_size_jtlb,  output logic [19:0] pn, output int next_is_used, output int prev_is_used, output int no_found_available_pn_zone_flag);
        int val;
        int id, count, i, continu_address_mode = 0;
        int no_usefull_bit;
        logic [19:0] pn_full;
        logic [19:0] pn_jtlb;
        longint unsigned page_size_tlb;
        longint unsigned four_k = (2**12); //Page 4K
    
        next_is_used = 0;
        prev_is_used = 0;

       
    
        if(program_tlb_mode == PROGRAM_LTLB)begin
            page_size_tlb = page_size_ltlb;
        end
        else if(program_tlb_mode == PROGRAM_VIDE_TLB)begin
            page_size_tlb = page_size_ltlb;
        end
        else begin 
            if(idx[0] == 0)
              page_size_tlb = small_size_jtlb;
            else
              page_size_tlb = large_size_jtlb;
        end
      
        val = $urandom_range(0,99);
         $display("GG:PN-1:%0X idx:%0d page_size_tlb:%0d small_size_jtlb:%0d large_size_jtlb:%0d",pn,idx,page_size_tlb,small_size_jtlb,large_size_jtlb);
       //  $display("GG:page_size_tlb_string:%s page_size_tlb:%0d val:%0d",size_tlb,page_size_tlb, val);
        // 50% not continuous pages 
        if ((val < 100) || (used_tlbs_nb.size() == 0) /*|| (program_tlb_mode == PROGRAM_JTLB )*/)begin
            continu_address_mode = 0;
            pn_full = (page_size_tlb/2**12) * ($urandom_range(0,2**32/page_size_tlb -1));
              $display("GG:PN1:%0X",pn_full);
                                                   
        end
       
        // 50% continuous pages OK
        else begin  // For now , not use the code because it is completed for generating continues page 
            continu_address_mode = 1;                     
            val =$urandom_range(0, used_tlbs_nb.size() -1);       
            id = used_tlbs_nb[val];
            count = 0;
            
            while (mmu_refmodel.tlb_array[id].next_page_is_used == 1 && mmu_refmodel.tlb_array[id].previous_page_is_used == 1) begin
                val+=1;
                count+=1;
                if (val == used_tlbs_nb.size)
                  val = 0;
                if (count == used_tlbs_nb.size) 
                  break;
                id = used_tlbs_nb[val];
              
            end
            if (count == used_tlbs_nb.size) begin
                continu_address_mode = 0;
                // not continuous pages => no other choice
                pn_full = (page_size_tlb/2**12) * ($urandom_range(0,2**32/page_size_tlb -1));
                                
            end
            else begin
                if (mmu_refmodel.tlb_array[id].next_page_is_used == 0) begin
                    
                    pn_full = mmu_refmodel.tlb_array[id].last_line_addr_of_page + 1;
                    mmu_refmodel.tlb_array[id].next_page_is_used = 1;
                    prev_is_used = 1;  
                   
                end               
                else begin
                    pn_full = mmu_refmodel.tlb_array[id].pn - page_size_tlb/four_k;
                    mmu_refmodel.tlb_array[id].previous_page_is_used = 1;
                    next_is_used = 1; 
                   
                end               
            end 
            
            if(pn_full == 0)
              prev_is_used = 1;
            else if (pn_full == ((2**32)-1))
              next_is_used = 1;
        end 
         $display("GG:PN2:%0X page_size_tlb:%0d",pn_full,page_size_tlb);
        // Calculation the written pn with the page size
        if(check_mmc_e_mode == 0)begin
            PN_Page_Size_Management(size_tlb, page_size_tlb, pn_full, pn);
             $display("GG:PN3:%0X page_size_tlb:%0d",pn_full,page_size_tlb);
            
            if( program_tlb_mode == PROGRAM_JTLB)begin         
                PN_Idx_JTLB_Management(size_tlb,idx/2, pn,  page_size_tlb, pn_jtlb);
                pn = pn_jtlb;
                 $display("GG:PN4:%0X page_size_tlb:%0d",pn_full,page_size_tlb);
            end
        end  
        else begin
            pn = $urandom_range(0,2**20-1);         
        end 
          $display("GG:PN5:%0X page_size_tlb:%0d",pn_full,page_size_tlb);
            no_usefull_bit_PN_management( page_size_tlb, no_usefull_bit);
      //  $display("GG:PN1:%0X",pn);
/********************* The first check the pn used a same pn or not ***************/
       
        if(continu_address_mode == 0)begin 
          longint unsigned count,count_limit,count1;
            for(int t= 0; t<(used_tlbs_nb.size);t++)begin                      
              int     flag ;            
              logic [19:0] pn_temp;
              logic [19:0] pn_temp_i;
              
                flag = 0;
                if(check_mmc_e_mode == 0)begin
                    pn_temp = pn;
                    pn_temp = (( pn_temp >> no_usefull_bit) << no_usefull_bit);
                end
                else begin
                    pn_temp = pn;
                end
                pn_temp_i = mmu_refmodel.tlb_array[used_tlbs_nb[t]].pn;
                pn_temp_i = (( pn_temp_i >> mmu_refmodel.tlb_array[used_tlbs_nb[t]].no_usefull_bit) << mmu_refmodel.tlb_array[used_tlbs_nb[t]].no_usefull_bit);
           
                while(((pn_temp > pn_temp_i ) && ((pn_temp + page_size_tlb/four_k) < (pn_temp_i + mmu_refmodel.tlb_array[used_tlbs_nb[t]].page_size/four_k - 1)))
                    
                      || (((pn_temp +  page_size_tlb/four_k - 1 ) > pn_temp_i ) && ((pn_temp +  page_size_tlb/four_k - 1 ) < (pn_temp_i + 
                         mmu_refmodel.tlb_array[used_tlbs_nb[t]].page_size/four_k - 1))) 
                      || ((pn_temp > pn_temp_i ) && ( pn_temp < (pn_temp_i + mmu_refmodel.tlb_array[used_tlbs_nb[t]].page_size/four_k - 1)))

                      || (pn_temp == pn_temp_i)
                      || (pn_temp == (pn_temp_i + mmu_refmodel.tlb_array[used_tlbs_nb[t]].page_size/four_k - 1))

                      || ((pn_temp +  page_size_tlb/four_k - 1) == pn_temp_i)
                      || ((pn_temp +  page_size_tlb/four_k - 1) == (pn_temp_i + mmu_refmodel.tlb_array[used_tlbs_nb[t]].page_size/four_k - 1))
                    
                      || (( pn_temp <= pn_temp_i) && (( pn_temp + page_size_tlb/four_k - 1) >= (pn_temp_i + mmu_refmodel.tlb_array[used_tlbs_nb[t]].page_size/four_k - 1))))begin  

                    
                    pn_full = (page_size_tlb/2**12) * ($urandom_range(0,2**32/page_size_tlb -1));
                    
                    if(check_mmc_e_mode == 0)begin
                        PN_Page_Size_Management( size_tlb, page_size_tlb ,pn_full, pn);
                        
                        if( program_tlb_mode == PROGRAM_JTLB)begin
                            PN_Idx_JTLB_Management(size_tlb,idx/2, pn,  page_size_tlb, pn_jtlb);
                            pn = pn_jtlb;
                        end
                    end
                    else begin
                        pn = $urandom_range(0,2**20-1);      
                    end 
                    if(check_mmc_e_mode == 0)begin
                        pn_temp = pn;
                        pn_temp = (( pn_temp >> no_usefull_bit) << no_usefull_bit);
                    end
                    else begin
                        pn_temp = pn;
                    end
                    pn_temp_i = mmu_refmodel.tlb_array[used_tlbs_nb[t]].pn;
                    pn_temp_i = (( pn_temp_i >> mmu_refmodel.tlb_array[used_tlbs_nb[t]].no_usefull_bit) << mmu_refmodel.tlb_array[used_tlbs_nb[t]].no_usefull_bit);
                    flag = 1;
                    count1++;
                    if(count1 == 10000)begin
                        no_found_available_pn_zone_flag = 1;
                        break;                        
                    end
                end 
                if(flag == 1)begin
                    t= -1;                
                end
                
                if(no_found_available_pn_zone_flag == 1)begin
                    
                    // `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU TEST]: All PN are used, can not find available pn for TLB[%0d]",$time,idx));
                    break;
                end
            end
        end 
        
        
    endfunction : no_multi_map_pn

    
/**************************** Generate the virtual address who can be continuous in the interesting l1,l2,l3 *************/
    
    function longint unsigned generate_virt_addr(longint unsigned start_addr, longint unsigned end_addr, longint unsigned page_size, int l3_is_en);
      longint     cur_addr = start_addr;
      longint     interesting_addr_l1[$];
      longint     interesting_addr_l2[$];
      longint     interesting_addr_l3[$];
      int         rate;
      longint     cur_addr_l;
      
        while (cur_addr < end_addr) begin
            // First line of 64 bytes
            for(int i=0; i<64; i++) begin                 
                interesting_addr_l1 = {interesting_addr_l1,cur_addr+i};               
            end
                                   
            if(page_size == 0)
              `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU TEST]: The page size can not be 0 when it generates a virtual address ",$time));
            // 64 bytes before
            for(int i=0; i<64; i++) begin
                
                if((end_addr == 2**32) && (l3_is_en == 1))begin
                    interesting_addr_l3 = {interesting_addr_l3,end_addr + i - 63};                    
                end                  
                else begin
                    interesting_addr_l2 = {interesting_addr_l2,end_addr + i - 63};                           
                end
                
            end
            break;
        end 
        
            
        rate = $urandom_range(0,99);
        //If the end adresss is 2**32, test the interesting addr l3
        if((end_addr == 2**32) && (l3_is_en == 1))begin
            cur_addr_l = interesting_addr_l3[$urandom_range(0,interesting_addr_l3.size -1)];   
            if(!(cur_addr_l <= end_addr) && (cur_addr_l >= start_addr))
              `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU TEST]: The generated virtual address of the intresting space 3 must between the start addr and end addr ",$time));
            return(cur_addr_l);
        end
        else if (rate < 30) begin 
            // address in priority 0 space
            cur_addr_l = $urandom_range(start_addr, end_addr);
            if(!(cur_addr_l <= end_addr) && (cur_addr_l >= start_addr))
              `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU TEST]: The generated virtual address of the 0 space must between the start addr and end addr ",$time));
            return(cur_addr_l);
        end
        else begin
            
            if(rate < 65)begin
                cur_addr_l = interesting_addr_l2[$urandom_range(0,interesting_addr_l2.size -1)];  
                if(!(cur_addr_l <= end_addr) && (cur_addr_l >= start_addr))
                  `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU TEST]: The generated virtual address of the intresting space 2 must between the start addr and end addr ",$time));  
            end
            else begin
                cur_addr_l = interesting_addr_l1[$urandom_range(0,interesting_addr_l1.size -1)];
                if(!(cur_addr_l <= end_addr) && (cur_addr_l >= start_addr))
                  `uvm_fatal(get_type_name(), $psprintf("[%0d]: [MMU TEST]: The generated virtual address of the intresting space 1 must between the start addr and end addr ",$time));            
            end
            
            return(cur_addr_l);                          
        end 
        
    endfunction :  generate_virt_addr
    
  
    
    //Generate the perlission RD allowed and WR allowed with the PA
    function void extract_permission(int priviledge_mode_random, int pa, output int rd_allowed, output int wr_allowed);
        rd_allowed = 0;
        wr_allowed = 0;
        if (priviledge_mode_random == 0) begin
            if (pa >= 5 && pa < 14)
              rd_allowed = 1;
            if (pa == 9 || pa == 10 || pa == 13)
              wr_allowed = 1;
        end
        else begin
            if (pa >= 1 && pa < 14)
              rd_allowed = 1;
            if (pa == 2 || pa == 4 || pa == 4 || pa == 8 || pa == 9 || pa == 12 || pa == 13)
              wr_allowed = 1;
        end
    endfunction :  extract_permission

    function void no_valid_pn_random(size_tlb_t size_tlb,output logic [19:0] rnd_pn,output longint unsigned page_size_tlb ,output int no_usefull_bit);
        
        if(size_tlb == OTHERS_RANDOM_K)begin
            page_size_tlb = 2**12; // For now, decide it 4K , must change later
        end
        else begin
            page_size_tlb = size_tlb;
        end
        
        rnd_pn = $urandom_range(1000, ((2**32)/page_size_tlb -1));
        if(page_size_tlb == 0)
          `uvm_fatal(get_type_name(), $psprintf("Page Size TLB should not be 0"));
        
        no_usefull_bit_PN_management(page_size_tlb, no_usefull_bit);
        $display("GG:page_size_tlb:%0d no_usefull_bit:%0d  rnd_pn:%0X",page_size_tlb,no_usefull_bit,rnd_pn);
    endfunction : no_valid_pn_random

    
    function void no_usefull_bit_PN_management(longint unsigned page_size_tlb, output int no_usefull_bit);
      longint unsigned page_size_temp; 
      int     count = 0;     
        page_size_temp  =  page_size_tlb; 
        $display("GG:page_size_tlb2:%0d",page_size_tlb);
        while(page_size_temp != 2**12)begin
           // $display("GG:page_size_tlb:%0d",page_size_tlb);
            page_size_temp = page_size_temp/2;
            count++; 
        end
        
        no_usefull_bit = count;
        
        count = 0;
        
    endfunction : no_usefull_bit_PN_management

    
    function void PN_Idx_JTLB_Management(size_tlb_t page_size, int idx, int pn, longint unsigned page_size_tlb, output logic [19:0] pn_jtlb);
        
      logic [19:0] pn_no_usefull ;
      logic [19:0] pn_temp ;
      int          no_usefull_bit;
        pn_temp = pn;
        pn_no_usefull = pn;
        
        case(page_size)
          
          FOUR_K : begin 
              pn_temp[5:0] = idx; 
              pn_jtlb = pn_temp;
          end   
          EIGHT_K : begin   
              pn_temp[6:1] = idx;
              pn_jtlb = pn_temp;
              
          end   
          SIXTEEN_K : begin 
              pn_temp[7:2] = idx;
              pn_jtlb = pn_temp;            
          end
          THIRTY_TWO_K : begin 
              pn_temp[8:3] = idx;
              pn_jtlb = pn_temp;
          end
          SIXTY_FOUR_K : begin 
              pn_temp[9:4] = idx;
              pn_jtlb = pn_temp;
          end
          OTHERS_RANDOM_K : begin
              no_usefull_bit_PN_management( page_size_tlb, no_usefull_bit); 
              pn_no_usefull = pn_no_usefull << (20 - no_usefull_bit);   
              pn_no_usefull = pn_no_usefull >> (20 - no_usefull_bit);  
              pn_temp = pn_temp >> no_usefull_bit;  
              pn_temp[5:0] = idx;  
              pn_temp = pn_temp << no_usefull_bit;
              pn_temp = pn_temp  + pn_no_usefull;  
              pn_jtlb =  pn_temp;
              
          end
          
        endcase 
    endfunction : PN_Idx_JTLB_Management

    
    function void JTLB_Page_Size_Management(size_tlb_t small_page_size_dps,size_tlb_t large_page_size_lps, output int dps, output int lps,  output int unsigned small_page_size_jtlb,
                                            output int unsigned large_page_size_jtlb);
        
      int unsigned page_size_temp;
      int unsigned lps_count= 0;
       
        case(small_page_size_dps)
          
          FOUR_K : begin 
              small_page_size_jtlb = small_page_size_dps;              
              dps = 0;
          end   
          EIGHT_K : begin
             
              small_page_size_jtlb = small_page_size_dps;            
              dps = 1;
               $display("small_page_size_jtlb:%0d",small_page_size_jtlb);
          end   
          SIXTEEN_K : begin 
              small_page_size_jtlb = small_page_size_dps;              
              dps = 2;
          end
          THIRTY_TWO_K : begin 
              small_page_size_jtlb = small_page_size_dps;              
              dps = 3;
          end
          SIXTY_FOUR_K : begin 
              small_page_size_jtlb = small_page_size_dps;              
              dps = 4;
          end
          OTHERS_RANDOM_K : begin
            int dps_random = $urandom_range(0,15);             
              small_page_size_jtlb = 4096*(2**dps_random); //128K -- 4M
              dps = dps_random; // dps has 4 bits
          end
          
        endcase 
        
        case(large_page_size_lps)// large_page_size_lps is the input parameter of the function
                                 // large_page_size_jtlb is the final value after calculation
          
          FOUR_K : begin 
              large_page_size_jtlb = large_page_size_lps;
              page_size_temp = large_page_size_jtlb;                
              while(page_size_temp !== small_page_size_jtlb)begin
                  page_size_temp = page_size_temp/2;
                  lps_count++;                    
              end
              lps = lps_count;
              lps_count = 0;
          end   
          EIGHT_K : begin   
              large_page_size_jtlb = large_page_size_lps;   
              page_size_temp = large_page_size_jtlb;                                      
              while(page_size_temp !== small_page_size_jtlb)begin
                  page_size_temp = page_size_temp/2;
                  lps_count++;                    
              end
              lps = lps_count; 
              lps_count = 0;
          end   
          SIXTEEN_K : begin              
              large_page_size_jtlb = large_page_size_lps; 
              page_size_temp = large_page_size_jtlb;                                      
              while(page_size_temp !== small_page_size_jtlb)begin
                  $display("GG:small_page_size_dps:%0d large_page_size_lps:%0d",small_page_size_dps,large_page_size_lps);
                  page_size_temp = page_size_temp/2;
                  lps_count++;                    
              end
              lps = lps_count;
              lps_count = 0;
          end
          THIRTY_TWO_K : begin 
              large_page_size_jtlb = large_page_size_lps;  
              page_size_temp = large_page_size_jtlb;                                       
              while(page_size_temp !== small_page_size_jtlb)begin
                  page_size_temp = page_size_temp/2;
                  lps_count++;                    
              end
              lps = lps_count;
              lps_count = 0;
          end
          SIXTY_FOUR_K : begin 
              large_page_size_jtlb = large_page_size_lps;  
              page_size_temp = large_page_size_jtlb;                                       
              while(page_size_temp !== small_page_size_jtlb)begin
                  page_size_temp = page_size_temp/2;
                  lps_count++;                    
              end
              lps = lps_count;
              lps_count = 0;
          end
          OTHERS_RANDOM_K : begin
            int lps_random = $urandom_range(0,15); //4K to 2G 
              if(small_page_size_jtlb == 2**12)
                lps_random = 0;           
              large_page_size_jtlb = small_page_size_jtlb*(2**lps_random);              
           
              while((small_page_size_jtlb > large_page_size_jtlb) || (large_page_size_jtlb > 2**31))begin
                  lps_random = $urandom_range(0,15);
                  large_page_size_jtlb = small_page_size_jtlb*(2**lps_random); 
              end
 
              page_size_temp  = large_page_size_jtlb;
             
              if(small_page_size_jtlb > large_page_size_jtlb)
                `uvm_fatal(get_type_name(), $psprintf("The large page size JTLB[%0d] must be less than the small one[%0d]",large_page_size_jtlb, small_page_size_jtlb));

              while(page_size_temp !== small_page_size_jtlb)begin
                  page_size_temp = page_size_temp/2;
                  lps_count++;                    
              end
              lps = lps_count;
              lps_count = 0;
          end
          
        endcase

        
    endfunction : JTLB_Page_Size_Management


    
    task  Program_Many_TLBs(int number_tlb,size_tlb_t page_size_ltlb_s, size_tlb_t small_page_size_dps,size_tlb_t large_page_size_lps, global_mode_t global_mode_value,int check_mmc_error_mode, int no_mapping_en, int multi_mapping_en, int priviledge_mode, trap_t trap, int simple_case_en,tlb_mantenance_mode_t tlb_mantenance_mode[$]);
      int unsigned idx, idx_pn, idx_last, idx_available, idx_no_available,idx_lrw;
      logic [19:0] fn;
      logic [19:0] pn;
      int unsigned nomapping_choice;    
      int unsigned val_index;  
      int unsigned val, next_is_used, prev_is_used;  
      int unsigned global_mode, asn_random;  
      int unsigned rate, no_trap_condition;
      int unsigned lps, dps;
      int unsigned sne, spe;
      int unsigned ptc;
      int unsigned no_found_available_pn_zone_flag,no_found_available_pn_zone_flag_temp;
      int unsigned no_found_available_idx_flag;
      longint unsigned page_size_ltlb;
      longint unsigned small_page_size_jtlb;
      longint unsigned large_page_size_jtlb;   
      longint unsigned page_size_tlb;
      longint unsigned virt_address;
      int     unsigned check_mmc_e_mode;
      int     unsigned big_size_page_mode;
        program_tlb_mode_t program_tlb_mode;
        size_tlb_t  page_size_tlb_string;
        tlb_mantenance_mode_t ltlb_mantenance_mode;
       
        mmu_mmc_reg        mmu_mmc;
        mmu_tel_reg        mmu_tel;
        mmu_teh_reg        mmu_teh;
        
    
        mmu_mmc = new;
        mmu_mmc.build();
        mmu_tel = new;
        mmu_tel.build();
        mmu_teh = new;
        mmu_teh.build();

        ltlb_mantenance_mode = tlb_mantenance_mode[$urandom_range(0, (tlb_mantenance_mode.size -1))];
       
        
        //Choose the un page random // 128K to 4M for now 
        if(page_size_ltlb_s == OTHERS_RANDOM_K)begin
            
          longint unsigned page_size_random;
          int     page_range;
            page_range = $urandom_range(0,19); // from 4k to 2G  
            //page_range =19;             
            page_size_random = 4096*(2**page_range);
            page_size_ltlb  =  page_size_random;                      
        end 
        else begin
            page_size_ltlb = page_size_ltlb_s;
        end
        
        //Calculation of the LPS and DPS 
        JTLB_Page_Size_Management(small_page_size_dps,large_page_size_lps, dps, lps, small_page_size_jtlb, large_page_size_jtlb);
        $display("GG:Page small1:%0d large:%0d",small_page_size_jtlb,large_page_size_jtlb);
        //Calculation the big Pages 2**27--2**31
        if(dps == 15)begin // Because there are just 5 bits(32) to put the idx in the jtlb
            big_size_page_mode = 1;
            check_mmc_error_mode = 0;            
        end
        //It is for the ASN in the Global mode 0
        asn_random = $urandom_range(0,512);
        sne = $urandom_range(0,1);
        spe = $urandom_range(0,1);
        
        //For global mode 
        if(global_mode_value == GLOBAL_ZERO)begin
            global_mode = 0;                                    
        end
        if(global_mode_value == GLOBAL_ONE)begin
            global_mode = 1;              
        end
        if(global_mode_value == GLOBAL_RANDOM)begin
            global_mode = $urandom_range(0,1);            
        end
        
        if(ltlb_mantenance_mode == LTLB_INDEX_MODE)begin
          int rate;
            rate=$urandom_range(0,100);
            if(rate > 50)begin
                number_tlb = 50;
            end
            else begin
                number_tlb = 136;
            end         
        end
        
        if (number_tlb > 136)
          `uvm_fatal(get_type_name(), $psprintf("Try to use %0d pages but only 136 pages are available in LTLB", number_tlb));

        available_valid_page_nb = {};

        ptc = $urandom_range(0,3);
        no_found_available_pn_zone_flag = 0;

        // Choose a tlb for setting the last ltlb  
        if(ltlb_mantenance_mode != TLB_READ_MODE)begin      
            idx_available=$urandom_range(128,available_tlb.size - 1);
            idx_last = available_tlb[idx_available];  
            available_tlb.delete(idx_available);
        end
        if(ltlb_mantenance_mode != TLB_WRITE_MODE)begin
            check_mmc_error_mode = 0;
        end
      
/*------------ Cycle for writing the TLB --------------------*/
        for(int n=number_tlb -1; n>0;n--)begin
          int  no_usefull_bit = 0;

            //Ensure the error is not 1 for the last write TLB 
            if(n < 10 || (n < 134 && (page_size_ltlb > 2**29 || large_page_size_jtlb > 2**29 || dps == 15)))begin
                big_size_page_mode = 1;
                check_mmc_error_mode = 0;
               // global_mode = 1;
            end
            //Choose the mmc_error_mode
            if(check_mmc_error_mode ==1)begin
              int value = $urandom_range(0,99);
                if(value < 30)begin
                    check_mmc_e_mode = 1;                
                end
                else begin
                    check_mmc_e_mode = 0;
                end
            end
            else begin
                check_mmc_e_mode = 0;
            end

            
/************** Here is to control the ratio of the trap ********************/       

            // Ensure there are always some TLBs without trap condition
            rate = $urandom_range(0,99);
            if(trap == NO_TRAP)begin         
                no_trap_condition = 1;              
            end
            if(trap == FEW_TRAP)begin         
                if (rate < 70) 
                  no_trap_condition = 1;
                else
                  no_trap_condition = 0;             
            end
            if(trap == FULL_TRAP)begin         
                no_trap_condition = 0;              
            end
         
                                                      
 /********************  Choose TLB IDX **************************/
                                
            //For write not implemented tlb
            if(check_mmc_e_mode == 1)begin // This is for generating the 4/10 trap nomapping
                                    
                nomapping_choice = $urandom_range(0,10);
                if(nomapping_choice > 4)begin
                    
                    idx_available=$urandom_range(0,available_tlb.size - 1);
                    idx = available_tlb[idx_available];
                    
                    available_tlb.delete(idx_available);
                end 
                else begin

                    idx_no_available=$urandom_range(0,no_available_tlb.size - 1);
                    idx = no_available_tlb[idx_no_available];
                    
                    no_available_tlb.delete(idx_no_available);                  
                    
                end    
            end 
            else begin
                             
                idx_available=$urandom_range(0,available_tlb.size - 1);
                idx = available_tlb[idx_available];
                available_tlb.delete(idx_available);
           end
                                 
/******************* Choose the TLB mode dependent on IDX ************/
           // idx = $urandom_range(256,263);
                
            if((idx >= 0) && (idx <= 127))begin
                
                program_tlb_mode = PROGRAM_JTLB;
                
                if(idx[0] == 0)begin
                    if(dps == 15 && idx > 63)begin
                      longint unsigned count;
                        while((idx > 63) || (idx[0] == 1))begin
                            idx_available=$urandom_range(0,available_tlb.size - 1);
                            idx = available_tlb[idx_available];
                            
                            count++;                            
                            if(count == 10000)begin
                                no_found_available_idx_flag = 1;
                                break;                        
                            end                            
                        end
                        
                        if(no_found_available_idx_flag == 1)begin  // No available IDX , so exist the writing TLB                                                    
                            break;
                        end
                        available_tlb.delete(idx_available);
                    end
                    
                    page_size_tlb_string = small_page_size_dps; 
                    page_size_tlb = small_page_size_jtlb;
                end
                else begin
                  longint unsigned count;
                    if(large_page_size_jtlb == 2**27 && idx > 63 )begin
                        
                        while(idx > 63 || idx[0] == 0)begin
                            idx_available=$urandom_range(0,available_tlb.size - 1);
                            idx = available_tlb[idx_available];
                            
                            count++;                            
                            if(count == 10000)begin
                                no_found_available_idx_flag = 1;
                                break;                        
                            end 
                        end
                        available_tlb.delete(idx_available);
                    end
                    else if(large_page_size_jtlb == 2**28 && idx > 31)begin      
                        
                        while(idx > 31 || idx[0] == 0)begin
                            idx_available=$urandom_range(0,available_tlb.size - 1);
                            idx = available_tlb[idx_available];
                            
                            count++;                            
                            if(count == 10000)begin
                                no_found_available_idx_flag = 1;
                                break;                        
                            end 
                        end
                        available_tlb.delete(idx_available);
                    end
                    else if(large_page_size_jtlb == 2**29 && idx > 15)begin
                        
                        while(idx > 15 || idx[0] == 0)begin
                            idx_available=$urandom_range(0,available_tlb.size - 1);
                            idx = available_tlb[idx_available];
                             
                            count++;                            
                            if(count == 10000)begin
                                no_found_available_idx_flag = 1;
                                break;                        
                            end 
                        end
                        available_tlb.delete(idx_available);
                    end
                    else if(large_page_size_jtlb == 2**30 && idx > 7)begin
                        
                        while(idx > 7 || idx[0] == 0)begin
                            idx_available=$urandom_range(0,available_tlb.size - 1);
                            idx = available_tlb[idx_available];
                             
                            count++;                            
                            if(count == 10000)begin
                                no_found_available_idx_flag = 1;
                                break;                        
                            end 
                        end
                        available_tlb.delete(idx_available);
                    end
                    else if(large_page_size_jtlb == 2**31 && idx > 3)begin
                        
                        while(idx > 3 || idx[0] == 0)begin
                            idx_available=$urandom_range(0,available_tlb.size - 1);
                            idx = available_tlb[idx_available];
                            
                            count++;                            
                            if(count == 10000)begin
                                no_found_available_idx_flag = 1;
                                break;                        
                            end 
                        end
                        available_tlb.delete(idx_available);
                    end
                    if(no_found_available_idx_flag == 1)begin                                                      
                        break;
                    end
                    page_size_tlb_string = large_page_size_lps;
                    page_size_tlb = large_page_size_jtlb;
                end
                
            end
            else if((idx >= 128) && (idx <= 255))begin
                program_tlb_mode = PROGRAM_VIDE_TLB;
                page_size_tlb_string = page_size_ltlb_s;
                page_size_tlb = page_size_ltlb;
            end
            else begin
                program_tlb_mode = PROGRAM_LTLB;
                page_size_tlb_string = page_size_ltlb_s;
                page_size_tlb = page_size_ltlb;
            end 
            $display("GG:Page small2:%0d large:%0d",small_page_size_jtlb,large_page_size_jtlb);
 /****** Control the value of Val to change the no mapping cases*********/  
         
            // In the condition Multi Mapping Enable
            if ((multi_mapping_en == 0)) begin 
                no_multi_map_pn(page_size_tlb_string, program_tlb_mode, idx, check_mmc_e_mode, page_size_ltlb, small_page_size_jtlb , large_page_size_jtlb, pn, next_is_used, prev_is_used,no_found_available_pn_zone_flag);
                //Ensure the last write TLB is correct with the 4K size
                if(no_found_available_pn_zone_flag == 1  && check_mmc_error_mode == 1)begin
                    
                    no_found_available_pn_zone_flag_temp = 1;                    
                    page_size_ltlb = 2**12;                    
                    page_size_tlb  = page_size_ltlb;
                    check_mmc_e_mode = 0;
                    
                    program_tlb_mode = PROGRAM_LTLB;                        
                    idx = idx_last;
                    no_multi_map_pn(page_size_tlb_string, program_tlb_mode, idx, check_mmc_e_mode, page_size_ltlb, small_page_size_jtlb , large_page_size_jtlb, pn, next_is_used, prev_is_used,no_found_available_pn_zone_flag);
                    
                end                            
                val = $urandom_range(0,99);
                if(simple_case_en == 1)begin
                  int four_k=2**12;
                    // simple case where phy pages are independente                    
                    fn = ((page_size_tlb/2**12)* ($urandom_range(0,(2**32/page_size_tlb-1))));
               
                end    
                else begin
                    if ((val < 50) && (used_tlbs_nb.size()>0)) begin
                        // reused same fn as existing TLB
                        val_index = $urandom_range(0, used_tlbs_nb.size() -1);
                        fn = mmu_refmodel.tlb_array[used_tlbs_nb[val_index]].fn;                                                                                 
                    end
                    else begin                        
                      // simple case where phy pages are independente                    
                        fn = ((page_size_tlb/2**12)* ($urandom_range(0,(2**32/page_size_tlb-1))));                         
                    end                    
                end                  
            end 
            
            else begin //OK in the mode g=1
                
                // This TLB reuses same pn as an existing one if g == 1
                val = $urandom_range(0,99);
                $display("GG:page_size_tlb5:%0d",page_size_tlb);
                if ((val > 80) && (used_tlbs_nb.size >0) && ( global_mode == 0) && ( n>10)) begin    
                    // This TLB reuses same pn and same asn as an existing one if g == 0
                    val_index = used_tlbs_nb[$urandom_range(0, used_tlbs_nb.size() -1)];
                    pn = mmu_refmodel.tlb_array[val_index].pn;
                    while(mmu_refmodel.tlb_array[val_index].page_size != page_size_tlb)begin
                        val_index = used_tlbs_nb[$urandom_range(0, used_tlbs_nb.size() -1)];
                        pn = mmu_refmodel.tlb_array[val_index].pn;
                    end
                    if (val < 90) begin
                        // simple case where phy pages are independente
                        fn = ((page_size_tlb/2**12)* ($urandom_range(0,(2**32/page_size_tlb-1))));
                    end
                    else begin 
                        // reused same fn as existing TLB
                        fn = mmu_refmodel.tlb_array[val_index].fn;
                    end                                  
                end
                else begin     
                    $display("GG:page_size_tlb3:%0d",page_size_tlb);
                    
                     no_multi_map_pn(page_size_tlb_string, program_tlb_mode, idx, check_mmc_e_mode, page_size_ltlb, small_page_size_jtlb , large_page_size_jtlb, pn, next_is_used, prev_is_used,no_found_available_pn_zone_flag);
                    
                    $display("GG:page_size_tlb4:%0d",page_size_tlb);
                    //Ensure the last write TLB is correct with the 4K size
                    if(no_found_available_pn_zone_flag == 1 && check_mmc_error_mode == 1)begin
                        
                        no_found_available_pn_zone_flag_temp = 1;                    
                        page_size_ltlb = 2**12;                    
                        page_size_tlb  = page_size_ltlb;
                        check_mmc_e_mode = 0;
                        
                        program_tlb_mode = PROGRAM_LTLB;                        
                        idx = idx_last;
                        no_multi_map_pn(page_size_tlb_string, program_tlb_mode, idx, check_mmc_e_mode, page_size_ltlb, small_page_size_jtlb , large_page_size_jtlb, pn, next_is_used, prev_is_used,no_found_available_pn_zone_flag);
                    end
                    if ((val < 40) && (used_tlbs_nb.size()>0)) begin
                        // reused same fn as an existing TLB
                        val_index = $urandom_range(0, used_tlbs_nb.size() -1);
                        fn = mmu_refmodel.tlb_array[used_tlbs_nb[val_index]].fn;
                    end
                    else begin                       
                        // simple case where page are independente
                        fn = ((page_size_tlb/2**12)* ($urandom_range(0,(2**32/page_size_tlb-1))));
                    end                    
                end
            end
 
 /************* Control the ASN of the MMC and TEH *******************************/
           
            if(global_mode == 0) begin            
              int idx_same_pn;           
              int found_flag;             
                if((used_tlbs_nb.size !=0) && (n > 1))begin
                    for(int i=0;i<used_tlbs_nb.size ;i++)begin
                        if(mmu_refmodel.tlb_array[used_tlbs_nb[i]].pn == pn)begin
                            idx_same_pn = i;                                                                             
                            found_flag = 1;
                            break;
                        end                                              
                    end                   
                    if(found_flag == 0)begin
                     
                        mmu_teh.asn.set(asn_random); 
                        mmu_mmc.asn.set(asn_random);
                    end
                    else begin                    
                        mmu_teh.asn.set($urandom_range(0,512)); 
                        mmu_mmc.asn.set($urandom_range(0,512));                                      
                    end                
                end                             
                else begin
                    // used tlbs nb size = 0                
                    mmu_teh.asn.set(asn_random); 
                    mmu_mmc.asn.set(asn_random);
                end 
            end  
            else begin
                // global_mode = 1                
                mmu_teh.asn.set($urandom_range(0,512)); 
                mmu_mmc.asn.set($urandom_range(0,512));
            end 
            
                   
            if (no_mapping_en == 0) begin
                if (no_trap_condition == 1)
                  mmu_tel.es.set(3);
                else
                  mmu_tel.es.set($urandom_range(1,3));      //This is for generating the trap writetoclean             
            end           
            else begin
                if (no_trap_condition == 1)
                  mmu_tel.es.set(3);
                else
                  mmu_tel.es.set($urandom_range(0,3));      //This is for generating the trap writetoclean                   
            end 
            
            if (mmu_tel.es.get() == 0)
              available_not_valid_page_nb = {available_not_valid_page_nb, pn};
            else
              available_valid_page_nb = {available_valid_page_nb, pn};
        
            if (no_trap_condition == 1) begin
              int available_val[$];
                // 9,10,13 if PM == 0 and 2,4,6,8,9,10,12,13 if PM = 1         
                if (priviledge_mode == 0)
                  available_val = {9,10,13};
                else
                  available_val = {2,4,6,8,9,10,12,13};
                mmu_tel.pa.set(available_val[$urandom_range(0, available_val.size -1)]);
            end
            else
              mmu_tel.pa.set($urandom_range(0,13));       //This is for generating the trap protecion

            if(page_size_tlb == 2**12)begin
                mmu_teh.s.set(1);
            end
            else begin
                mmu_teh.s.set(0);
            end
            
/******************* Calculation of the JTLB PN  *********************************************************/      
           
           
            used_tlbs_nb = { used_tlbs_nb, idx };
            // Check the PN respect the page size or not
            if(mmu_mmc.s.get() == 0)begin
              logic [19:0] pn_temp;
                no_usefull_bit_PN_management( page_size_tlb, no_usefull_bit);
                pn_temp = pn;
                pn_temp = pn_temp >> (no_usefull_bit - 1);                    
                if((pn_temp[0] !=1) && (page_size_tlb != 2**12) && (check_mmc_e_mode != 1))
                  `uvm_fatal(get_type_name(), $psprintf("[MMU_TESTS]: PN[%0X] must respect the page size[%0d] no_usefull_bit:%0d !",pn,page_size_tlb,no_usefull_bit));              
            end                   

            // Generate the cases with the wrongs parametres for checking the MMC_E  
            
            if(check_mmc_e_mode == 1 && no_found_available_pn_zone_flag_temp == 0)begin
              int rate = $urandom_range(0,100);
                if(rate < 100)begin                 
                    mmu_mmc.s.set($urandom_range(0,1));                  
                end                                           
            end
            else begin
             
                mmu_mmc.s.set(0);
                                          
            end

            mmu_teh.pn.set(pn);
            mmu_mmc.dps.set(dps);
            mmu_mmc.lps.set(lps); 
            mmu_mmc.idx.set(idx);
            mmu_mmc.sne.set(sne);     //Enable Trap Protection         
            mmu_mmc.spe.set(spe);     //Enable Trap Nomapping       
            mmu_mmc.ptc.set(ptc);     //This is for generating the trap protecion
            mmu_mmc.e.set(0);

         
            mmu_tel.cp.set($urandom_range(0,3));          //This is for generatiog the signal dcache policy
            mmu_tel.ae.set($urandom_range(0,16));
            mmu_tel.fn.set(fn);            
            mmu_teh.reserved.set(0);
            mmu_teh.g.set(global_mode);          
            $display("GG:no_found_available_pn_zone_flag:%0d",no_found_available_pn_zone_flag);


            if(no_found_available_pn_zone_flag == 1  && check_mmc_error_mode == 0)begin
                break;
            end
                    
            Program_TLB( mmu_mmc, mmu_teh, mmu_tel);
                  
                        
/******************* Store the necessary values ************************************/

            mmu_refmodel.tlb_array[idx].page_size = page_size_tlb;
            mmu_refmodel.tlb_array[idx].next_page_is_used = next_is_used;
            mmu_refmodel.tlb_array[idx].previous_page_is_used = prev_is_used;
            no_usefull_bit_PN_management(page_size_tlb, no_usefull_bit);
            mmu_refmodel.tlb_array[idx].no_usefull_bit = no_usefull_bit;
            
            mmu_refmodel.tlb_array[idx].last_line_addr_of_page = (((pn >> no_usefull_bit)<< no_usefull_bit)  << 12) + page_size_tlb - 1 ;
            mmu_refmodel.tlb_array[idx].first_line_addr_of_page = (((pn >> no_usefull_bit)<< no_usefull_bit) << 12);
            
            mmu_refmodel.tlb_array[idx].check_mmc_error_mode = check_mmc_e_mode;
            mmu_refmodel.check_mmc_e_flag = check_mmc_e_mode;
            mmu_refmodel.tlb_array[idx].multi_mapping_en =  multi_mapping_en;
            
            for(int i=0;i<264;i++)begin // Flag of the continueus page
                if( (  ((mmu_refmodel.tlb_array[i].first_line_addr_of_page) == (mmu_refmodel.tlb_array[idx].last_line_addr_of_page + 1)) || ((mmu_refmodel.tlb_array[i].last_line_addr_of_page + 1) == (mmu_refmodel.tlb_array[idx].first_line_addr_of_page)) ) && (mmu_refmodel.tlb_array[i].g == 1 || (mmu_refmodel.tlb_array[i].asn ==  mmu_mmc.asn.get())))begin

                    mmu_refmodel.tlb_array[idx].continueus_flag = 1;  
                    
                    if((mmu_refmodel.tlb_array[i].first_line_addr_of_page) == (mmu_refmodel.tlb_array[idx].last_line_addr_of_page + 1))begin             
                        mmu_refmodel.tlb_array[idx].Pre_Continu_Page_Index = i;
                    end
                    else begin
                        mmu_refmodel.tlb_array[idx].After_Continu_Page_Index = i;
                    end
                    
                end
            end  
            $display("GG:DPS:%0d LPS:%0d IDX:%0d  no_usefull_bit:%0d check_mmc_e_mode:%0d",dps,lps, idx, no_usefull_bit,check_mmc_e_mode);

/*---------------------- TLB Maintenance --------------------------------*/
            
            tlbmaintenance_sequence = tlbmaintenance_seq::type_id::create($psprintf("tlb_maintenance_sequence"));
		    mmu_proc_tlbmaintenance.master.sequencer.count = 1;
		    tlbmaintenance_sequence.v_name                 = "MMU_TLB_MAINTENANCE";
            tlbmaintenance_sequence.lcancel_mode           = NO_CANCEL;
	        tlbmaintenance_sequence.lcancel_lat            = 1;
            tlbmaintenance_sequence.lreq_lat               = $urandom_range(5,10);    
            tlbmaintenance_sequence.lcmd                   = TLBWRITE;	           
		    tlbmaintenance_sequence.start(mmu_proc_tlbmaintenance.master.sequencer);

            if(no_found_available_pn_zone_flag_temp == 1  && check_mmc_error_mode == 1)begin
                break;
            end

            
        end // for (int n=number_tlb; n>0;n--)
        
        //It is the least recently writen index, This is for verifying the tlb maintenance index jtlb
       
        idx_lrw = idx;
        mmu_refmodel.tlb_array[idx].lrw_index_mode = 1;
           $display("GG:idx_lrw:%0d lrw_index_mode:%0d", idx_lrw, mmu_refmodel.tlb_array[idx].lrw_index_mode);
        if(ltlb_mantenance_mode == TLB_WRITE_MODE)begin
            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
		    mmu_proc_sfrreads.master.sequencer.count = 1;        
		    sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = MMC;	 	   
		    sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
        end
        if(ltlb_mantenance_mode == TLB_READ_MODE)begin
            tlb_mantenance_read_management(100);
        end        
        if(ltlb_mantenance_mode == TLB_PROBE_MODE)begin
            tlb_mantenance_probe_management(100);
        end
        if(ltlb_mantenance_mode == LTLB_INDEX_MODE)begin
            tlb_mantenance_index_ltlb_management(8);
        end
        if(ltlb_mantenance_mode == JTLB_INDEX_MODE)begin
            tlb_mantenance_index_jtlb_management(idx_lrw,100);
        end
        if(ltlb_mantenance_mode == CHECK_TLB_WRITE_CODE)begin
            tlb_write_code_management(100);
        end
      
    endtask : Program_Many_TLBs



    task tlb_mantenance_read_management(int unsigned tlb_maint_num);
      logic [31:0] mmc;
      int          unsigned idx_maint,rate;
    
        for(int i=0; i<tlb_maint_num; i++)begin
            rate = $urandom_range(0,100);
            if(rate > 30)begin
                if(rate < 60)begin
                    idx_maint=$urandom_range(0,127);
                end
                else begin
                    idx_maint=$urandom_range(256,263);
                end
                mmc = mmu_refmodel.tlb_array[idx_maint].mmc;
            end
            else begin
                idx_maint = $urandom_range(128,255);
                mmc = mmu_refmodel.mmu_registers.mmu_mmc.get();
                mmc[30:22] =idx_maint;
            end
            mmu_refmodel.mmu_registers.mmu_mmc.set(mmc);
            
            
            sfrwrites_sequence = sfrwrites_seq::type_id::create($psprintf("sfrwrites_sequence"));        
	        mmu_proc_sfrwrites.master.sequencer.count = 1;        
	        sfrwrites_sequence.v_name = "MMU_SFR_WRITE";
	        sfrwrites_sequence.lreq_lat = $urandom_range(5,10);
	        sfrwrites_sequence.lcmd = SET;
	        sfrwrites_sequence.sfr_name = MMC;    
	        sfrwrites_sequence.lcpu_wr_reg_val_i = mmc;
	        sfrwrites_sequence.start(mmu_proc_sfrwrites.master.sequencer);

            tlbmaintenance_sequence = tlbmaintenance_seq::type_id::create($psprintf("tlb_maintenance_sequence"));
	        mmu_proc_tlbmaintenance.master.sequencer.count = 1;
	        tlbmaintenance_sequence.v_name                 = "MMU_TLB_MAINTENANCE";
            tlbmaintenance_sequence.lcancel_mode           = NO_CANCEL;
	        tlbmaintenance_sequence.lcancel_lat            = 1;
            tlbmaintenance_sequence.lreq_lat               = $urandom_range(5,10);    
            tlbmaintenance_sequence.lcmd                   = TLBREAD;	           
	        tlbmaintenance_sequence.start(mmu_proc_tlbmaintenance.master.sequencer);

            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = MMC;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
            
            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = TEH;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
            
            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = TEL;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
        end
    endtask
    
    task tlb_mantenance_probe_management(int unsigned tlb_maint_num);
      logic [31:0] teh_maint;    
      int          unsigned idx_maint;
      int          rate;
        for(int i=0; i<tlb_maint_num;i++)begin
            rate = $urandom_range(0,100);
            idx_maint =  $urandom_range(0,263);
            while (idx_maint <256 && idx_maint >127)begin
                idx_maint =  $urandom_range(0,263);
            end
            //Generate the matche cas and no matche cas.
            if(rate >50)begin
                teh_maint = mmu_refmodel.tlb_array[idx_maint].teh;
            end
            else begin
                teh_maint = mmu_refmodel.tlb_array[idx_maint].teh;
                teh_maint[31:12] = $urandom_range(0,2**20); 
            end
            
            mmu_refmodel.mmu_registers.mmu_teh.set(teh_maint);
            

            sfrwrites_sequence = sfrwrites_seq::type_id::create($psprintf("sfrwrites_sequence"));        
	        mmu_proc_sfrwrites.master.sequencer.count = 1;        
	        sfrwrites_sequence.v_name = "MMU_SFR_WRITE";
	        sfrwrites_sequence.lreq_lat = $urandom_range(5,10);
	        sfrwrites_sequence.lcmd = SET;
	        sfrwrites_sequence.sfr_name = TEH;    
	        sfrwrites_sequence.lcpu_wr_reg_val_i = teh_maint;
	        sfrwrites_sequence.start(mmu_proc_sfrwrites.master.sequencer);

         
            tlbmaintenance_sequence = tlbmaintenance_seq::type_id::create($psprintf("tlb_maintenance_sequence"));
	        mmu_proc_tlbmaintenance.master.sequencer.count = 1;
	        tlbmaintenance_sequence.v_name                 = "MMU_TLB_MAINTENANCE";
            tlbmaintenance_sequence.lcancel_mode           = NO_CANCEL;
	        tlbmaintenance_sequence.lcancel_lat            = 1;
            tlbmaintenance_sequence.lreq_lat               = $urandom_range(5,10);    
            tlbmaintenance_sequence.lcmd                   = TLBPROBE;	           
	        tlbmaintenance_sequence.start(mmu_proc_tlbmaintenance.master.sequencer);

            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = MMC;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
            
            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = TEH;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
            
            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = TEL;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
        end
    endtask

    task tlb_mantenance_index_ltlb_management(int unsigned tlb_maint_num);

        for(int i=0; i<tlb_maint_num;i++)begin
            
            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = MMC;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
            
            tlbmaintenance_sequence = tlbmaintenance_seq::type_id::create($psprintf("tlb_maintenance_sequence"));
	        mmu_proc_tlbmaintenance.master.sequencer.count = 1;
	        tlbmaintenance_sequence.v_name                 = "MMU_TLB_MAINTENANCE";
            tlbmaintenance_sequence.lcancel_mode           = NO_CANCEL;
	        tlbmaintenance_sequence.lcancel_lat            = 1;
            tlbmaintenance_sequence.lreq_lat               = $urandom_range(5,10);    
            tlbmaintenance_sequence.lcmd                   = TLBINDEXL;	           
	        tlbmaintenance_sequence.start(mmu_proc_tlbmaintenance.master.sequencer);

            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = MMC;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
            
        end
    endtask


    task tlb_mantenance_index_jtlb_management(int unsigned idx_lrw,int unsigned tlb_maint_num);

      logic [31:0] teh_maint;     
      logic [31:0] tel_maint; 
      int          unsigned idx_maint;
      int          rate;
        for(int i=0; i<tlb_maint_num;i++)begin
        rate = $urandom_range(0,100);
        if(rate > 50 || idx_lrw > 128)begin           
            idx_maint =  $urandom_range(0,127);
        end
        else begin
            idx_maint = idx_lrw;
        end
        teh_maint = mmu_refmodel.tlb_array[idx_maint].teh;
        tel_maint = mmu_refmodel.tlb_array[idx_maint].tel;
        
        
        mmu_refmodel.mmu_registers.mmu_teh.set(teh_maint);
        mmu_refmodel.mmu_registers.mmu_tel.set(tel_maint);

        sfrwrites_sequence = sfrwrites_seq::type_id::create($psprintf("sfrwrites_sequence"));        
	    mmu_proc_sfrwrites.master.sequencer.count = 1;        
	    sfrwrites_sequence.v_name = "MMU_SFR_WRITE";
	    sfrwrites_sequence.lreq_lat = $urandom_range(5,10);
	    sfrwrites_sequence.lcmd = SET;
	    sfrwrites_sequence.sfr_name = TEH;    
	    sfrwrites_sequence.lcpu_wr_reg_val_i = teh_maint;
	    sfrwrites_sequence.start(mmu_proc_sfrwrites.master.sequencer);
        
        sfrwrites_sequence = sfrwrites_seq::type_id::create($psprintf("sfrwrites_sequence"));        
	    mmu_proc_sfrwrites.master.sequencer.count = 1;        
	    sfrwrites_sequence.v_name = "MMU_SFR_WRITE";
	    sfrwrites_sequence.lreq_lat = $urandom_range(5,10);
	    sfrwrites_sequence.lcmd = SET;
	    sfrwrites_sequence.sfr_name = TEL;    
	    sfrwrites_sequence.lcpu_wr_reg_val_i = tel_maint;
	    sfrwrites_sequence.start(mmu_proc_sfrwrites.master.sequencer);
        
     
        tlbmaintenance_sequence = tlbmaintenance_seq::type_id::create($psprintf("tlb_maintenance_sequence"));
	    mmu_proc_tlbmaintenance.master.sequencer.count = 1;
	    tlbmaintenance_sequence.v_name                 = "MMU_TLB_MAINTENANCE";
        tlbmaintenance_sequence.lcancel_mode           = NO_CANCEL;
	    tlbmaintenance_sequence.lcancel_lat            = 1;
        tlbmaintenance_sequence.lreq_lat               = $urandom_range(5,10);    
        tlbmaintenance_sequence.lcmd                   = TLBINDEXJ;	           
	    tlbmaintenance_sequence.start(mmu_proc_tlbmaintenance.master.sequencer);

        sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	    mmu_proc_sfrreads.master.sequencer.count = 1;        
	    sfrreads_sequence.v_name = "MMU_SFR_READ";
	    sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
        sfrreads_sequence.lrr_stall_i = 1;
        sfrreads_sequence.sfr_name = MMC;	 	   
	    sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
        
        end 
        
    endtask


    task tlb_write_code_management(int tlb_maint_num);
  
        cpu_wr_reg_cmd_t lcmd;
        int          rate;
        logic [31:0] val_temp;
        logic [31:0] val_reg;
        logic [31:0] val_calc;
        for(int i=0; i<tlb_maint_num;i++)begin
            rate = $urandom_range(0,100);
            val_temp = $urandom_range(0,2000000000);
            val_reg =  mmu_refmodel.mmu_registers.mmu_mmc.get();
            
            if(rate > 100)begin
                lcmd = HFXB;              
            end
            else begin
                lcmd = HFXT;
                val_reg[31:16] = (val_reg[31:16] & (~val_temp[15:0])) |  val_temp[31:16];
                val_calc = val_reg;
            end
           
            $display("GG:lcmd:%s rate:%0d val_reg:%0X val_temp:%0X val_calc:%0X",lcmd,rate,val_reg,val_temp,val_calc);
            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = MMC;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);
            
            sfrwrites_sequence = sfrwrites_seq::type_id::create($psprintf("sfrwrites_sequence"));        
	        mmu_proc_sfrwrites.master.sequencer.count = 1;        
	        sfrwrites_sequence.v_name = "MMU_SFR_WRITE";
	        sfrwrites_sequence.lreq_lat = $urandom_range(5,10);
	        sfrwrites_sequence.lcmd = lcmd;
	        sfrwrites_sequence.sfr_name = MMC;    
	        sfrwrites_sequence.lcpu_wr_reg_val_i = val_temp;
	        sfrwrites_sequence.start(mmu_proc_sfrwrites.master.sequencer);
            
            mmu_refmodel.mmu_registers.mmu_mmc.set(val_calc);
            
            sfrreads_sequence = sfrreads_seq::type_id::create($psprintf("sfrreads_sequence"));        
	        mmu_proc_sfrreads.master.sequencer.count = 1;        
	        sfrreads_sequence.v_name = "MMU_SFR_READ";
	        sfrreads_sequence.lreq_lat = $urandom_range(5,10); 
            sfrreads_sequence.lrr_stall_i = 1;
            sfrreads_sequence.sfr_name = MMC;	 	   
	        sfrreads_sequence.start(mmu_proc_sfrreads.master.sequencer);

            
            // mmu_refmodel.mmu_registers.mmu_teh.set(teh_maint);
            
            
        end
        
    endtask










    
/************************ Generate virtual address *******************************************/

    
    task Generate_Access_Dcache(int number_access, e1_dcache_opc_t opcode_access[$],int unsigned size_access[$], int no_trapping_en, exception_t enabled_traps[$], 
                                int priviledge_mode_random, aligned_mode_t aligned_mode,int no_mapping_en, trap_t trap_mode, 
                                size_tlb_t page_size_ltlb_s, size_tlb_t small_page_size_dps,size_tlb_t large_page_size_lps);
        
      int unsigned virt_addr, page_nb, id;
        e1_dcache_opc_t lopcode_access;     
      int unsigned lsize_access;
      int trap_wtc_en, trap_atc_en, trap_protect_en, trap_dmis_en, trap_dsys_en, trap_nomap_en, no_traps;
    
        // Control the trap, then generate the request's virtual address
        
        // typedef enum {TRAP_ALL, TRAP_WTC, TRAP_ATC, TRAP_PROTECT, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP} exception_t;
        trap_wtc_en = 0;
        trap_atc_en = 0;
        trap_protect_en = 0;
        trap_dmis_en = 0;
        trap_dsys_en = 0;
        trap_nomap_en = 0;
        no_traps = 1;
        if(trap_mode == NO_TRAP) enabled_traps={};
        foreach(enabled_traps[i]) begin
            case (enabled_traps[i])
              TRAP_ALL : begin
                  trap_wtc_en = 1;
                  trap_atc_en = 1;
                  trap_protect_en = 1;
                  trap_dmis_en = 1;
                  trap_dsys_en = 1;
                  trap_nomap_en = 1;
                  no_traps = 0;
              end
              TRAP_WTC : begin
                  trap_wtc_en = 1;
                  no_traps = 0;
              end
              TRAP_ATC : begin
                  trap_atc_en = 1;
                  no_traps = 0;
              end
              TRAP_PROTECT : begin
                  trap_protect_en = 1;
                  no_traps = 0;
              end
              TRAP_DMISALIGN : begin
                  trap_dmis_en = 1;
                  no_traps = 0;
              end
              TRAP_DYSERR : begin
                  trap_dsys_en = 1;
                  no_traps = 0;
              end
              TRAP_NOMAP : begin
                  trap_nomap_en = 1;
                  no_traps = 0;
              end
            endcase
        end 
        
        mmu_refmodel.traps_disabled = no_traps;
        
        
        for(int n=number_access; n>0; n--)begin
          int no_map_access = 0;
          int tlb_usable[$]; 
          int rate;
          int tlb_used, rnd_pn, no_usefull_bit,  tlb_found;
          int l3_is_allowed, pn_ok;
          int align_size;
          int bit_ratio = 0;
          int unsigned page_size_temp = 0;
  
                   
            lopcode_access = opcode_access[$urandom_range(0, (opcode_access.size -1))];
            
            if (trap_nomap_en == 1) begin
              int a =$urandom_range(0,99);
                if (a < 50)begin
                    // Generate access in NO MAPPING (50% ratio)
                    no_map_access = 1;
                end
            end           
            
/**************************** If no map access is 1, there are three no mapping cases ************************/
            
            if ((no_map_access == 1) && (no_mapping_en == 1))begin
                // NO MAPPING access: Three cases
                `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_TESTS]: Generate access with possible NO MAPPING", $time), UVM_FULL) 
                tlb_found = 0;
                rate = $urandom_range(0,99);
                if (rate < 30) begin 
                    // Try to generate NO MAPPING on invalid TLB
                    foreach(used_tlbs_nb[i]) begin
                        if(mmu_refmodel.tlb_array[used_tlbs_nb[i]].page_size != 0 && mmu_refmodel.tlb_array[used_tlbs_nb[i]].check_mmc_error_mode == 0)begin
                            if (mmu_refmodel.tlb_array[used_tlbs_nb[i]].es == 0)
                              tlb_usable = { tlb_usable , used_tlbs_nb[i] };   
                        end                
                    end
             
                    if (tlb_usable.size > 0) begin
                        
                        tlb_used = tlb_usable[$urandom_range(0,tlb_usable.size()-1)];
                        
                        if (trap_nomap_en == 1 || mmu_refmodel.tlb_array[tlb_used].next_page_is_used == 1)
                          l3_is_allowed = 1;
                        else
                          l3_is_allowed = 0;
                        
                        virt_addr = generate_virt_addr(mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page, mmu_refmodel.tlb_array[tlb_used].last_line_addr_of_page ,mmu_refmodel.tlb_array[tlb_used].page_size,l3_is_allowed);
                         $display("GG:tlb_uesed0:%0d virt_addr:%0X first_line_addr_of_page:%0X last_line_addr_of_page:%0X",tlb_used,virt_addr,mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page,mmu_refmodel.tlb_array[tlb_used].last_line_addr_of_page);
                        tlb_found = 1;
                    end 
                end
                else begin //For now it is not usefull because it can not generate multi mapping with different ASN
                    // Try to generate NO MAPPING on ASN
                    foreach(used_tlbs_nb[i]) begin
                        if(mmu_refmodel.tlb_array[used_tlbs_nb[i]].page_size !=0  && mmu_refmodel.tlb_array[used_tlbs_nb[i]].check_mmc_error_mode == 0)begin
                            if (mmu_refmodel.tlb_array[used_tlbs_nb[i]].es != 0 && mmu_refmodel.tlb_array[used_tlbs_nb[i]].g == 0 && 
                                mmu_refmodel.tlb_array[used_tlbs_nb[i]].asn != mmu_refmodel.mmu_registers.mmu_mmc.asn.get())
                              tlb_usable = { tlb_usable , used_tlbs_nb[i] };
                        end
                    end
                    
                    if (tlb_usable.size > 0) begin
                        tlb_used = tlb_usable[$urandom_range(0,tlb_usable.size()-1)];
                        if (trap_nomap_en == 1 || mmu_refmodel.tlb_array[tlb_used].next_page_is_used == 1)
                          l3_is_allowed = 1;
                        else
                          l3_is_allowed = 0;                     
                        
                        virt_addr = generate_virt_addr(mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page, mmu_refmodel.tlb_array[tlb_used].last_line_addr_of_page ,mmu_refmodel.tlb_array[tlb_used].page_size,l3_is_allowed);
                       $display("GG:tlb_uesed1:%0d virt_addr:%0X first_line_addr_of_page:%0X last_line_addr_of_page:%0X",tlb_used,virt_addr,mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page,mmu_refmodel.tlb_array[tlb_used].last_line_addr_of_page);
                        tlb_found = 1;
                    end
                end
                if (tlb_found == 0) begin
                    
                  longint unsigned page_size_tlb;
                    
                    // Generate NO MAPPING virtual address on No match TLB
                    pn_ok = 0;
                    while (pn_ok == 0) begin
                        
                        no_valid_pn_random(page_size_ltlb_s, rnd_pn, page_size_tlb, no_usefull_bit); //Must consider it later
                        $display("GG:page_size_ltlb_s:%0d",page_size_tlb);
                        pn_ok = 1;
                        foreach(used_tlbs_nb[i]) begin
                            if (mmu_refmodel.tlb_array[used_tlbs_nb[i]].pn == rnd_pn) begin
                                pn_ok = 0;
                                break;
                            end
                        end
                    end // while (pn_ok == 0)
                     $display("GG:page_size_ltlb_s:%0d rnd_pn:%0X",page_size_tlb,rnd_pn);
                    virt_addr = generate_virt_addr(((rnd_pn >> no_usefull_bit) << no_usefull_bit) << 12,
                                                   ((((rnd_pn >> no_usefull_bit) << no_usefull_bit)<<12) +
                                                    page_size_tlb -1), page_size_tlb,l3_is_allowed);
                     $display("GG:tlb_uesed3:%0d virt_addr:%0X first_line_addr_of_page:%0X last_line_addr_of_page:%0X",tlb_used,virt_addr,mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page,mmu_refmodel.tlb_array[tlb_used].last_line_addr_of_page);
                end                 
            end             
            //If no map access is 0, choose the no trap tlb Then generate the correspond virtual address 
            else begin                           
/******* It is for choosing the no trap protection tlb , Then generate the correspond virtual address  ***************/               
              int wtc_could_hit;
              int atc_could_hit;
              int prot_could_hit;
              int rd_allowed, wr_allowed;
                 
                `uvm_info(get_type_name(), $psprintf("[%0d]: [MMU_TESTS]: Generate access without NO MAPPING", $time), UVM_FULL) 
                foreach(used_tlbs_nb[i]) begin                   
                    wtc_could_hit = 0;
                    atc_could_hit = 0;
                    prot_could_hit = 0;
                             
                    if ((mmu_refmodel.tlb_array[used_tlbs_nb[i]].es != 0) && (mmu_refmodel.tlb_array[used_tlbs_nb[i]].g == 1 || 
                                                                              mmu_refmodel.tlb_array[used_tlbs_nb[i]].asn == mmu_refmodel.mmu_registers.mmu_mmc.asn.get())) begin

                        if ((lopcode_access == STORE || lopcode_access == DZEROL) && mmu_refmodel.tlb_array[used_tlbs_nb[i]].es == 1)
                          wtc_could_hit = 1;
                        if ((lopcode_access == LDC || lopcode_access == FDA || lopcode_access == CWS) && mmu_refmodel.tlb_array[used_tlbs_nb[i]].es != 3)
                          atc_could_hit = 1;
                        extract_permission(priviledge_mode_random, mmu_refmodel.tlb_array[used_tlbs_nb[i]].pa, rd_allowed, wr_allowed);
                        if ((lopcode_access == LOAD || lopcode_access == DINVAL || lopcode_access == DTOUCHL) && rd_allowed == 0)
                          prot_could_hit = 1;
                        else if (lopcode_access != DINVAL && lopcode_access != WPURGE && wr_allowed == 0)
                          prot_could_hit = 1;
                        if ((trap_wtc_en == 1 || wtc_could_hit == 0) && (trap_atc_en == 1 || atc_could_hit == 0) && (trap_protect_en == 1 || prot_could_hit == 0))begin
                            tlb_usable = { tlb_usable , used_tlbs_nb[i] };                   
                        end                      
                    end                    
                end 
          
                if (tlb_usable.size > 0) begin
                    
                    tlb_used = tlb_usable[$urandom_range(0,tlb_usable.size()-1)];            
                    if (trap_nomap_en == 1 || mmu_refmodel.tlb_array[tlb_used].next_page_is_used == 1)
                      l3_is_allowed = 1;
                    else
                      l3_is_allowed = 0;
                    
                    
                    virt_addr = generate_virt_addr(mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page, mmu_refmodel.tlb_array[tlb_used].last_line_addr_of_page ,mmu_refmodel.tlb_array[tlb_used].page_size,l3_is_allowed);
                                     
                end                   
                else begin
                    
                    foreach(used_tlbs_nb[i]) begin
                        if(mmu_refmodel.tlb_array[used_tlbs_nb[i]].page_size != 0 && mmu_refmodel.tlb_array[used_tlbs_nb[i]].check_mmc_error_mode == 0)begin
                            tlb_usable = { tlb_usable , used_tlbs_nb[i] };   
                        end                
                    end
                    tlb_used = tlb_usable[$urandom_range(0,tlb_usable.size()-1)];       
                    $display("GG:");
                    virt_addr = generate_virt_addr(mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page, mmu_refmodel.tlb_array[tlb_used].last_line_addr_of_page ,mmu_refmodel.tlb_array[tlb_used].page_size,l3_is_allowed);
                       $display("GG:tlb_uesed:%0d first_line_addr_of_page:%0X last_line_addr_of_page:%0X",tlb_used,mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page,mmu_refmodel.tlb_array[tlb_used].last_line_addr_of_page);
                end
            end
            $display("GG:virt_addr:%0X",virt_addr);
            // It is not possible that the virt addresss is 0 if the start address is not 0            
            if(virt_addr ==0)begin 
                if(mmu_refmodel.tlb_array[tlb_used].first_line_addr_of_page != 0) 
                  `uvm_fatal(get_type_name(), $psprintf("[MMU_TESTS]: Virtual addresss should not be  0!"));
            end
            
            
            lsize_access   = size_access[$urandom_range(0,(size_access.size - 1))];

            if(lopcode_access == LDC)
              lsize_access = 8;
            if(lopcode_access == FDA || lopcode_access == CWS)
              lsize_access = 4;
            
            if(aligned_mode == ALIGNED)begin             
                align_size = lsize_access;
            end
            else if(aligned_mode == ALIGNED_RANDOM)begin
                align_size=(2**$urandom_range(0,3));               
            end
            else begin
                align_size=1;
            end
            
            /*************** Caluculation of the bit elapse for the diffrent size page ***************/
        
                 
            if(trap_mode == NO_TRAP)begin 
                virt_addr[3:0] = 8; // It can not generate the trap disalign
            end
            else if(trap_mode == FEW_TRAP)begin
              int val = $urandom_range(0,100);
                if(val > 50)
                  virt_addr[2:0] = 8;
            end
            
            if(align_size == 8)begin     
                virt_addr[2:0]=0;
            end
            else if(align_size == 4)begin        
                virt_addr[1:0]=0;
            end
            else if(align_size == 2)begin                    
                virt_addr[0:0]=0;          
            end
         
            //no_trapping_en = 1;
            if(tlb_usable.size !=0 )begin
                proc_dcache_sequence = proc_dcache_seq::type_id::create($psprintf("proc_dcache_sequence"));
		        mmu_proc_dcache.master.sequencer.count      =  1; 
                proc_dcache_sequence.v_name                 = "MMU_PROC_DCACHE";
                proc_dcache_sequence.lreq_lat               = $urandom_range(5,2);
                proc_dcache_sequence.le1_dcache_opc_i       = lopcode_access;
                proc_dcache_sequence.le1_dcache_virt_addr_i = virt_addr;
                proc_dcache_sequence.le1_non_trapping_i     = no_trapping_en;
                proc_dcache_sequence.le1_dcache_size_i      = lsize_access;             	            
		        proc_dcache_sequence.start(mmu_proc_dcache.master.sequencer);
            end
        end
    endtask : Generate_Access_Dcache


    
endclass : mppa_proc_mmu_tests


/********************** Test 4K Page Aligned with global 1 *********************/

class only_4k_pages_aligned_global_one_tnm_dis_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_aligned_global_one_tnm_dis_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en,check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "only_4k_pages_aligned_global_one_tnm_dis_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_aligned_global_one_tnm_dis_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  =$urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;
               // program_tlb_mode=   PROGRAM_LTLB;
                trap_mode       =   FEW_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  5000;
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                no_mapping_en   =  0;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                check_mmc_e_mode = 0;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
        
            
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_aligned_global_one_tnm_dis_tmm_dis



/********************  Test 4K Page No Aligned with global 1 *******************/

class only_4k_pages_no_aligned_global_one_tnm_dis_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_no_aligned_global_one_tnm_dis_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  trap_random;
  string v_name;
   int unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    global_mode_t    global_mode;
    aligned_mode_t   aligned_mode;
    
	function new(string name = "only_4k_pages_no_aligned_global_one_tnm_dis_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration


	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	    
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_no_aligned_global_one_tnm_dis_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
        
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
             //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  5000;
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  0;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_no_aligned_global_one_tnm_dis_tmm_dis   


/******************** Test 4K Page Global Mode 0 with page aligned ***************/

class only_4k_pages_aligned_global_zero_tnm_dis_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_aligned_global_zero_tnm_dis_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t  opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t      trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  trap_random;
  string v_name;
   int unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    global_mode_t   global_mode;
    aligned_mode_t  aligned_mode;
    
	function new(string name = "only_4k_pages", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration


	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	    
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'one_page'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
        
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
               //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  0;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_aligned_global_zero_tnm_dis_tmm_dis   

/********************** Test 4K Page Aligned No mapping enable with global 1 *********************/

class only_4k_pages_aligned_global_one_tnm_en_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_aligned_global_one_tnm_en_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
   int unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    aligned_mode_t aligned_mode;
	function new(string name = "only_4k_pages_aligned_global_one_tnm_en_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_aligned_global_one_tnm_en_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
              //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);              
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_aligned_global_one_tnm_en_tmm_dis      

/********************** Test 4K Page Aligned No mapping enable multi mapping enable with global 1 *********************/

class only_4k_pages_aligned_global_one_tnm_en_tmm_en extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_aligned_global_one_tnm_en_tmm_en)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
   int unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    aligned_mode_t aligned_mode;
	function new(string name = "only_4k_pages_aligned_global_one_tnm_en_tmm_en", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_aligned_global_one_tnm_en_tmm_en'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  1;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);       
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_aligned_global_one_tnm_en_tmm_en


/********************** Test 4K Page Aligned No mapping enable multi mapping disable with global 0 *********************/

class only_4k_pages_aligned_global_zero_tnm_en_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_aligned_global_zero_tnm_en_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
   int unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    aligned_mode_t aligned_mode;
	function new(string name = "only_4k_pages_aligned_global_zero_tnm_en_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_aligned_global_zero_tnm_en_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);          
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_aligned_global_zero_tnm_en_tmm_dis


/********************** Test 4K Page Aligned No mapping enable multi mapping disable with global 0 *********************/

class only_4k_pages_aligned_global_zero_tnm_en_tmm_en extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_aligned_global_zero_tnm_en_tmm_en)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
   int unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    aligned_mode_t aligned_mode;
	function new(string name = "only_4k_pages_aligned_global_zero_tnm_en_tmm_en", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_aligned_global_zero_tnm_en_tmm_en'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
               //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  1;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);               
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_aligned_global_zero_tnm_en_tmm_en

/********************** Test 4K Page Aligned No mapping enable multi mapping disable with global 1 *********************/

class only_4k_pages_no_aligned_global_one_tnm_en_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_no_aligned_global_one_tnm_en_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
   int unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    aligned_mode_t aligned_mode;
	function new(string name = "only_4k_pages_no_aligned_global_one_tnm_en_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_no_aligned_global_one_tnm_en_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);     
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_no_aligned_global_one_tnm_en_tmm_dis


/********************** Test 4K Page Aligned No mapping enable multi mapping enable with global 1 *********************/

class only_4k_pages_no_aligned_global_one_tnm_en_tmm_en extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_no_aligned_global_one_tnm_en_tmm_en)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
   int unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    aligned_mode_t aligned_mode;
	function new(string name = "only_4k_pages_no_aligned_global_one_tnm_en_tmm_en", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_no_aligned_global_one_tnm_en_tmm_en'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  1;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                                
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : only_4k_pages_no_aligned_global_one_tnm_en_tmm_en


/***************** Test 4K Page Global Mode 0 with page no aligned *************/

class only_4k_pages_no_aligned_global_zero_tnm_dis_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_no_aligned_global_zero_tnm_dis_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
  
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;

  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  trap_random; 
  string v_name;
  int    unsigned  check_mmc_e_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    trap_t           trap_mode;
    global_mode_t    global_mode;
    e1_dcache_opc_t  opcode_access[$];
    aligned_mode_t   aligned_mode;
    
	function new(string name = "only_4k_pages", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration


	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	    
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'one_page'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
        
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  0;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
                
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t     END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass :only_4k_pages_no_aligned_global_zero_tnm_dis_tmm_dis   


/***************** Test 4K Page Global Mode 0 with page no aligned *************/

class only_4k_pages_no_aligned_global_zero_tnm_en_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_no_aligned_global_zero_tnm_en_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
  
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;

  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  trap_random; 
  string v_name;
    trap_t           trap_mode;
    global_mode_t    global_mode;
    e1_dcache_opc_t  opcode_access[$];
    aligned_mode_t   aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
    
	function new(string name = "only_4k_pages_no_aligned_global_zero_tnm_en_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration


	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	    
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_no_aligned_global_zero_tnm_en_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
        
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
              //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FEW_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
                

            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t     END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass :only_4k_pages_no_aligned_global_zero_tnm_en_tmm_dis 


/***************** Test 4K Page Global Mode 0 with page no aligned *************/

class only_4k_pages_no_aligned_global_zero_tnm_en_tmm_en extends mppa_proc_mmu_tests;
	`uvm_component_utils(only_4k_pages_no_aligned_global_zero_tnm_en_tmm_en)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
  
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
  int unsigned  check_mmc_e_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  trap_random; 
  string v_name;
    trap_t           trap_mode;
    global_mode_t    global_mode;
    e1_dcache_opc_t  opcode_access[$];
    aligned_mode_t   aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "only_4k_pages_no_aligned_global_zero_tnm_en_tmm_en", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration


	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	    
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'only_4k_pages_no_aligned_global_zero_tnm_en_tmm_en'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
        
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
               //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   FOUR_K; 
                small_size_jtlb =   FOUR_K;
                large_size_jtlb =   FOUR_K;             
                trap_mode       =   FEW_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  0; 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  1;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
                


                
            end
		join
        #20;
		$display("\n\t\t*********************************\n\t\t     END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
  
endclass :only_4k_pages_no_aligned_global_zero_tnm_en_tmm_en




/********************** Test Random Page All TLB Aligned with global 1 *********************/

class random_pages_all_tlb_aligned_global_one_tnm_dis_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(random_pages_all_tlb_aligned_global_one_tnm_dis_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "random_pages_all_tlb_aligned_global_one_tnm_dis_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'random_pages_all_tlb_aligned_global_one_tnm_dis_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   OTHERS_RANDOM_K; 
                small_size_jtlb =   OTHERS_RANDOM_K;
                large_size_jtlb =   OTHERS_RANDOM_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : random_pages_all_tlb_aligned_global_one_tnm_dis_tmm_dis

/********************** Test Random Page All TLB Aligned with global 1 *********************/

class random_pages_all_tlb_aligned_global_one_tnm_en_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(random_pages_all_tlb_aligned_global_one_tnm_en_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "random_pages_all_tlb_aligned_global_one_tnm_en_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'random_pages_all_tlb_aligned_global_one_tnm_en_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   OTHERS_RANDOM_K; 
                small_size_jtlb =   OTHERS_RANDOM_K;
                large_size_jtlb =   OTHERS_RANDOM_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode ={TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : random_pages_all_tlb_aligned_global_one_tnm_en_tmm_dis

/********************** Test Random Page All TLB Aligned with global 1 *********************/

class random_pages_all_tlb_no_aligned_global_one_tnm_dis_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(random_pages_all_tlb_no_aligned_global_one_tnm_dis_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "random_pages_all_tlb_no_aligned_global_one_tnm_dis_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'random_pages_all_tlb_no_aligned_global_one_tnm_dis_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   OTHERS_RANDOM_K; 
                small_size_jtlb =   OTHERS_RANDOM_K;
                large_size_jtlb =   OTHERS_RANDOM_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : random_pages_all_tlb_no_aligned_global_one_tnm_dis_tmm_dis

/********************** Test Random Page All TLB Aligned with global 1 *********************/

class random_pages_all_tlb_no_aligned_global_one_tnm_en_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(random_pages_all_tlb_no_aligned_global_one_tnm_en_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  k1_64b_mode;
  int unsigned  check_mmc_e_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "random_pages_all_tlb_no_aligned_global_one_tnm_en_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'random_pages_all_tlb_no_aligned_global_one_tnm_en_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   OTHERS_RANDOM_K; 
                small_size_jtlb =   OTHERS_RANDOM_K;
                large_size_jtlb =   OTHERS_RANDOM_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};             
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode ={TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : random_pages_all_tlb_no_aligned_global_one_tnm_en_tmm_dis


/********************** Test Random Page All TLB Aligned with global 0  *********************/

class random_pages_all_tlb_aligned_global_zero_tnm_dis_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(random_pages_all_tlb_aligned_global_zero_tnm_dis_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "random_pages_all_tlb_aligned_global_zero_tnm_dis_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'random_pages_all_tlb_aligned_global_zero_tnm_dis_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   OTHERS_RANDOM_K; 
                small_size_jtlb =   OTHERS_RANDOM_K;
                large_size_jtlb =   OTHERS_RANDOM_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : random_pages_all_tlb_aligned_global_zero_tnm_dis_tmm_dis

/********************** Test Random Page All TLB Aligned with global 0  *********************/

class random_pages_all_tlb_aligned_global_zero_tnm_en_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(random_pages_all_tlb_aligned_global_zero_tnm_en_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "random_pages_all_tlb_aligned_global_zero_tnm_en_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'random_pages_all_tlb_aligned_global_zero_tnm_en_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   OTHERS_RANDOM_K; 
                small_size_jtlb =   OTHERS_RANDOM_K;
                large_size_jtlb =   OTHERS_RANDOM_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : random_pages_all_tlb_aligned_global_zero_tnm_en_tmm_dis

/********************** Test Random Page All TLB Aligned with global 0  *********************/

class random_pages_all_tlb_no_aligned_global_zero_tnm_dis_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(random_pages_all_tlb_no_aligned_global_zero_tnm_dis_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "random_pages_all_tlb_no_aligned_global_zero_tnm_dis_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'random_pages_all_tlb_no_aligned_global_zero_tnm_dis_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   OTHERS_RANDOM_K; 
                small_size_jtlb =   OTHERS_RANDOM_K;
                large_size_jtlb =   OTHERS_RANDOM_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : random_pages_all_tlb_no_aligned_global_zero_tnm_dis_tmm_dis


/********************** Test Random Page All TLB Aligned with global 0  *********************/

class random_pages_all_tlb_no_aligned_global_zero_tnm_en_tmm_dis extends mppa_proc_mmu_tests;
	`uvm_component_utils(random_pages_all_tlb_no_aligned_global_zero_tnm_en_tmm_dis)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];
	function new(string name = "random_pages_all_tlb_no_aligned_global_zero_tnm_en_tmm_dis", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'random_pages_all_tlb_no_aligned_global_zero_tnm_en_tmm_dis'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = 0/*$urandom_range(0,1)*/;
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   OTHERS_RANDOM_K; 
                small_size_jtlb =   OTHERS_RANDOM_K;
                large_size_jtlb =   OTHERS_RANDOM_K;             
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ZERO;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = 0;
                no_mapping_en   =  1;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {TLB_MAINTENANCE_DISABLE};
                Program_Many_TLBs(number_tlb,size_ltlb,small_size_jtlb,large_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
                Generate_Access_Dcache(number_access, opcode_access,size_access, no_trapping_en,enabled_traps, priviledge_mode_random,aligned_mode,no_mapping_en,trap_mode, size_ltlb,small_size_jtlb,large_size_jtlb);
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : random_pages_all_tlb_no_aligned_global_zero_tnm_en_tmm_dis

/********************** Test TLB maintenance All TLB Aligned with global 1 *********************/

class test_tlb_maintenance_all_tlb_4K extends mppa_proc_mmu_tests;
	`uvm_component_utils(test_tlb_maintenance_all_tlb_4K)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];

    size_tlb_t size_ltlb[$];
    size_tlb_t small_size_jtlb[$];
    size_tlb_t large_size_jtlb[$];
    size_tlb_t lsize_ltlb;
    size_tlb_t lsmall_size_jtlb;
    size_tlb_t llarge_size_jtlb;
	function new(string name = "test_tlb_maintenance_all_tlb_4K", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'test_tlb_maintenance_all_tlb_4K'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = $urandom_range(0,1);
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   {FOUR_K}; 
                small_size_jtlb =   {FOUR_K}; 
                large_size_jtlb =   {FOUR_K};            
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = $urandom_range(0,1);
                no_mapping_en   =  0;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {/*TLB_MAINTENANCE_DISABLE,*//*TLB_WRITE_MODE,TLB_READ_MODE,TLB_PROBE_MODE,LTLB_INDEX_MODE,JTLB_INDEX_MODE,*/CHECK_TLB_WRITE_CODE/*,TLB_MAINTENANCE_MODE_RANDOM*/};
                
                lsize_ltlb    = size_ltlb[$urandom_range(0, (size_ltlb.size -1))];
                lsmall_size_jtlb = small_size_jtlb[$urandom_range(0, (small_size_jtlb.size -1))];
                llarge_size_jtlb = large_size_jtlb[$urandom_range(0, (large_size_jtlb.size -1))];
             
                while(llarge_size_jtlb < lsmall_size_jtlb)begin
                    lsmall_size_jtlb = small_size_jtlb[$urandom_range(0, (small_size_jtlb.size -1))];
                    llarge_size_jtlb = large_size_jtlb[$urandom_range(0, (large_size_jtlb.size -1))];
                end
                Program_Many_TLBs(number_tlb,lsize_ltlb,lsmall_size_jtlb,llarge_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
              
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : test_tlb_maintenance_all_tlb_4K



/********************** Test TLB maintenance All TLB Aligned with global 1 tmm en Global 0  *********************/

class test_tlb_maintenance_all_tlb_small_size_page_tmm_en extends mppa_proc_mmu_tests;
	`uvm_component_utils(test_tlb_maintenance_all_tlb_small_size_page_tmm_en)

  int unsigned  number_tlb;    
  int unsigned  number_access;
  int unsigned  size_access[$];
  int unsigned  no_trapping_en;
  int unsigned  page_max, page_min;
    e1_dcache_opc_t opcode_access[$];
  int unsigned  write_not_implemented_tlb;
  int unsigned  priviledge_mode_random;
    trap_t  trap_mode;
  int unsigned  simple_case_en;
  int unsigned  no_mapping_en;
  int unsigned  multi_mapping_en;
  int unsigned  check_mmc_e_mode;
  int unsigned  k1_64b_mode;
    global_mode_t global_mode;
  string v_name;
    aligned_mode_t aligned_mode;
    tlb_mantenance_mode_t tlb_mantenance_mode[$];

    size_tlb_t size_ltlb[$];
    size_tlb_t small_size_jtlb[$];
    size_tlb_t large_size_jtlb[$];
    size_tlb_t lsize_ltlb;
    size_tlb_t lsmall_size_jtlb;
    size_tlb_t llarge_size_jtlb;
	function new(string name = "test_tlb_maintenance_all_tlb_small_size_page_tmm_en", uvm_component parent=null);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	endfunction : build_phase

	function void end_of_elaboration();
		super.end_of_elaboration();
		`uvm_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration
    
	task run_phase(uvm_phase phase);
        exception_t enabled_traps[$];
	              
		super.run_phase(phase);

		`uvm_info(get_type_name(), $psprintf("Starting test 'test_tlb_maintenance_all_tlb_small_size_page_tmm_en'"), UVM_LOW)
		uvm_test_done.raise_objection(this);

        mmu_dcache.configure_slave_latencies(5,10);
        
        // Configure stall latencies
        mmu_proc_sfrreads.configure_rr_stall_lat(1,5,1,2);              
     
        fork
            begin
                mmu_dcache_default_slave_seq = mmu_dcache_slave_seq_default::type_id::create("default_slave_dcache_seq");
                mmu_dcache_default_slave_seq.start(mmu_dcache.slave.sequencer);
            end
        join_none
        
	    fork
		    begin
                priviledge_mode_random  = $urandom_range(0,1);
                configure_seq = mmucfg_configure::type_id::create($psprintf("configure_seq"));
		        mmucfg.master.sequencer.count        = 1;
		        configure_seq.v_name                 = "MMUCFG";
	            configure_seq.lmmu_enable            = 1;
	            configure_seq.lproc_in_debug         = $urandom_range(0,1);
	            configure_seq.lpriviledge_mode       = priviledge_mode_random;
	            configure_seq.lk1_64b_mode           = 0;
	            configure_seq.lsmem_ext_cfg          = 4000;
		        configure_seq.start(mmucfg.master.sequencer); 
                
		    end 
		    begin
                
                //Configure Parameters TLB               
                number_tlb      =   136;
                size_ltlb       =   {EIGHT_K,SIXTEEN_K,THIRTY_TWO_K}; 
                small_size_jtlb =   {EIGHT_K,SIXTEEN_K,THIRTY_TWO_K}; 
                large_size_jtlb =   {EIGHT_K,SIXTEEN_K,THIRTY_TWO_K};            
                trap_mode       =   FULL_TRAP; // For the mode NO_TRAP, not consider trap dimisalign yet!!               
                global_mode     =   GLOBAL_ONE;
                
                
                //Configure Parameters Dcache
                no_trapping_en  =  $urandom_range(0,1); // TBD If it is set 1, the MMU will not generate the trap dissaligne 
                number_access   =  $urandom_range(5000,10000);
                opcode_access   =  {LOAD,STORE,DZEROL,DINVALL,DTOUCHL,DINVAL,WPURGE,LDC,FDA,CWS}; 
                size_access     =  {1,2,4,8}; 
                aligned_mode    =  NO_ALIGNED;       
                enabled_traps   =  {TRAP_ALL/*,TRAP_WTC, TRAP_ATC, TRAP_PROTECT/*, TRAP_DMISALIGN, TRAP_DYSERR, TRAP_NOMAP*/};
                check_mmc_e_mode = $urandom_range(0,1);
                no_mapping_en   =  0;
                multi_mapping_en=  0;
                simple_case_en  =  1;
                tlb_mantenance_mode = {/*TLB_MAINTENANCE_DISABLE,*/TLB_WRITE_MODE,TLB_READ_MODE,/*TLB_PROBE_MODE,*/LTLB_INDEX_MODE,JTLB_INDEX_MODE/*,CHECK_TLB_WRITE_CODE,TLB_MAINTENANCE_MODE_RANDOM*/};
                
                lsize_ltlb    = size_ltlb[$urandom_range(0, (size_ltlb.size -1))];
                lsmall_size_jtlb = small_size_jtlb[$urandom_range(0, (small_size_jtlb.size -1))];
                llarge_size_jtlb = large_size_jtlb[$urandom_range(0, (large_size_jtlb.size -1))];
             
                while(llarge_size_jtlb < lsmall_size_jtlb)begin
                    lsmall_size_jtlb = small_size_jtlb[$urandom_range(0, (small_size_jtlb.size -1))];
                    llarge_size_jtlb = large_size_jtlb[$urandom_range(0, (large_size_jtlb.size -1))];
                end
                Program_Many_TLBs(number_tlb,lsize_ltlb,lsmall_size_jtlb,llarge_size_jtlb, global_mode,check_mmc_e_mode, no_mapping_en, multi_mapping_en, priviledge_mode_random, trap_mode, simple_case_en,tlb_mantenance_mode);
              
                
            end
         
		join
        #20;
		$display("\n\t\t*********************************\n\t\t    END of Test Detected\n\t\t*********************************");
		uvm_test_done.drop_objection(this);
	endtask : run_phase
    
endclass : test_tlb_maintenance_all_tlb_small_size_page_tmm_en


//Global zero always has problems. 






`endif 

