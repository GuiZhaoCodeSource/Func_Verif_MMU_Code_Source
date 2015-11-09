/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_sfrwrites_env.sv
* DEVICE:    MMU_PROC_SFRWRITES VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_SFRWRITES_ENV_SV
`define MMU_PROC_SFRWRITES_ENV_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_sfrwrites_env
//
//------------------------------------------------------------------------------

class mmu_proc_sfrwrites_env extends uvm_env;

    typedef mmu_proc_sfrwrites_env mmu_proc_sfrwrites_env_t;
    typedef mmu_proc_sfrwrites_master_agent mmu_proc_sfrwrites_master_agent_t;
    typedef mmu_proc_sfrwrites_slave_agent mmu_proc_sfrwrites_slave_agent_t;

    typedef mmu_proc_sfrwrites_bus_monitor mmu_proc_sfrwrites_bus_monitor_t;

    // Control properties
    protected bit has_bus_monitor = 1;
    protected int unsigned vip_is_master = 1;
    protected string v_name;

    // The following two bits are used to control whether checks and coverage are
    // done both in the bus monitor class and the interface.
    bit intf_checks_enable = 1;
    bit intf_coverage_enable = 1;

    // Components of the environment
    mmu_proc_sfrwrites_bus_monitor_t monitor;
    mmu_proc_sfrwrites_master_agent_t master;
    mmu_proc_sfrwrites_slave_agent_t slave;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_sfrwrites_env_t)
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
            master = mmu_proc_sfrwrites_master_agent_t::type_id::create("master", this);
            uvm_config_db#(string)::set(this,"master", "v_name", v_name);
        end
        else begin
            slave = mmu_proc_sfrwrites_slave_agent_t::type_id::create("slave", this);
            uvm_config_db#(string)::set(this,"slave", "v_name", v_name);
        end
        if (has_bus_monitor == 1) begin
            monitor = mmu_proc_sfrwrites_bus_monitor_t::type_id::create("monitor", this);
            uvm_config_db#(string)::set(this,"monitor", "v_name",  v_name);
        end

    endfunction : build_phase

    function void assign_vi(virtual interface mmu_proc_sfrwrites_if mmu_proc_sfrwrites_i);
        if (vip_is_master == 1)
            master.assign_vi(mmu_proc_sfrwrites_i);
        else
            slave.assign_vi(mmu_proc_sfrwrites_i);
        if (has_bus_monitor == 1)
            monitor.assign_vi(mmu_proc_sfrwrites_i);

   endfunction : assign_vi

endclass : mmu_proc_sfrwrites_env

`endif
