/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_slave_driver.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_SLAVE_DRIVER_SV
`define MMU_DCACHE_SLAVE_DRIVER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_dcache_slave_driver
//
//------------------------------------------------------------------------------
//`include "tb_mmu_refmodel.sv"
//`include "tb_mppa_proc_tests.sv"

class mmu_dcache_slave_driver extends uvm_driver #(mmu_dcache_transfer);

    typedef mmu_dcache_slave_driver mmu_dcache_slave_driver_t;
    typedef mmu_dcache_transfer mmu_dcache_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_dcache_if mmu_dcache_si;

    // Add specific items
    int unsigned e2_wk_cycles_min;
    int unsigned e2_wk_cycles_max;
    
    // List to store pending requests
    protected mmu_dcache_transfer_t pending_requests[$];

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_dcache_slave_driver_t)
        //`uvm_field_int(r_req_lat_min, UVM_ALL_ON)
        //`uvm_field_int(r_req_lat_max, UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_dcache_if mmu_dcache_si);
        this.mmu_dcache_si = mmu_dcache_si;
    endfunction : assign_vi

    // run phase
    virtual task run_phase(uvm_phase phase);       
       fork
           reset_signals();
           get_request();
           e2_management();
        join
    endtask : run_phase

    // reset_signals
    virtual protected task reset_signals();      
        mmu_dcache_si.dcache_e1_grant_i_s     <= 1;
        mmu_dcache_si.dcache_second_acc_d_i_s <= 0;
        mmu_dcache_si.dcache_e3_stall_i_s     <= 0;
    endtask : reset_signals

    // get_and_drive
    virtual protected task get_request();
        @(negedge mmu_dcache_si.reset);
        forever begin
            @(posedge mmu_dcache_si.clock);           
            seq_item_port.get_next_item(req);         
            extract_e1_request(req);       
            seq_item_port.item_done();
        end
    endtask : get_request

    // Implement request extraction and put it in the pending queue
    virtual protected task extract_e1_request(mmu_dcache_transfer_t resp);       
        
        wait(mmu_dcache_si.e1_dcache_req_m === 1  &&  mmu_dcache_si.dcache_e1_grant_i_s === 1);
        @(posedge mmu_dcache_si.clock);
        resp.e1_dcache_virt_addr_m = mmu_dcache_si.e1_dcache_virt_addr_m;     
        resp.e1_dcache_size_m      = mmu_dcache_si.e1_dcache_size_m;
        resp.e1_dcache_opc_i       = mmu_dcache_si.e1_dcache_opc_i_m;

      
        
        pending_requests = {pending_requests, resp};
     
    endtask : extract_e1_request

    // Implement reponses using pending queue
    virtual protected task e2_management();
        
      bit   e2_is_stalled;
      bit   e3_stall_en;
      bit   second_access;
      int   unsigned e2_wk_cycles;
      int   unsigned e3_stall_cycles;
      logic [40:0]   check_virt_address;
      int            n;
      logic          virt_page;
      int            found_index;
      int            traps_cnt;
     
        forever begin
                        
            wait(pending_requests.size() == 1);
            n++;            
            check_virt_address = pending_requests[0].e1_dcache_virt_addr_m + pending_requests[0].e1_dcache_size_m - 1;
            virt_page=pending_requests[0].e1_dcache_virt_addr_m >> 12;
          //  $display("[%0d]: ZGDcache : e1_dcache_virt_addr_m virt adress %X chek virt address %X",$time, mmu_dcache_si.e1_dcache_virt_addr_m,check_virt_address );
       
            if (((pending_requests[0].e1_dcache_virt_addr_m[40:6]) != (check_virt_address[40:6])) && (pending_requests[0].e1_dcache_opc_i != DZEROL))begin
                second_access = 1;    
               // $display("[%0d] ZGS3:after request second access : opcode =%s",$time,pending_requests[0].e1_dcache_opc_i);                          
            end         
            else second_access = 0;
            
