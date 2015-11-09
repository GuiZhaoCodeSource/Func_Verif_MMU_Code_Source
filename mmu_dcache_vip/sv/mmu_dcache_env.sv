/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_dcache_env.sv
* DEVICE:    MMU_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_DCACHE_ENV_SV
`define MMU_DCACHE_ENV_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_dcache_env
//
//------------------------------------------------------------------------------

class mmu_dcache_env extends uvm_env;

    typedef mmu_dcache_env mmu_dcache_env_t;
    typedef mmu_dcache_master_agent mmu_dcache_master_agent_t;
    typedef mmu_dcache_slave_agent mmu_dcache_slave_agent_t;

    typedef mmu_dcache_bus_monitor mmu_dcache_bus_monitor_t;

    // Control properties
    protected bit has_bus_monitor = 1;
    protected int unsigned vip_is_master = 1;
    protected string v_name;

    // The following two bits are used to control whether checks and coverage are
    // done both in the bus monitor class and the interface.
    bit intf_checks_enable = 1;
    bit intf_coverage_enable = 1;

    // Components of the environment
    mmu_dcache_bus_monitor_t monitor;
    mmu_dcache_master_agent_t master;
    mmu_dcache_slave_agent_t slave;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_dcache_env_t)
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
            master = mmu_dcache_master_agent_t::type_id::create("master", this);
            uvm_config_db#(string)::set(this,"master", "v_name", v_name);
        end
        else begin
            slave = mmu_dcache_slave_agent_t::type_id::create("slave", this);
            uvm_config_db#(string)::set(this,"slave", "v_name", v_name);
        end
        if (has_bus_monitor == 1) begin
            monitor = mmu_dcache_bus_monitor_t::type_id::create("monitor", this);
            uvm_config_db#(string)::set(this,"monitor", "v_name",  v_name);
        end

    endfunction : build_phase

    function void assign_vi(virtual interface mmu_dcache_if mmu_dcache_i);
        if (vip_is_master == 1)
           master.assign_vi(mmu_dcache_i);
        else
          slave.assign_vi(mmu_dcache_i);
        if (has_bus_monitor == 1)
          monitor.assign_vi(mmu_dcache_i);

    endfunction : assign_vi

    function void configure_slave_latencies(int unsigned e2_wk_cycles_min, int unsigned e2_wk_cycles_max);
        if (vip_is_master == 0) begin
            slave.driver.e2_wk_cycles_min = e2_wk_cycles_min;
            slave.driver.e2_wk_cycles_max = e2_wk_cycles_max;
       end
    endfunction // configure_grant_lat


endclass : mmu_dcache_env

`endif
