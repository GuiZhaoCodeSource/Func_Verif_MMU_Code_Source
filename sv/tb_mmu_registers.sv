/******************************************************************************
 *
 * MODULE:name
 * DEVICE:MMU
 * PROJECT:Functional Verification of the MMU of a multiprocessor 
 * AUTHOR:Gui ZHAO
 * DATE: 01/04/2015
 *
 * ABSTRACT:
 *
 *******************************************************************************/
`ifndef MMU_CLUSTER_REGISTER
`define MMU_CLUSTER_REGISTER

class mmu_mmc_reg extends uvm_reg;

   `uvm_object_utils(mmu_mmc_reg)
    // Register fields
    rand uvm_reg_field asn;
    rand uvm_reg_field s;
    rand uvm_reg_field dps;
    rand uvm_reg_field lps;
    rand uvm_reg_field sne;
    rand uvm_reg_field spe;
    rand uvm_reg_field ptc;
    rand uvm_reg_field idx;
    rand uvm_reg_field e;
    

    function new(string name = "mmu_mmc_reg");
    	// super.new(name, <register size>, UVM_NO_COVERAGE);
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        
        asn = uvm_reg_field::type_id::create("asn");
	// f_offset.configure(this, <size>, <lsb pos>, <access: WO, RW, RO>, <volatile=0>, <reset value>, <has reset>,
	// <is random (0 for reserved>, <individually_accessible=1>);
        asn.configure(this, 9, 0, "RW", 0, 0, 1, 1, 1);

        s = uvm_reg_field::type_id::create("s");
        s.configure(this, 1, 9, "RO", 0, 0, 1, 0, 1);

        dps = uvm_reg_field::type_id::create("dps");
        dps.configure(this, 4, 10, "RW", 0, 0, 1, 1, 1);
        
        lps = uvm_reg_field::type_id::create("lps");
        lps.configure(this, 4, 14, "RW", 0, 0, 1, 1, 1);

        sne = uvm_reg_field::type_id::create("sne");
        sne.configure(this, 1, 18, "RW", 0, 0, 1, 1, 1);

        spe = uvm_reg_field::type_id::create("spe");
        spe.configure(this, 1, 19, "RW", 0, 0, 1, 1, 1);

        ptc = uvm_reg_field::type_id::create("ptc");
        ptc.configure(this, 2, 20, "RW", 0, 0, 1, 1, 1);
        
        idx = uvm_reg_field::type_id::create("idx");
        idx.configure(this, 9, 22, "RW", 0, 0, 1, 1, 1);

        e = uvm_reg_field::type_id::create("e");
        e.configure(this, 1, 31, "RW", 0, 0, 1, 1, 1);
        
    endfunction

endclass // mmu_mmc_reg



class mmu_tel_reg extends uvm_reg;

    `uvm_object_utils(mmu_tel_reg)
    // Register fields
    rand uvm_reg_field es;
    rand uvm_reg_field cp;
    rand uvm_reg_field pa;
    rand uvm_reg_field ae;
    rand uvm_reg_field fn;
    

    function new(string name = "mmu_tel_reg");
    	// super.new(name, <register size>, UVM_NO_COVERAGE);
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();     
 
	// f_offset.configure(this, <size>, <lsb pos>, <access: WO, RW, RO>, <volatile=0>, <reset value>, <has reset>,
	// <is random (0 for reserved>, <individually_accessible=1>);
        es = uvm_reg_field::type_id::create("es");
        es.configure(this, 2, 0, "RW", 0, 0, 1, 1, 1);

        cp = uvm_reg_field::type_id::create("cp");
        cp.configure(this, 2, 2, "RW", 0, 0, 1, 1, 1);

        pa = uvm_reg_field::type_id::create("pa");
        pa.configure(this, 4, 4, "RW", 0, 0, 1, 1, 1);
        
        ae = uvm_reg_field::type_id::create("ae");
        ae.configure(this, 4, 8, "RW", 0, 0, 1, 1, 1);

        fn = uvm_reg_field::type_id::create("fn");
        fn.configure(this, 20, 12, "RW", 0, 0, 1, 1, 1);

        
    endfunction

