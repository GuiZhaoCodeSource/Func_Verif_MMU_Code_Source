/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_dcache_master_driver.sv
* DEVICE:    MMU_PROC_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_DCACHE_MASTER_DRIVER_SV
`define MMU_PROC_DCACHE_MASTER_DRIVER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_dcache_master_driver
//
//------------------------------------------------------------------------------

class mmu_proc_dcache_master_driver extends uvm_driver #(mmu_proc_dcache_transfer);

    typedef mmu_proc_dcache_master_driver mmu_proc_dcache_master_driver_t;
    typedef mmu_proc_dcache_transfer mmu_proc_dcache_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_dcache_if mmu_proc_dcache_mi;

    string v_name;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_dcache_master_driver_t)
        `uvm_field_string(v_name,  UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_dcache_if mmu_proc_dcache_mi);
        this.mmu_proc_dcache_mi = mmu_proc_dcache_mi;
    endfunction : assign_vi

    // run phase
    virtual task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $psprintf("Starting driver run"), UVM_LOW)
        fork
            reset_signals();
            get_and_drive();
        join
    endtask : run_phase

    // reset_signals
    virtual protected task reset_signals();
        `uvm_info(get_type_name(), $psprintf("Reseting signals"), UVM_LOW)
        
        mmu_proc_dcache_mi.e1_dcache_req_i_m        <= 0;
        mmu_proc_dcache_mi.e1_non_trapping_i_m      <= 0;
        mmu_proc_dcache_mi.e1_dcache_size_i_m       <= 0;
        mmu_proc_dcache_mi.e1_glob_acc_i_m          <= 0;
        mmu_proc_dcache_mi.e1_dcache_virt_addr_i_m  <= 0;
        mmu_proc_dcache_mi.e1_dcache_opc_i_m        <= LOAD;

      
    endtask : reset_signals

    // get_and_drive
    virtual protected task get_and_drive();
        `uvm_info(get_type_name(), $psprintf("get_and_drive"), UVM_LOW)
        @(negedge mmu_proc_dcache_mi.reset);
        forever begin
          seq_item_port.get_next_item(req);
          if (req.v_name == v_name) begin
              $cast(rsp, req.clone());
              rsp.set_id_info(req);
              drive_transfer(rsp);
          end
          seq_item_port.item_done(rsp);
        end
    endtask : get_and_drive

  virtual protected task drive_transfer (mmu_proc_dcache_transfer_t trans);
      // Wait latency before request
      
      repeat(trans.req_lat)@(posedge mmu_proc_dcache_mi.clock);
      while (!(mmu_proc_dcache_mi.e1_dcache_req_i_m === 1 && mmu_proc_dcache_mi.e2_stall_o === 0 && mmu_proc_dcache_mi.dcache_e1_grant_i_o === 1)) begin
          @(negedge mmu_proc_dcache_mi.clock);
          if ((mmu_proc_dcache_mi.dcache_e3_stall_i_o === 0) && ( mmu_proc_dcache_mi.e2_stall_o === 0)) begin
              mmu_proc_dcache_mi.e1_dcache_req_i_m        <= 1;              
              mmu_proc_dcache_mi.e1_dcache_opc_i_m        <= trans.e1_dcache_opc;
              
              if(trans.e1_dcache_opc == WPURGE || trans.e1_dcache_opc == DINVAL) 
                mmu_proc_dcache_mi.e1_glob_acc_i_m <= 1;
              else
                mmu_proc_dcache_mi.e1_glob_acc_i_m <= 0;
            
              mmu_proc_dcache_mi.e1_dcache_virt_addr_i_m  <= trans.e1_dcache_virt_addr_i;
              if (trans.e1_dcache_opc == LOAD || trans.e1_dcache_opc == DTOUCHL)
                mmu_proc_dcache_mi.e1_non_trapping_i_m      <= trans.e1_non_trapping_i;
              else
                mmu_proc_dcache_mi.e1_non_trapping_i_m      <= 0;
              mmu_proc_dcache_mi.e1_dcache_size_i_m       <= trans.e1_dcache_size_i;
                            
          end
          else
            mmu_proc_dcache_mi.e1_dcache_req_i_m        <= 0;
          @(posedge mmu_proc_dcache_mi.clock);
      end 
       
      reset_signals();
  endtask : drive_transfer

endclass : mmu_proc_dcache_master_driver

`endif
