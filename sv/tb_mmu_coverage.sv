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
typedef enum {ONE_MASTER, SEVERAL_MASTERS} outstanding_masters_t;
typedef enum {ONE_ID, SEVERAL_IDS} outstanding_ids_t;
typedef enum {ONE_SLAVE, SEVERAL_SLAVES} outstanding_slaves_t;
typedef enum {SEVERAL_SIMULT_MASTERS, ALL_MASTERS} simult_masters_t;

covergroup UsedTLB(ref int unsigned index, ref bit s, ref bit g, ref byte unsigned asn, ref byte unsigned ae, ref byte unsigned pa, ref byte unsigned cp, ref byte unsigned es);
    option.per_instance = 1;
    option.name = "UsedTLB";

    TLB_index : coverpoint index {
        bins JTLB_0 = {0};
        bins JTLB_1 = {1};
        bins JTLB_2 = {2};
        bins JTLB_3 = {3};
        bins JTLB_Others = { [4:123] };
        bins JTLB_124 = {124};
        bins JTLB_125 = {125};
        bins JTLB_126 = {126};
        bins JTLB_127 = {127};
        bins LTLB_256 = {256};
        bins LTLB_257 = {257};
        bins LTLB_258 = {258};
        bins LTLB_259 = {259};
        bins LTLB_260 = {260};
        bins LTLB_261 = {261};
        bins LTLB_262 = {262};
        bins LTLB_263 = {263};
        bins No_Available_TLB = {[128:255]};
    }
    TLB_S     : coverpoint s;
    TLB_G     : coverpoint g;
    TLB_ASN   : coverpoint asn;


    TEL_AE     : coverpoint ae {
        bins AE_0 = {0};
        bins AE_1 = {1};
        bins AE_2 = {2};
        bins AE_3 = {3};
        bins AE_4 = {4};
        bins AE_5 = {5};
        bins AE_6 = {6};
        bins AE_7 = {7};
        bins AE_8 = {8};
        bins AE_9 = {9};
        bins AE_10 = {10};
        bins AE_11 = {11};
        bins AE_12 = {12};
        bins AE_13 = {13};
        bins AE_14 = {14};
        bins AE_15 = {15};
        // illegal_bins ILLEGAL = default;
    }
    TEL_PA     : coverpoint pa {
        
        bins PA_0 = {0};
        bins PA_1 = {1};
        bins PA_2 = {2};
        bins PA_3 = {3};
        bins PA_4 = {4};
        bins PA_5 = {5};
        bins PA_6 = {6};
        bins PA_7 = {7};
        bins PA_8 = {8};
        bins PA_9 = {9};
        bins PA_10 = {10};
        bins PA_11 = {11};
        bins PA_12 = {12};
        bins PA_13 = {13};
             
    }
    TEL_CP     : coverpoint cp {
        bins CP_0 = {0};
        bins CP_1 = {1};
        bins CP_2 = {2};
        bins CP_3 = {3}; 
    }
    TEL_ES     : coverpoint es {
        bins ES_0 = {0};  
        bins ES_1 = {1};
        bins ES_2 = {2};
        bins ES_3 = {3};
    }
    
    TEL_COV   : cross TEL_AE , TEL_PA, TEL_CP, TEL_ES;
    TLB_Cov   : cross TLB_index, TLB_S, TLB_G, TLB_ASN;

endgroup


