/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_env.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_ENV_SV
`define MMUCFG_ENV_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_env
//
//------------------------------------------------------------------------------

class mmucfg_env extends uvm_env;

    typedef mmucfg_env mmucfg_env_t;
    typedef mmucfg_master_agent mmucfg_master_agent_t;
    typedef mmucfg_slave_agent mmucfg_slave_agent_t;

    typedef mmucfg_bus_monitor mmucfg_bus_monitor_t;

    // Control properties
    protected bit has_bus_monitor = 1;
    protected int unsigned vip_is_master = 1;
    protected string v_name;

    // The following two bits are used to control whether checks and coverage are
    // done both in the bus monitor class and the interface.
    bit intf_checks_enable = 1;
    bit intf_coverage_enable = 1;

    // Components of the environment
    mmucfg_bus_monitor_t monitor;
    mmucfg_master_agent_t master;
    mmucfg_slave_agent_t slave;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmucfg_env_t)
    `uvm_field_int   (has_bus_monitor,      UVM_ALL_ON)
    `uvm_field_int   (vip_is_master,        UVM_ALL_ON)
    `uvm_field_int   (intf_checks_enable,   UVM_ALL_ON)
    `uvm_field_int   (intf_coverage_enable, UVM_ALL_ON)
    `uvm_field_string(v_name,               UVM_ALL_ON)
    `uvm_component_utils_end

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build
    virtual function void build_phase(uvm_phase phase);
        string inst_name;

        super.build_phase(phase);
        if (vip_is_master == 1) begin
            master = mmucfg_master_agent_t::type_id::create("master", this);
            uvm_config_db#(string)::set(this,"master", "v_name", v_name);
        end
        else begin
            slave = mmucfg_slave_agent_t::type_id::create("slave", this);
            uvm_config_db#(string)::set(this,"slave", "v_name", v_name);
        end
        if (has_bus_monitor == 1) begin
            monitor = mmucfg_bus_monitor_t::type_id::create("monitor", this);
            uvm_config_db#(string)::set(this,"monitor", "v_name",  v_name);
        end

    endfunction : build_phase

    function void assign_vi(virtual interface mmucfg_if mmucfg_i);
        if (vip_is_master == 1)
            master.assign_vi(mmucfg_i);
        else
            slave.assign_vi(mmucfg_i);
        if (has_bus_monitor == 1)
            monitor.assign_vi(mmucfg_i);

   endfunction : assign_vi

endclass : mmucfg_env

`endif
