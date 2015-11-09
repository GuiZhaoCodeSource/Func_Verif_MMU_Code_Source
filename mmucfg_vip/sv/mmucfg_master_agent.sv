/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_master_agent.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_MASTER_AGENT_SV
`define MMUCFG_MASTER_AGENT_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_master_agent
//
//------------------------------------------------------------------------------

class mmucfg_master_agent extends uvm_agent;

    typedef mmucfg_master_agent mmucfg_master_agent_t;
    typedef mmucfg_master_driver mmucfg_master_driver_t;
    typedef mmucfg_master_sequencer mmucfg_master_sequencer_t;

    protected uvm_active_passive_enum is_active = UVM_ACTIVE;

    string v_name;

    mmucfg_master_driver_t    driver;
    mmucfg_master_sequencer_t sequencer;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmucfg_master_agent_t)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_string(v_name,                           UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(is_active == UVM_ACTIVE) begin
            driver = mmucfg_master_driver_t::type_id::create("driver", this);
            sequencer = mmucfg_master_sequencer_t::type_id::create("sequencer", this);
            uvm_config_db#(string)::set(this,"driver", "v_name", v_name);
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

endclass : mmucfg_master_agent

`endif
