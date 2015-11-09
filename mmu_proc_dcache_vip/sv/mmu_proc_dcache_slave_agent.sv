/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_dcache_slave_agent.sv
* DEVICE:    MMU_PROC_DCACHE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_DCACHE_SLAVE_AGENT_SV
`define MMU_PROC_DCACHE_SLAVE_AGENT_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_dcache_slave_agent
//
//------------------------------------------------------------------------------

class mmu_proc_dcache_slave_agent extends uvm_agent;

    typedef mmu_proc_dcache_slave_agent mmu_proc_dcache_slave_agent_t;
    typedef mmu_proc_dcache_slave_driver mmu_proc_dcache_slave_driver_t;
    typedef mmu_proc_dcache_slave_sequencer mmu_proc_dcache_slave_sequencer_t;

    protected uvm_active_passive_enum is_active = UVM_ACTIVE;

    mmu_proc_dcache_slave_driver_t    driver;
    mmu_proc_dcache_slave_sequencer_t sequencer;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(mmu_proc_dcache_slave_agent_t)
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
            driver = mmu_proc_dcache_slave_driver_t::type_id::create("driver", this);
            sequencer = mmu_proc_dcache_slave_sequencer_t::type_id::create("sequencer", this);
        end
    endfunction : build_phase

    // connect
    function void connect_phase(uvm_phase phase);
        if(is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
     endfunction : connect_phase

    // assign the virtual interface
    function void assign_vi(virtual interface mmu_proc_dcache_if mmu_proc_dcache_si);
        if (is_active == UVM_ACTIVE) begin
            sequencer.assign_vi(mmu_proc_dcache_si);
            driver.assign_vi(mmu_proc_dcache_si);
        end
    endfunction : assign_vi

endclass : mmu_proc_dcache_slave_agent

`endif
