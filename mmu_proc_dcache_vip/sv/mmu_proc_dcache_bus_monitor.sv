/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_dcache_bus_monitor.sv
* DEVICE:    MMU_PROC_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_DCACHE_BUS_MONITOR_SV
`define MMU_PROC_DCACHE_BUS_MONITOR_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_dcache_bus_monitor
//
//------------------------------------------------------------------------------

class mmu_proc_dcache_bus_monitor extends uvm_monitor;

    typedef mmu_proc_dcache_bus_monitor mmu_proc_dcache_bus_monitor_t;
    typedef mmu_proc_dcache_transfer mmu_proc_dcache_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_dcache_if mmu_proc_dcache_mi;

    string v_name;
    
    event new_trans_detected;
    event pending_trans_is_empty;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_dcache_bus_monitor_t)
        `uvm_field_string(v_name, UVM_ALL_ON)
    `uvm_component_utils_end

    // Analysis ports for the item_collected and state notifier.
    uvm_analysis_port #(mmu_proc_dcache_transfer_t) item_collected_port;

    // The following property holds the transaction information currently
    // being captured (by the collect_address_phase and data_phase methods).
    protected mmu_proc_dcache_transfer_t pending_trans[$];

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_dcache_if mmu_proc_dcache_mi);
        this.mmu_proc_dcache_mi = mmu_proc_dcache_mi;
    endfunction

    // run phase
    task run_phase(uvm_phase phase);
        // Implement monitoring and log tasks

      integer fileID;
      mmu_proc_dcache_transfer_t cur_trans;
      mmu_proc_dcache_transfer_t mmu_proc_dcache_queue[$];
        
    if ((fileID = $fopen($psprintf("mmu_proc_dcache_%s.log",v_name), "w")) == 0) begin
        $display($psprintf("Error opening 'mmu_proc_dcache_%s.log' file", v_name));
    end
    @(negedge mmu_proc_dcache_mi.reset)
      forever begin
          @(posedge mmu_proc_dcache_mi.clock)           

            if ((mmu_proc_dcache_queue.size == 1) && (mmu_proc_dcache_mi.dcache_e1_grant_i_o == 1) && (mmu_proc_dcache_mi.dcache_e3_stall_i_o == 0) && (mmu_proc_dcache_mi.e2_stall_o == 0) ) begin
               
        
                mmu_proc_dcache_queue[0].e2_non_trapping_id_cancel_o = mmu_proc_dcache_mi.e2_non_trapping_id_cancel_o;
                mmu_proc_dcache_queue[0].e2_trap_nomapping_o = mmu_proc_dcache_mi.e2_trap_nomapping_o;   
                mmu_proc_dcache_queue[0].e2_trap_protection_o = mmu_proc_dcache_mi.e2_trap_protection_o;
                mmu_proc_dcache_queue[0].e2_trap_writetoclean_o = mmu_proc_dcache_mi.e2_trap_writetoclean_o;
                mmu_proc_dcache_queue[0].e2_trap_atomictoclean_o= mmu_proc_dcache_mi.e2_trap_atomictoclean_o;
                mmu_proc_dcache_queue[0].e2_trap_dmisalign_o= mmu_proc_dcache_mi.e2_trap_dmisalign_o;
                mmu_proc_dcache_queue[0].e2_trap_dsyserror_o = mmu_proc_dcache_mi.e2_trap_dsyserror_o;              
                
                $fdisplay(fileID, $psprintf("[%0d]: %0d: [%s] virtual address: 'h%0X, Size of address: %0d, Global access: %0d, E1-Non-trapping: %0d, E2-Non-trapping: %0d, Trap nomapping: %0d,  Trap protection: %0d, Trap writetoclean: %0d, Trap atomictoclean: %0d, Trap dmisalign: %0d,Trap dsyserror: %0d", $time, mmu_proc_dcache_queue[0].req_time, mmu_proc_dcache_queue[0].e1_dcache_opc, mmu_proc_dcache_queue[0].e1_dcache_virt_addr_i, mmu_proc_dcache_queue[0].e1_dcache_size_i, mmu_proc_dcache_queue[0].e1_glob_acc_i, mmu_proc_dcache_queue[0].e1_non_trapping_i, mmu_proc_dcache_queue[0].e2_non_trapping_id_cancel_o, mmu_proc_dcache_queue[0].e2_trap_nomapping_o, mmu_proc_dcache_queue[0].e2_trap_protection_o,mmu_proc_dcache_queue[0].e2_trap_writetoclean_o, mmu_proc_dcache_queue[0].e2_trap_atomictoclean_o, mmu_proc_dcache_queue[0].e2_trap_dmisalign_o, mmu_proc_dcache_queue[0].e2_trap_dsyserror_o ));
                
                mmu_proc_dcache_queue = {};
            end 
         
          if ((mmu_proc_dcache_mi.e1_dcache_req_i_m == 1) && (mmu_proc_dcache_mi.dcache_e1_grant_i_o == 1) && (mmu_proc_dcache_mi.dcache_e3_stall_i_o == 0) && (mmu_proc_dcache_mi.e2_stall_o == 0)) begin
              cur_trans = new;
              cur_trans.req_time = $time;                
              cur_trans.e1_dcache_virt_addr_i= mmu_proc_dcache_mi.e1_dcache_virt_addr_i_m;
              cur_trans.e1_glob_acc_i = mmu_proc_dcache_mi.e1_glob_acc_i_m;
              cur_trans.e1_dcache_size_i = mmu_proc_dcache_mi.e1_dcache_size_i_m;
              cur_trans.e1_non_trapping_i = mmu_proc_dcache_mi.e1_non_trapping_i_m;
              cur_trans.e1_dcache_opc = mmu_proc_dcache_mi.e1_dcache_opc_i_m;
              
              mmu_proc_dcache_queue = {mmu_proc_dcache_queue, cur_trans};
             

          end        
      end
    endtask : run_phase

 



    
endclass : mmu_proc_dcache_bus_monitor

`endif






