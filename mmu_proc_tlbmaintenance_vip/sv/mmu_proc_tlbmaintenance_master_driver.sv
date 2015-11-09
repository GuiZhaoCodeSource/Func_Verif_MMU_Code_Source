/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_tlbmaintenance_master_driver.sv
* DEVICE:    MMU_PROC_TLBMAINTENANCE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_TLBMAINTENANCE_MASTER_DRIVER_SV
`define MMU_PROC_TLBMAINTENANCE_MASTER_DRIVER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_tlbmaintenance_master_driver
//
//------------------------------------------------------------------------------

class mmu_proc_tlbmaintenance_master_driver extends uvm_driver #(mmu_proc_tlbmaintenance_transfer);

    typedef mmu_proc_tlbmaintenance_master_driver mmu_proc_tlbmaintenance_master_driver_t;
    typedef mmu_proc_tlbmaintenance_transfer mmu_proc_tlbmaintenance_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_mi;

    string v_name;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_tlbmaintenance_master_driver_t)
        `uvm_field_string(v_name,  UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_tlbmaintenance_if mmu_proc_tlbmaintenance_mi);
        this.mmu_proc_tlbmaintenance_mi = mmu_proc_tlbmaintenance_mi;
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
                                  
        mmu_proc_tlbmaintenance_mi.tlbread_i_m   <= 0;
        mmu_proc_tlbmaintenance_mi.tlbread_i_m   <= 0;
        mmu_proc_tlbmaintenance_mi.tlbwrite_i_m  <= 0;
        mmu_proc_tlbmaintenance_mi.tlbprobe_i_m  <= 0;
        mmu_proc_tlbmaintenance_mi.tlbindexl_i_m <= 0;
        mmu_proc_tlbmaintenance_mi.tlbindexj_i_m <= 0;
        mmu_proc_tlbmaintenance_mi.tlbinvald_i_m <= 0;
        mmu_proc_tlbmaintenance_mi.tlbinvali_i_m <= 0;
       

    endtask : reset_signals

    // get_and_drive
    virtual protected task get_and_drive();
        `uvm_info(get_type_name(), $psprintf("get_and_drive"), UVM_LOW)
        @(negedge mmu_proc_tlbmaintenance_mi.reset);              
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

  virtual protected task drive_transfer (mmu_proc_tlbmaintenance_transfer_t trans);
      // Wait latency before request
    int unsigned current_cancel_counter;         

      repeat(trans.req_lat)  @(posedge mmu_proc_tlbmaintenance_mi.clock);
    
      while(mmu_proc_tlbmaintenance_mi.rr_stall_mmu_o == 1 )begin
          @(posedge mmu_proc_tlbmaintenance_mi.clock);
        
      end
      
      case(trans.cmd)
        
        TLBREAD:     mmu_proc_tlbmaintenance_mi.tlbread_i_m   <= 1;
        TLBWRITE:    mmu_proc_tlbmaintenance_mi.tlbwrite_i_m  <= 1;
        TLBPROBE:    mmu_proc_tlbmaintenance_mi.tlbprobe_i_m  <= 1;
        TLBINDEXL:   mmu_proc_tlbmaintenance_mi.tlbindexl_i_m <= 1;
        TLBINDEXJ:   mmu_proc_tlbmaintenance_mi.tlbindexj_i_m <= 1;
        TLBINVALD:   mmu_proc_tlbmaintenance_mi.tlbinvald_i_m <= 1;
        TLBINVALI:   mmu_proc_tlbmaintenance_mi.tlbinvali_i_m <= 1;
        
      endcase 
    

      @(posedge mmu_proc_tlbmaintenance_mi.clock);
      
      current_cancel_counter = trans.cancel_lat;
      while(mmu_proc_tlbmaintenance_mi.f_stall_mmu_o == 1 )begin
          @(posedge mmu_proc_tlbmaintenance_mi.clock);        
          if (trans.cancel_mode == CANCEL_ALLOWED) begin
              if (current_cancel_counter == 0)
                break;
              else
                current_cancel_counter -= 1;
          end
      end
      reset_signals();
      
  endtask : drive_transfer

endclass : mmu_proc_tlbmaintenance_master_driver

`endif