// How to use the value of CP of the TLB ARRAY into the VIP DCACHE
        /*    for(int i=0;i<264;i++)begin
                
                if((mmu_refmodel.tlb_array[i].pn == virt_page) && (mmu_refmodel.tlb_array[i].asn == mmu_refmodel.tlb_array[i].asn_mmc))begin
                    found_index = i;                                          
                end       
                
            end
            if(mmu_refmodel.tlb_array[found_index].cp == 2) second_access = 1;    
            */
 
           
           // $display("[%0d] GZ-second_access=%0d trap protection: %0d", $time, second_access, mmu_dcache_si.e2_trap_protection_o);

            // First step: manage D$ E2 internal stall (gnt is set to 0) + possibly e3_stall send to MMU
            e2_is_stalled = $urandom_range(0,1);
            if (second_access == 1)
              e2_is_stalled = 1;
            if (e2_is_stalled == 1) begin          
                mmu_dcache_si.dcache_e1_grant_i_s <= 0;
                @(posedge mmu_dcache_si.clock);
                e3_stall_en = $urandom_range(0,1);
                if (e3_stall_en == 1) begin                 
                    mmu_dcache_si.dcache_e3_stall_i_s <= 1;
                end
                e2_wk_cycles = $urandom_range(e2_wk_cycles_max, e2_wk_cycles_min);
                e3_stall_cycles = $urandom_range(e2_wk_cycles_max, e2_wk_cycles_min);
                while (e2_wk_cycles > 0) begin
                    @(posedge mmu_dcache_si.clock);               
                    e2_wk_cycles -= 1;
                    if (e3_stall_cycles > 0)
                      e3_stall_cycles -= 1;
                    else
                      mmu_dcache_si.dcache_e3_stall_i_s <= 0;
                end
            end 
            // Second strep: Check if MMU has already send the response (addr + trap)
            while (mmu_dcache_si.e2_stall_m == 1)
              @(posedge mmu_dcache_si.clock);
            
            // Possibly third step => second access if no trap
            traps_cnt = 0;
            traps_cnt += mmu_dcache_si.e2_trap_nomapping_o;
            traps_cnt += mmu_dcache_si.e2_trap_protection_o;
            traps_cnt += mmu_dcache_si.e2_trap_writetoclean_o;
            traps_cnt += mmu_dcache_si.e2_trap_atomictoclean_o;
            traps_cnt += mmu_dcache_si.e2_trap_dmisalign_o;
            traps_cnt += mmu_dcache_si.e2_trap_dsyserror_o;
            
       /*     if(mmu_dcache_si.e2_dcache_policy_m == 1)
              second_access = 1;*/
            if(traps_cnt >0)
              second_access = 0;
          //  $display("GZDca:second_access : %0d,traps_cnt :%0d ",second_access,traps_cnt);
            if (second_access == 1) begin
            //    $display("%0d: ZG: bedore second access management", $time);                                              
            //    $display("GZtrap protection: %0d",mmu_dcache_si.e2_trap_protection_o);
                if ((second_access == 1) && (mmu_dcache_si.e2_trap_protection_o == 0)) begin
                    mmu_dcache_si.dcache_second_acc_d_i_s <= 1;
                    @(posedge mmu_dcache_si.clock);
                    mmu_dcache_si.dcache_second_acc_d_i_s <= 0;
                    e2_is_stalled = $urandom_range(0,1);
                    if (e2_is_stalled == 1) begin
                        e3_stall_en = $urandom_range(0,1);
                        if (e3_stall_en == 1) begin                  
                            mmu_dcache_si.dcache_e3_stall_i_s <= 1;
                        end
                        e2_wk_cycles = $urandom_range(e2_wk_cycles_max, e2_wk_cycles_min);
                        e3_stall_cycles = $urandom_range(e2_wk_cycles_max, e2_wk_cycles_min);
                        while (e2_wk_cycles > 0) begin
                            @(posedge mmu_dcache_si.clock);                     
                            e2_wk_cycles -= 1;
                            if (e3_stall_cycles > 0)
                              e3_stall_cycles -= 1;
                            else
                              mmu_dcache_si.dcache_e3_stall_i_s <= 0;
                        end
                    end 
                end
            end                                             
            mmu_dcache_si.dcache_e1_grant_i_s <= 1;
            while (e3_stall_en == 1 && e3_stall_cycles > 0)
              e3_stall_cycles -= 1;
            mmu_dcache_si.dcache_e3_stall_i_s <= 0;
            @(posedge mmu_dcache_si.clock);
           // $display("%0d: ZG: pending request size %d",$time, pending_requests.size());
            pending_requests.delete(0);
            
        end
        
        
    endtask : e2_management

endclass : mmu_dcache_slave_driver

`endif
