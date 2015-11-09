/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_slave_driver.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_SLAVE_DRIVER_SV
`define MMUCFG_SLAVE_DRIVER_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_slave_driver
//
//------------------------------------------------------------------------------

class mmucfg_slave_driver extends uvm_driver #(mmucfg_transfer);

   typedef mmucfg_slave_driver mmucfg_slave_driver_t;
   typedef mmucfg_transfer mmucfg_transfer_t;

    // The virtual interface used to drive and view HDL signals.
    protected virtual mmucfg_if mmucfg_si;

    // Add specific items
    //protected int r_req_lat_min;
    //protected int r_req_lat_max;

    // List to store pending requests
    protected mmucfg_transfer_t pending_requests[$];

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmucfg_slave_driver_t)
        //`uvm_field_int(r_req_lat_min, UVM_ALL_ON)
        //`uvm_field_int(r_req_lat_max, UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // assign the virtual interface
    function void assign_vi(virtual interface mmucfg_if mmucfg_si);
        this.mmucfg_si = mmucfg_si;
    endfunction : assign_vi

    // run phase
    virtual task run_phase(uvm_phase phase);
        fork
            reset_signals();
            get_request();
            send_response();
        join
    endtask : run_phase

    // reset_signals
    virtual protected task reset_signals();
        //mmucfg_si.reqr_s <= 0;
        //mmucfg_si.gnt_s <= 1;
    endtask : reset_signals

    // get_and_drive
    virtual protected task get_request();
        @(negedge mmucfg_si.reset);
        forever begin
            @(posedge mmucfg_si.clock);
            seq_item_port.get_next_item(req);
            extract_request(req);
            seq_item_port.item_done();
        end
    endtask : get_request

    // Implement request extraction and put it in the pending queue
    virtual protected task extract_request(mmucfg_transfer_t resp);

    endtask : extract_request

    // Implement reponses using pending queue
    virtual protected task send_response();

    endtask : send_response

endclass : mmucfg_slave_driver

`endif
