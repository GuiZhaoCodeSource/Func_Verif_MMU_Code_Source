/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrreads_master_driver.sv
* DEVICE:    MMU_PROC_SFRREADS VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRREADS_MASTER_DRIVER_SV
`define MMU_PROC_SFRREADS_MASTER_DRIVER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_sfrreads_master_driver
//
//------------------------------------------------------------------------------

class mmu_proc_sfrreads_master_driver extends uvm_driver #(mmu_proc_sfrreads_transfer);

    typedef mmu_proc_sfrreads_master_driver mmu_proc_sfrreads_master_driver_t;
    typedef mmu_proc_sfrreads_transfer mmu_proc_sfrreads_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmu_proc_sfrreads_if mmu_proc_sfrreads_mi;

    protected int      stall_lat_0_min;
    protected int      stall_lat_0_max;
    protected int      stall_lat_1_min;
    protected int      stall_lat_1_max;

    string v_name;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_sfrreads_master_driver_t)
        `uvm_field_string(v_name,  UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_sfrreads_if mmu_proc_sfrreads_mi);
        this.mmu_proc_sfrreads_mi = mmu_proc_sfrreads_mi;
  endfunction : assign_vi

   function void configure_rr_stall_lat(int stall_lat_0_min, int stall_lat_0_max, int stall_lat_1_min, int stall_lat_1_max);
       this.stall_lat_0_min = stall_lat_0_min;
       this.stall_lat_0_max = stall_lat_0_max;
       this.stall_lat_1_min = stall_lat_1_min;
       this.stall_lat_1_max = stall_lat_1_max;
   endfunction

    // run phase
    virtual task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $psprintf("Starting driver run"), UVM_LOW)
        fork
            reset_signals();
            get_and_drive();
	        gen_rr_stall();
	   
        join
    endtask : run_phase

    // reset_signals
    virtual protected task reset_signals();
        `uvm_info(get_type_name(), $psprintf("Reseting signals"), UVM_LOW)
       
       mmu_proc_sfrreads_mi.f_sfr_read_en_i_m <= 0;
       mmu_proc_sfrreads_mi.f_sfr_read_idx_i_m <=$urandom_range('hFF,0);
    //   mmu_proc_sfrreads_mi.rr_stall_i_m <= 0;
       
    endtask : reset_signals

    // get_and_drive
    virtual protected task get_and_drive();
        `uvm_info(get_type_name(), $psprintf("get_and_drive"), UVM_LOW)
        @(negedge mmu_proc_sfrreads_mi.reset);
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

   virtual protected task gen_rr_stall();
       int stall_lat0;
       int stall_lat1;
       `uvm_info(get_type_name(), $psprintf("gen_rr_stall"), UVM_LOW)
       
       @(negedge mmu_proc_sfrreads_mi.reset);
	   forever begin
	  
           if ((stall_lat_0_min == 0) || (stall_lat_0_min > stall_lat_0_max))
             `uvm_fatal(get_type_name(), $psprintf("bad rr_stall lantencies configuration\n\t- stall_lat_0_min= %0d\n\t- stall_lat_0_max= %0d", stall_lat_0_min, stall_lat_0_max))
           if ((stall_lat_1_min == 0) || (stall_lat_1_min > stall_lat_1_max))
             `uvm_fatal(get_type_name(), $psprintf("bad rr_stall lantencies configuration\n\t- stall_lat_1_min= %0d\n\t- stall_lat_1_max= %0d", stall_lat_1_min, stall_lat_1_max))
           
           stall_lat0 = $urandom_range(stall_lat_0_min,stall_lat_0_max);
		   mmu_proc_sfrreads_mi.rr_stall_i_m<=0;
		   repeat(stall_lat0) @(posedge mmu_proc_sfrreads_mi.clock);
           
           stall_lat1 = $urandom_range(stall_lat_1_min,stall_lat_1_max);
		   mmu_proc_sfrreads_mi.rr_stall_i_m<=1;
	  	   repeat(stall_lat1) @(posedge mmu_proc_sfrreads_mi.clock);	
	   end 
     
            
   endtask : gen_rr_stall

    virtual protected task drive_transfer (mmu_proc_sfrreads_transfer_t trans);
   
	  // Wait latency before request
	  repeat(trans.req_lat) @(posedge mmu_proc_sfrreads_mi.clock);
       
	  // Drive the request
	  mmu_proc_sfrreads_mi.f_sfr_read_en_i_m <=1;
       @(negedge mmu_proc_sfrreads_mi.clock);   
	   while(mmu_proc_sfrreads_mi.rr_stall_i_m==1)		 	      	     	  	       
         @(negedge mmu_proc_sfrreads_mi.clock) ;      
            mmu_proc_sfrreads_mi.f_sfr_read_idx_i_m <= trans.f_sfr_read_idx_i;

	  // Wait one cycle
	  @(posedge mmu_proc_sfrreads_mi.clock );
	  // Reset signals
	  reset_signals();
      
	  

 
    endtask : drive_transfer

endclass : mmu_proc_sfrreads_master_driver

`endif

