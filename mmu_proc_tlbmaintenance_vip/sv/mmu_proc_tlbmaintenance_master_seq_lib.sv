/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmu_proc_tlbmaintenance_master_seq_lib.sv
* DEVICE:    MMU_PROC_TLBMAINTENANCE VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMU_PROC_TLBMAINTENANCE_MASTER_SEQ_LIB_SV
`define MMU_PROC_TLBMAINTENANCE_MASTER_SEQ_LIB_SV

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_tlbmaintenance_master_base_sequence
//
//------------------------------------------------------------------------------

class mmu_proc_tlbmaintenance_master_base_sequence extends uvm_sequence #(mmu_proc_tlbmaintenance_transfer);

    typedef mmu_proc_tlbmaintenance_master_sequencer mmu_proc_tlbmaintenance_master_sequencer_t;
    typedef mmu_proc_tlbmaintenance_transfer mmu_proc_tlbmaintenance_transfer_t;

    `uvm_object_param_utils(mmu_proc_tlbmaintenance_master_base_sequence)

    string v_name;
   
    // new - constructor
    function new(string name="mmu_proc_tlbmaintenance_master_base_sequence");
        super.new(name);
    endfunction : new

    // Raise in pre_body so the objection is only raised for root sequences.
    // There is no need to raise for sub-sequences since the root sequence
    // will encapsulate the sub-sequence.
    virtual task pre_body();
        m_sequencer.uvm_report_info(get_type_name(), $psprintf("%s pre_body() raising an uvm_test_done objection", get_sequence_path()), UVM_HIGH);
        uvm_test_done.raise_objection(this);
    endtask
    // Drop the objection in the post_body so the objection is removed when
    // the root sequence is complete.
    virtual task post_body();
        m_sequencer.uvm_report_info(get_type_name(), $psprintf("%s post_body() dropping an uvm_test_done objection", get_sequence_path()), UVM_HIGH);
        uvm_test_done.drop_objection(this);
    endtask // post_body
endclass : mmu_proc_tlbmaintenance_master_base_sequence

//------------------------------------------------------------------------------
//
// CLASS: mmu_proc_tlbmaintenance_standby_seq
//
//------------------------------------------------------------------------------

class mmu_proc_tlbmaintenance_standby_seq extends mmu_proc_tlbmaintenance_master_base_sequence;

    `uvm_object_param_utils(mmu_proc_tlbmaintenance_standby_seq)

    // new - constructor
    function new(string name="mmu_proc_tlbmaintenance_standby_seq");
        super.new(name);
    endfunction : new

    // Implment behavior sequence
    virtual task body();

    endtask // body

endclass : mmu_proc_tlbmaintenance_standby_seq

//------------------------------------------------------------------------------
// Example sequence
// CLASS: mmu_proc_tlbmaintenance_trial_seq
//
//------------------------------------------------------------------------------

class tlbmaintenance_seq extends mmu_proc_tlbmaintenance_master_base_sequence;

    `uvm_object_param_utils(tlbmaintenance_seq)

    // Add sequence parameters
    int unsigned lreq_lat;
    tlb_maintenance_cmd_t lcmd;
    cancel_mode_t lcancel_mode;
    int unsigned  lcancel_lat;
    

    // new - constructor
    function new(string name="mmu_proc_tlbmaintenance_trial_seq");
        super.new(name);
    endfunction : new

    mmu_proc_tlbmaintenance_transfer_t mmu_proc_tlbmaintenance_trans;

    // Implment behavior sequence
    virtual task body();
    `uvm_info(get_type_name(), $psprintf("Start sequence mmu_proc_tlbmaintenance_trial_seq"), UVM_LOW)
    $cast(mmu_proc_tlbmaintenance_trans, create_item(mmu_proc_tlbmaintenance_transfer_t::type_id::get(), m_sequencer, "mmu_proc_tlbmaintenance_trans"));
    start_item(mmu_proc_tlbmaintenance_trans);
   
    mmu_proc_tlbmaintenance_trans.v_name = v_name;
        
    if (!(mmu_proc_tlbmaintenance_trans.randomize() with {
        // Transmit sequence paramaters
       mmu_proc_tlbmaintenance_trans.req_lat == lreq_lat;
       mmu_proc_tlbmaintenance_trans.cancel_lat== lcancel_lat; 
       mmu_proc_tlbmaintenance_trans.cmd     == lcmd;                                                 
       mmu_proc_tlbmaintenance_trans.cancel_mode == lcancel_mode; 
      
                
          }))
      `uvm_fatal(get_type_name(), $psprintf("mmu_proc_tlbmaintenance_trial_seq: randomization error"))
    finish_item(mmu_proc_tlbmaintenance_trans);
    `uvm_info(get_type_name(), "End sequence mmu_proc_tlbmaintenance_trial_seq", UVM_LOW)
  endtask // body
endclass : tlbmaintenance_seq
`endif