covergroup PageSize(ref int unsigned index, ref longint unsigned page_size_tlb, ref int unsigned page_position);
    option.per_instance = 1;
    option.name = "PageSize";

    
    TLB_index : coverpoint index {
        bins JTLB_0 = {0};
        bins JTLB_1 = {1};
        bins JTLB_2 = {2};
        bins JTLB_3 = {3};
        bins JTLB_Others = { [4:123] };     
        bins JTLB_124 = {124};
        bins JTLB_125 = {125};
        bins JTLB_126 = {126};
        bins JTLB_127 = {127};
        bins LTLB_256 = {256};
        bins LTLB_257 = {257};
        bins LTLB_258 = {258};
        bins LTLB_259 = {259};
        bins LTLB_260 = {260};
        bins LTLB_261 = {261};
        bins LTLB_262 = {262};
        bins LTLB_263 = {263};
        bins No_Available_TLB = {[128:255]};
    }
    
    TLB_Page_Size     : coverpoint page_size_tlb {
        bins Page_Size_4K = {2**12};
        bins Page_Size_8K = {2**13};
        bins Page_Size_16K = {2**14};
        bins Page_Size_32K = {2**15};
        bins Page_Size_64K = {2**16};
        bins Page_Size_128K = {2**17};
        bins Page_Size_256K = {2**18};
        bins Page_Size_512K = {2**19};
        
        bins Page_Size_1M = {2**20};
        bins Page_Size_2M = {2**21};       
        bins Page_Size_4M = {2**22};
        bins Page_Size_8M = {2**23};
        bins Page_Size_16M = {2**24};
        bins Page_Size_32M = {2**25};
        bins Page_Size_64M = {2**26};
        bins Page_Size_128M = {2**27};
        bins Page_Size_256M = {2**28};
        bins Page_Size_512M = {2**29};
        
        bins Page_Size_1G = {2**30};
        bins Page_Size_2G = {2**31};
    }

    Page_Virt_Address_Position: coverpoint page_position {
        bins Page_Top    = {1};
        bins Page_Others = {2};
        bins Page_Bottom = {3};
    }
   
    
    TLB_Index_Page_Size_Cov   : cross TLB_index, TLB_Page_Size, Page_Virt_Address_Position;

endgroup 


covergroup PageContinu(ref longint unsigned page_size_tlb, ref longint unsigned next_page_size_tlb);
    option.per_instance = 1;
    option.name = "PageContinu";

    
    TLB_Page_Size     : coverpoint page_size_tlb {
        bins Page_Size_4K = {2**12};
        bins Page_Size_8K = {2**13};
        bins Page_Size_16K = {2**14};
        bins Page_Size_32K = {2**15};
        bins Page_Size_64K = {2**16};
        bins Page_Size_128K = {2**17};
        bins Page_Size_256K = {2**18};
        bins Page_Size_512K = {2**19};
        
        bins Page_Size_1M = {2**20};
        bins Page_Size_2M = {2**21};       
        bins Page_Size_4M = {2**22};
        bins Page_Size_8M = {2**23};
        bins Page_Size_16M = {2**24};
        bins Page_Size_32M = {2**25};
        bins Page_Size_64M = {2**26};
        bins Page_Size_128M = {2**27};
        bins Page_Size_256M = {2**28};
        bins Page_Size_512M = {2**29};
        
        bins Page_Size_1G = {2**30};
        bins Page_Size_2G = {2**31};
        bins Page_No_Mapping   = {0};
    }

    
    Next_TLB_Page_Size     : coverpoint next_page_size_tlb {
    
        bins Next_Page_Size_4K = {2**12};
        bins Next_Page_Size_8K = {2**13};
        bins Next_Page_Size_16K = {2**14};
        bins Next_Page_Size_32K = {2**15};
        bins Next_Page_Size_64K = {2**16};
        bins Next_Page_Size_128K = {2**17};
        bins Next_Page_Size_256K = {2**18};
        bins Next_Page_Size_512K = {2**19};
        
        bins Next_Page_Size_1M = {2**20};
        bins Next_Page_Size_2M = {2**21};       
        bins Next_Page_Size_4M = {2**22};
        bins Next_Page_Size_8M = {2**23};
        bins Next_Page_Size_16M = {2**24};
        bins Next_Page_Size_32M = {2**25};
        bins Next_Page_Size_64M = {2**26};
        bins Next_Page_Size_128M = {2**27};
        bins Next_Page_Size_256M = {2**28};
        bins Next_Page_Size_512M = {2**29};
        
        bins Next_Page_Size_1G = {2**30};
        bins Next_Page_Size_2G = {2**31};
        
        bins Next_Page_No_Mapping = {0};
    }

    
    TLB_Page_Continu_Cov   : cross TLB_Page_Size, Next_TLB_Page_Size;

