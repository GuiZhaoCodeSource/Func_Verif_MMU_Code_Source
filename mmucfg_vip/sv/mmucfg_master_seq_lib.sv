/******************************************************************************
* (C) Copyright 2011 KALRAY SA All Rights Reserved
*
* MODULE:    mmucfg_master_seq_lib.sv
* DEVICE:    MMUCFG VIP
* PROJECT:
* AUTHOR:
* DATE:
*
* ABSTRACT:
*
*******************************************************************************/
`ifndef MMUCFG_MASTER_SEQ_LIB_SV
`define MMUCFG_MASTER_SEQ_LIB_SV

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_master_base_sequence
//
//------------------------------------------------------------------------------

class mmucfg_master_base_sequence extends uvm_sequence #(mmucfg_transfer);

   typedef mmucfg_master_sequencer mmucfg_master_sequencer_t;
   typedef mmucfg_transfer mmucfg_transfer_t;

    `uvm_object_param_utils(mmucfg_master_base_sequence)

    string v_name;

    // new - constructor
    function new(string name="mmucfg_master_base_sequence");
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
endclass : mmucfg_master_base_sequence

//------------------------------------------------------------------------------
//
// CLASS: mmucfg_standby_seq
//
//------------------------------------------------------------------------------

class mmucfg_standby_seq extends mmucfg_master_base_sequence;

    `uvm_object_param_utils(mmucfg_standby_seq)

    // new - constructor
    function new(string name="mmucfg_standby_seq");
        super.new(name);
    endfunction : new

    // Implment behavior sequence
    virtual task body();

    endtask // body

endclass : mmucfg_standby_seq

//------------------------------------------------------------------------------
// Example sequence
// CLASS: mmucfg_trial_seq
//
//------------------------------------------------------------------------------

class mmucfg_configure extends mmucfg_master_base_sequence;

    `uvm_object_param_utils(mmucfg_configure)

    // Add sequence parameters
    bit lmmu_enable;
    int lproc_in_debug;
    int lpriviledge_mode;
    int lk1_64b_mode;
    logic[4:0] lsmem_ext_cfg;

    // new - constructor
    function new(string name="mmucfg_configure");
        super.new(name);
    endfunction : new

    mmucfg_transfer_t mmucfg_trans;

    // Implment behavior sequence
    virtual task body();
    `uvm_info(get_type_name(), $psprintf("Start sequence mmucfg_configure"), UVM_LOW)
    $cast(mmucfg_trans, create_item(mmucfg_transfer_t::type_id::get(), m_sequencer, "mmucfg_trans"));
    start_item(mmucfg_trans);
    if (!(mmucfg_trans.randomize() with {
        // Transmit sequence paramaters
	     mmucfg_trans.mmu_enable == lmmu_enable;
	     mmucfg_trans.proc_in_debug == lproc_in_debug;
	     mmucfg_trans.priviledge_mode == lpriviledge_mode;
	     mmucfg_trans.k1_64b_mode == lk1_64b_mode;
	     mmucfg_trans.smem_ext_cfg == lsmem_ext_cfg;
					 
            	        
             			 
          }))
      `uvm_fatal(get_type_name(), $psprintf("mmucfg_trial_seq: randomization error"))
    mmucfg_trans.v_name = v_name;
    finish_item(mmucfg_trans);
    `uvm_info(get_type_name(), "End sequence mmucfg_trial_seq", UVM_LOW)
  endtask // body
endclass : mmucfg_configure
`endif
