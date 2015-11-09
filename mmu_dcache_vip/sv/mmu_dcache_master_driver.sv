/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_master_driver.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_MASTER_DRIVER_SV
`define MMU_DCACHE_MASTER_DRIVER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_dcache_master_driver
//
//------------------------------------------------------------------------------

class mmu_dcache_master_driver extends uvm_driver #(mmu_dcache_transfer);

    typedef mmu_dcache_master_driver mmu_dcache_master_driver_t;
    typedef mmu_dcache_transfer mmu_dcache_transfer_t;
   
    
    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_dcache_if mmu_dcache_mi;
/*
    protected int      stall_lat_0_min;
    protected int      stall_lat_0_max;
    protected int      stall_lat_1_min;
    protected int      stall_lat_1_max;
*/
    string v_name;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_dcache_master_driver_t)
        `uvm_field_string(v_name,  UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_dcache_if mmu_dcache_mi);
        this.mmu_dcache_mi = mmu_dcache_mi;
    endfunction : assign_vi
/*
    function void configure_grant_lat(int stall_lat_0_min, int stall_lat_0_max, int stall_lat_1_min, int stall_lat_1_max);
        if (stall_lat_0_min == 0)
          `uvm_fatal(get_type_name(), $psprintf("Min grant latency must be greater than 0"))
        this.stall_lat_0_min = stall_lat_0_min;
        this.stall_lat_0_max = stall_lat_0_max;
        this.stall_lat_1_min = stall_lat_1_min;
        this.stall_lat_1_max = stall_lat_1_max;
    endfunction
    
*/
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
  /*      
        mmu_dcache_mi.dcache_second_acc_d_i_m    <= 0;    
        mmu_dcache_mi.dcache_e1_grant_i_m        <= 0;
        mmu_dcache_mi.dcache_e3_stall_i_m        <= 0;
   */    
    endtask : reset_signals

    // get_and_drive
    virtual protected task get_and_drive();
        `uvm_info(get_type_name(), $psprintf("get_and_drive"), UVM_LOW)
        @(negedge mmu_dcache_mi.reset);
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

/*
  virtual protected task gen_grant();
    int stall_lat0;
    int stall_lat1;
      `uvm_info(get_type_name(), $psprintf("gen_grant"), UVM_LOW)
      @(negedge mmu_dcache_mi.clock);
	  forever begin
	      
          stall_lat0 = $urandom_range(stall_lat_0_min,stall_lat_0_max);
		  mmu_dcache_mi.dcache_e1_grant_i_m<=0;
          //  mmu_dcache_mi.dcache_e3_stall_i_m      <=  0;
		  repeat(stall_lat0) @(posedge mmu_dcache_mi.clock);
          
          stall_lat1 = $urandom_range(stall_lat_1_min,stall_lat_1_max);
		  mmu_dcache_mi.dcache_e1_grant_i_m<=1;
         //  mmu_dcache_mi.dcache_e3_stall_i_m      <=  1;
	  	  repeat(stall_lat1) @(posedge mmu_dcache_mi.clock);	
	  end 
  endtask :  gen_grant 
*/
    virtual protected task drive_transfer (mmu_dcache_transfer_t trans);
      // Wait latency before request
   /*     repeat(trans.req_lat) @(posedge mmu_dcache_mi.clock);

        mmu_dcache_mi.dcache_second_acc_d_i_m  <=  trans.dcache_second_acc_d_i; 
      
    //    mmu_dcache_mi.dcache_e1_grant_i_m      <=  trans.dcache_e1_grant_i ;   
          
        mmu_dcache_mi.dcache_e3_stall_i_m      <=  trans.dcache_e3_stall_i;
        
        @(posedge mmu_dcache_mi.clock);
        reset_signals();*/
    endtask : drive_transfer

endclass : mmu_dcache_master_driver

`endif