endclass // mmu_tel_reg


class mmu_teh_reg extends uvm_reg;

    `uvm_object_utils(mmu_teh_reg)
    // Register fields
    rand uvm_reg_field asn;
    rand uvm_reg_field reserved;
    rand uvm_reg_field g;
    rand uvm_reg_field s;
    rand uvm_reg_field pn;
    

    function new(string name = "mmu_teh_reg");
    	// super.new(name, <register size>, UVM_NO_COVERAGE);
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();     
 
	// f_offset.configure(this, <size>, <lsb pos>, <access: WO, RW, RO>, <volatile=0>, <reset value>, <has reset>,
	// <is random (0 for reserved>, <individually_accessible=1>);
        asn = uvm_reg_field::type_id::create("asn");
        asn.configure(this, 9, 0, "RW", 0, 0, 1, 1, 1);

        reserved = uvm_reg_field::type_id::create("reserved");
        reserved.configure(this, 1, 9, "RO", 0, 0, 1, 0, 1);

        g = uvm_reg_field::type_id::create("g");
        g.configure(this, 1, 10, "RW", 0, 0, 1, 1, 1);
        
        s = uvm_reg_field::type_id::create("s");
        s.configure(this, 1, 11, "RW", 0, 1, 1, 1, 1);

        pn = uvm_reg_field::type_id::create("pn");
        pn.configure(this, 20, 12, "RW", 0, 0, 1, 1, 1);

        
    endfunction

endclass // mmu_teh_reg



class mmu_reg_blk extends uvm_reg_block;
   `uvm_object_utils(mmu_reg_blk)
   
    // Registers
    rand mmu_mmc_reg mmu_mmc; 
    rand mmu_tel_reg mmu_tel;
    rand mmu_teh_reg mmu_teh;
    
    uvm_reg_map MMU_MAP;

    function new(string name = "mmu_reg_blk");
       super.new(name, build_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
        // Create registers
   
        mmu_mmc = mmu_mmc_reg::type_id::create("mmu_mmc");
        mmu_mmc.configure(this);
        mmu_mmc.build();
        
      
        mmu_tel = mmu_tel_reg::type_id::create("mmu_tel");
        mmu_tel.configure(this);
        mmu_tel.build();
        
      
        mmu_teh = mmu_teh_reg::type_id::create("mmu_teh");
        mmu_teh.configure(this);
        mmu_teh.build();
	
	// Create Map
	// create_map(<name>, <base_addr>, <n_bytes of bus>, <endian>)
	MMU_MAP = create_map("MMU_MAP", 42, 'h4, UVM_LITTLE_ENDIAN);
    default_map = MMU_MAP;
	
	// Add registers in Map
	// add_reg (<register>,<offset>,<rights: WO, RW, RO>)
        
    MMU_MAP.add_reg(mmu_mmc, 'h0, "RW");  
    MMU_MAP.add_reg(mmu_tel, 'h1, "RW");  
    MMU_MAP.add_reg(mmu_teh, 'h2, "RW");
        
        lock_model();
    endfunction

endclass

/* class my_top

    uvm_reg       addr2reg[int unsigned];
    
    mmu_reg_blk   mmu_registers;

    function void build_phase(uvm_phase phase);
        uvm_reg regs[$];
    
        mmu_registers = mmu_reg_blk::type_id::create("mmu_reg");
-	mmu_registers.build();
	
	// Extract registers from Map
	mmu_registers.MMU_MAP.get_registers(regs);
	foreach(regs[i]) begin
	    reg_addr = regs[i].get_address();
	    addr2reg[reg_addr] = regs[i];
	end

    endfunction
    
    task run_phase(uvm_phase phase);
        // Reset register
	mmu_registers.mmu_mmc.reset();
	
	// Explicit Read registers
	val = mmu_registers.mmu_mmc.get();
	
	// Explicit Write registers
	mmu_registers.mmu_mmc.set(value);
	
	// Implicit Write
	mmu_registers.mmu_mmc.predict(value);
	
    endtask

endclass */

`endif
