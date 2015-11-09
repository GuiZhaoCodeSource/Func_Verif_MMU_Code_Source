/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_bus_monitor.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_BUS_MONITOR_SV
`define MMU_DCACHE_BUS_MONITOR_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_dcache_bus_monitor
//
//------------------------------------------------------------------------------

class mmu_dcache_bus_monitor extends uvm_monitor;

    typedef mmu_dcache_bus_monitor mmu_dcache_bus_monitor_t;
    typedef mmu_dcache_transfer mmu_dcache_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_dcache_if mmu_dcache_mi;
    mmu_dcache_transfer_t mmu_dcache_queue[$];
    string v_name;
   
    event new_trans_detected;
    event pending_trans_is_empty;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_dcache_bus_monitor_t)
        `uvm_field_string(v_name, UVM_ALL_ON)
    `uvm_component_utils_end

    // Analysis ports for the item_collected and state notifier.
    uvm_analysis_port #(mmu_dcache_transfer_t) item_collected_port;

    // The following property holds the transaction information currently
    // being captured (by the collect_address_phase and data_phase methods).
    protected mmu_dcache_transfer_t pending_trans[$];

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_dcache_if mmu_dcache_mi);
        this.mmu_dcache_mi = mmu_dcache_mi;
    endfunction

    // run phase
    task run_phase(uvm_phase phase);
        // Implement monitoring and log tasks

      integer fileID;
        mmu_dcache_transfer_t cur_trans;
      int tep;
        
        if ((fileID = $fopen($psprintf("mmu_dcache_%s.log",v_name), "w")) == 0) begin
            $display($psprintf("Error opening 'mmu_dcache_%s.log' file", v_name));
        end
        @(negedge mmu_dcache_mi.reset)
          forever begin
              @(posedge mmu_dcache_mi.clock)           
                  
                if ((mmu_dcache_queue.size == 1) && (mmu_dcache_mi.dcache_e1_grant_i_s === 1) && (mmu_dcache_mi.dcache_e3_stall_i_s === 0) && (mmu_dcache_mi.e2_stall_m === 0) ) begin
                    
                    mmu_dcache_queue[0].e2_dcache_phys_addr_m       =  mmu_dcache_mi.e2_dcache_phys_addr_m;
                    tep=mmu_dcache_mi.e2_dcache_phys_addr_m;                     
                    mmu_dcache_queue[0].e2_dcache_cluster_per_acc_m =  mmu_dcache_mi.e2_dcache_cluster_per_acc_m;         
                    mmu_dcache_queue[0].e2_dcache_policy_m          =  mmu_dcache_mi.e2_dcache_policy_m;
                    mmu_dcache_queue[0].dcache_second_acc_d_i       =  mmu_dcache_mi.dcache_second_acc_d_i_s;                    
                    
                    $fdisplay(fileID, $psprintf("[%0d]: %0d:  virtual address: 'h%X, Size of address: %d, Return physique address: 'h%X, Second access: %0d,Cluster: %0d, Policy: %0d", $time, mmu_dcache_queue[0].req_time, mmu_dcache_queue[0].e1_dcache_virt_addr_m, mmu_dcache_queue[0].e1_dcache_size_m, mmu_dcache_queue[0].e2_dcache_phys_addr_m, mmu_dcache_queue[0].dcache_second_acc_d_i, mmu_dcache_queue[0].e2_dcache_cluster_per_acc_m, mmu_dcache_queue[0].e2_dcache_policy_m));
                 
                    mmu_dcache_queue = {};
                end 
              
              if ((mmu_dcache_mi.e1_dcache_req_m === 1)&& (mmu_dcache_mi.dcache_e1_grant_i_s === 1) && (mmu_dcache_mi.dcache_e3_stall_i_s === 0) && (mmu_dcache_mi.e2_stall_m === 0)&& (mmu_dcache_queue.size == 0)) begin
                  cur_trans = new;
                  cur_trans.req_time = $time;                
                  cur_trans.e1_dcache_virt_addr_m = mmu_dcache_mi.e1_dcache_virt_addr_m;                 
                  cur_trans.e1_dcache_size_m      = mmu_dcache_mi.e1_dcache_size_m;                   
                  mmu_dcache_queue                = {mmu_dcache_queue, cur_trans};
                  
              end        
          end
        
    endtask : run_phase


endclass : mmu_dcache_bus_monitor

`endif
