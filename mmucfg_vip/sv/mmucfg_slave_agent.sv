/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_slave_agent.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_SLAVE_AGENT_SV
`define MMUCFG_SLAVE_AGENT_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_slave_agent
//
//------------------------------------------------------------------------------

class mmucfg_slave_agent extends uvm_agent;

    typedef mmucfg_slave_agent mmucfg_slave_agent_t;
    typedef mmucfg_slave_driver mmucfg_slave_driver_t;
    typedef mmucfg_slave_sequencer mmucfg_slave_sequencer_t;

    protected uvm_active_passive_enum is_active = UVM_ACTIVE;

    mmucfg_slave_driver_t    driver;
    mmucfg_slave_sequencer_t sequencer;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmucfg_slave_agent_t)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(is_active == UVM_ACTIVE) begin
            driver = mmucfg_slave_driver_t::type_id::create("driver", this);
            sequencer = mmucfg_slave_sequencer_t::type_id::create("sequencer", this);
        end
    endfunction : build_phase

    // connect
    function void connect_phase(uvm_phase phase);
        if(is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
     endfunction : connect_phase

    // assign the virtual interface
    function void assign_vi(virtual interface mmucfg_if mmucfg_si);
        if (is_active == UVM_ACTIVE) begin
            sequencer.assign_vi(mmucfg_si);
            driver.assign_vi(mmucfg_si);
        end
    endfunction : assign_vi

endclass : mmucfg_slave_agent

`endif