endgroup 


covergroup DpsLps(ref byte unsigned dps, ref byte unsigned lps);
    option.per_instance = 1;
    option.name = "DpsLps";

    TLB_DPS     : coverpoint dps {
        bins DPS_0 = {0};
        bins DPS_1 = {1};
        bins DPS_2 = {2};
        bins DPS_3 = {3};
        bins DPS_4 = {4};
        bins DPS_5 = {5};
        bins DPS_6 = {6};
        bins DPS_7 = {7};
        bins DPS_8 = {8};
        bins DPS_9 = {9};
        bins DPS_10 = {10};
        bins DPS_11 = {11};
        bins DPS_12 = {12};
        bins DPS_13 = {13};
        bins DPS_14 = {14};
        bins DPS_15 = {15};
    }
    
    TLB_LPS     : coverpoint lps {
        bins LPS_0 = {0};
        bins LPS_1 = {1};
        bins LPS_2 = {2};
        bins LPS_3 = {3};
        bins LPS_4 = {4};
        bins LPS_5 = {5};
        bins LPS_6 = {6};
        bins LPS_7 = {7};
        bins LPS_8 = {8};
        bins LPS_9 = {9};
        bins LPS_10 = {10};
        bins LPS_11 = {11};
        bins LPS_12 = {12};
        bins LPS_13 = {13};
        bins LPS_14 = {14};
        bins LPS_15 = {15};
    }
    
    
    TLB_DPS_LPS_Cov   : cross TLB_DPS,TLB_LPS;

endgroup

covergroup UsedTLBPnFn(ref int unsigned pn, ref int unsigned fn);
    option.per_instance = 1;
    option.name = "UsedTLBPN";

    TLB_PN     : coverpoint pn {
       // bins PN = {[0: 2**20]};
      //  illegal_bins ILLEGAL = {[2**20:2**32]};
    }
    TLB_FN     : coverpoint fn {
      //  bins FN = {[0: 2**20]};
      //  illegal_bins ILLEGAL = {[2**20:2**32]};
    }

endgroup 



class tb_mmu_coverage extends uvm_component;

    typedef tb_mmu_coverage tb_mmu_coverage_t;

    `uvm_component_param_utils(tb_mmu_coverage_t)

    // Declare all signals used for coverage
  int unsigned index_cov;
  bit s_cov, g_cov;
  byte unsigned asn_cov;
    
  longint unsigned page_size_tlb_cov;
  longint unsigned next_page_size_tlb_cov;
  byte    unsigned dps_cov, lps_cov;
  int     unsigned page_position_cov;
    
 // bit     continueus_flag_cov;
    
  byte    unsigned ae_cov, pa_cov, cp_cov, es_cov;
  int     unsigned pn_cov;
  int     unsigned fn_cov;
    
    // Instanciate covergroups
    
    UsedTLB  UsedTLB_cov;
    PageSize PageSize_cov;
    DpsLps DpsLps_cov; 
    UsedTLBPnFn UsedTLBPnFn_cov;
    PageContinu PageContinu_cov;
    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    function void end_of_elaboration();

        // New of covergroups
        // Link covergroup inputs with coverage signals
        UsedTLB_cov  = new( index_cov, s_cov, g_cov, asn_cov, ae_cov, pa_cov, cp_cov, es_cov);
        PageSize_cov = new(index_cov, page_size_tlb_cov, page_position_cov);
        DpsLps_cov   = new(dps_cov,lps_cov);            
        UsedTLBPnFn_cov = new(pn_cov,fn_cov);
        PageContinu_cov = new(page_size_tlb_cov, next_page_size_tlb_cov);
    endfunction : end_of_elaboration

  virtual task run_phase(uvm_phase phase);
  endtask : run_phase

endclass

