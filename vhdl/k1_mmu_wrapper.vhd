-- *******************************************************************************
--                             KALRAY-SA
--     Reproduction and Communication of this document is strictly prohibited 
--       unless specifically authorized in writing by KALRAY-SA.
-- 
-- ******************************************************************************

library ieee;
 
library lib_mppa_package_vhdl;
use     lib_mppa_package_vhdl.mppa_function_package.all;
use     lib_mppa_package_vhdl.mppa_smem_package.all;
use     lib_mppa_package_vhdl.mppa_mmu_package.all;
use     lib_mppa_package_vhdl.mppa_proc_package.all;

library lib_mppa_proc_mmu_vhdl;
use     lib_mppa_proc_mmu_vhdl.all;

library lib_mppa_mem_cut_vlog;
use     lib_mppa_mem_cut_vlog.all;

library lib_mppa_proc_mmu_vhdl;
use     lib_mppa_proc_mmu_vhdl.all;

use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_arith.all;
use ieee.STD_LOGIC_misc.all;

entity k1_mmu_wrapper is
  generic(
    IO_MAP             : boolean := false;
    i_utlb_nb_words    : integer := 4;
    d_utlb_nb_words    : integer := 4;
    l2_ltlb_nb_entries : integer := 8;
    l2_jtlb_nb_line    : integer := 64;
    pa_nbbits          : integer := 22  -- default for FN field is 21 downto 0 (2MB + 2MB smem no PAE)
    );

  port (
    clk   : in std_logic;
    reset : in std_logic;
    
    mmu_enable_i         : in std_logic;
    processor_in_debug_i : in std_logic;
    k1_64_mode_i         : in std_logic;

    -- maintenance instructions interface with core
    tlbread_i        : in  std_logic;
    tlbwrite_i       : in  std_logic;
    tlbprobe_i       : in  std_logic;
    tlbindexl_i      : in  std_logic;
    tlbindexj_i      : in  std_logic;
    tlbinvald_i      : in  std_logic;
    tlbinvali_i      : in  std_logic;
    f_stall_mmu_o    : out std_logic;
    rr_stall_mmu_o   : out std_logic;

    -- data side proc interface
    e1_dcache_req_i       : in std_logic;
    dcache_e3_stall_i     : in std_logic;
    e1_dcache_virt_addr_i : in std_logic_vector(40 downto 0);
    e1_dcache_opc_i       : in std_logic_vector(5 downto 0);
    e1_glob_acc_i         : in std_logic;
    e1_dcache_size_i      : in std_logic_vector(3 downto 0);
    e1_non_trapping_i     : in std_logic;
    
    e2_non_trapping_ld_cancel_o : out std_logic;
    e2_trap_nomapping_o         : out std_logic_vector(1 downto 0);
    e2_trap_protection_o        : out std_logic_vector(1 downto 0);
    e2_trap_writetoclean_o      : out std_logic_vector(1 downto 0);
    e2_trap_atomictoclean_o     : out std_logic_vector(1 downto 0);
    e2_trap_dmisalign_o         : out std_logic;
    e2_trap_dsyserror_o         : out std_logic_vector(1 downto 0);

    -- interface with dcache
    e2_dcache_phys_addr_o       : out std_logic_vector(pa_nbbits-1 downto 12);
    e2_dcache_cluster_per_acc_o : out std_logic;
    e2_dcache_policy_o          : out std_logic;
    e2_stall_o                  : out std_logic;
    dcache_e1_grant_i           : in  std_logic;
    dcache_second_acc_d_i       : in  std_logic;

    -- instruction side proc/cache interface
    icache_req_i             : in  std_logic;
    icache_cancel_i          : in  std_logic;
    icache_virt_addr_i       : in  std_logic_vector(40 downto 2);
    icache_phys_addr_o       : out std_logic_vector(pa_nbbits-1 downto 12);
    icache_cluster_per_acc_o : out std_logic;

    icache_datar_v_hacked_o : out std_logic_vector(3 downto 0);
    gate_icache_req_o       : out std_logic;
    gate_icache_grant_o     : out std_logic;
    ins_trap_nomapping_o    : out std_logic;
    ins_trap_protection_o   : out std_logic;
    ins_trap_psyserror_o    : out std_logic;

    -- interface with icache
    icache_grant_i       : in  std_logic;
    icache_datar_v_i     : in  std_logic_vector(3 downto 0);
    icache_replay_req_o  : out std_logic;
    icache_replay_addr_o : out std_logic_vector(40 downto 2);
    force_i_hit_o        : out std_logic;
    i_cached_acc_o       : out std_logic;

    -- Far SFR interface
    -----------------------------------------------------------------------
    -- Core write interface
    -----------------------------------------------------------------------
    cpu_wr_reg_idx_i : in  std_logic_vector(7 downto 0);
    cpu_wr_reg_val_i : in  std_logic_vector(31 downto 0);
    cpu_wr_reg_cmd_i : in  std_logic_vector(1 downto 0);
    privilege_mode_i : in  std_logic;
    cpu_wr_reg_en_i  : in  std_logic;

    -----------------------------------------------------------------------
    -- Core mmc HW updates interface
    -----------------------------------------------------------------------
    e3_update_mmc_ptc_i : in std_logic;
    e3_update_mmc_S_i   : in std_logic;
    e3_mmc_ptc_i        : in std_logic_vector(1 downto 0);
    e3_mmc_S_i          : in std_logic;
    -----------------------------------------------------------------------
    -- Core read interface
    -----------------------------------------------------------------------
    f_sfr_read_en_i  : in  std_logic;
    f_sfr_read_idx_i : in  std_logic_vector(7 downto 0);
    rr_stall_i       : in  std_logic;

    -----------------------------------------------------------------------
    -- smem config : 0, 1, 2, 3 or 4 MB
    -----------------------------------------------------------------------
    smem_ext_cfg_i   : in  std_logic_vector(4 downto 0);           

    -----------------------------------------------------------------------
    -- Core result interface
    -----------------------------------------------------------------------
    rr_result_o      : out std_logic_vector(31 downto 0)
    );
  

end k1_mmu_wrapper;

architecture rtl of k1_mmu_wrapper is

  component dti_1pr_tm28hp_64x100_2bw3x_m
    port(
      VDD   : inout std_logic;
      VSS   : inout std_logic;
      DO    : out   std_logic_vector(99 downto 0);
      A     : in    std_logic_vector(5 downto 0);
      DI    : in    std_logic_vector(99 downto 0);
      CE_N  : in    std_logic;
      GWE_N : in    std_logic;
      BWE_N : in    std_logic_vector(99 downto 0);
      T_RWM : in    std_logic_vector(2 downto 0);
      CLK   : in    std_logic
      );
  end component;
  
  
  component k1_mmu is
    generic(
    IO_MAP             : boolean := false;
    i_utlb_nb_words    : integer := 4;
    d_utlb_nb_words    : integer := 4;
    l2_ltlb_nb_entries : integer := 8;
    l2_jtlb_nb_line    : integer := 64;
    pa_nbbits          : integer := 22  -- default for FN field is 21 downto 0 (2MB + 2MB smem no PAE)
    );

  port(
    clk   : in std_logic;
    reset : in std_logic;

    mmu_enable_i         : in std_logic;
    processor_in_debug_i : in std_logic;
    k1_64_mode_i         : in std_logic;

    -- maintenance instructions interface with core
    tlbread_i        : in  std_logic;
    tlbwrite_i       : in  std_logic;
    tlbprobe_i       : in  std_logic;
    tlbindexl_i      : in  std_logic;
    tlbindexj_i      : in  std_logic;
    tlbinvald_i      : in  std_logic;
    tlbinvali_i      : in  std_logic;
    f_stall_mmu_o    : out std_logic;
    rr_stall_mmu_o   : out std_logic;

    -- data side proc interface
    e1_dcache_req_i       : in std_logic;
    dcache_e3_stall_i     : in std_logic;
    e1_dcache_virt_addr_i : in std_logic_vector(40 downto 0);
    e1_dcache_opc_i       : in std_logic_vector(5 downto 0);
    e1_glob_acc_i         : in std_logic;
    e1_dcache_size_i      : in std_logic_vector(3 downto 0);
    e1_non_trapping_i     : in std_logic;
    
    e2_non_trapping_ld_cancel_o : out std_logic;
    e2_trap_nomapping_o         : out std_logic_vector(1 downto 0);
    e2_trap_protection_o        : out std_logic_vector(1 downto 0);
    e2_trap_writetoclean_o      : out std_logic_vector(1 downto 0);
    e2_trap_atomictoclean_o     : out std_logic_vector(1 downto 0);
    e2_trap_dmisalign_o         : out std_logic;
    e2_trap_dsyserror_o         : out std_logic_vector(1 downto 0);

    -- interface with dcache
    e2_dcache_phys_addr_o       : out std_logic_vector(pa_nbbits-1 downto 12);
    e2_dcache_cluster_per_acc_o : out std_logic;
    e2_dcache_policy_o          : out std_logic;
    e2_stall_o                  : out std_logic;
    dcache_e1_grant_i           : in  std_logic;
    dcache_second_acc_d_i       : in  std_logic;

    -- instruction side proc/cache interface
    icache_req_i             : in  std_logic;
    icache_cancel_i          : in  std_logic;
    icache_virt_addr_i       : in  std_logic_vector(40 downto 2);
    icache_phys_addr_o       : out std_logic_vector(pa_nbbits-1 downto 12);
    icache_cluster_per_acc_o : out std_logic;

    icache_datar_v_hacked_o : out std_logic_vector(3 downto 0);
    gate_icache_req_o       : out std_logic;
    gate_icache_grant_o     : out std_logic;
    ins_trap_nomapping_o    : out std_logic;
    ins_trap_protection_o   : out std_logic;
    ins_trap_psyserror_o    : out std_logic;

    -- interface with icache
    icache_grant_i       : in  std_logic;
    icache_datar_v_i     : in  std_logic_vector(3 downto 0);
    icache_replay_req_o  : out std_logic;
    icache_replay_addr_o : out std_logic_vector(40 downto 2);
    force_i_hit_o        : out std_logic;
    i_cached_acc_o       : out std_logic;

    -- Far SFR interface
    -----------------------------------------------------------------------
    -- Core write interface
    -----------------------------------------------------------------------
    cpu_wr_reg_idx_i : in  std_logic_vector(7 downto 0);
    cpu_wr_reg_val_i : in  std_logic_vector(31 downto 0);
    cpu_wr_reg_cmd_i : in  std_logic_vector(1 downto 0);
    privilege_mode_i : in  std_logic;
    cpu_wr_reg_en_i  : in  std_logic;

    -----------------------------------------------------------------------
    -- Core mmc HW updates interface
    -----------------------------------------------------------------------
    e3_update_mmc_ptc_i : in std_logic;
    e3_update_mmc_S_i   : in std_logic;
    e3_mmc_ptc_i        : in std_logic_vector(1 downto 0);
    e3_mmc_S_i          : in std_logic;
    -----------------------------------------------------------------------
    -- Core read interface
    -----------------------------------------------------------------------
    f_sfr_read_en_i  : in  std_logic;
    f_sfr_read_idx_i : in  std_logic_vector(7 downto 0);
    rr_stall_i       : in  std_logic;

    -----------------------------------------------------------------------
    -- smem config : 0, 1, 2, 3 or 4 MB
    -----------------------------------------------------------------------
    smem_ext_cfg_i   : in  std_logic_vector(4 downto 0);           

    -----------------------------------------------------------------------
    -- Core result interface
    -----------------------------------------------------------------------
    rr_result_o      : out std_logic_vector(31 downto 0);
    -----------------------------------------------------------------------
    -- JTLB ram interface
    -----------------------------------------------------------------------
    ram_tlbe_o       : out TLBEFULLF_type;
    ram_tlbe_way0_i  : in  TLBEFULLF_type;
    ram_tlbe_way1_i  : in  TLBEFULLF_type;
    ram_me_o         : out std_logic;
    ram_we_o         : out std_logic;
    ram_way_o        : out std_logic;
    ram_addr_o       : out std_logic_vector(5 downto 0)
    );

end component;



  signal mmu_ram_tlbe_in_s         : TLBEFULLF_type ;
  signal mmu_ram_tlbe_out_way0_s   : TLBEFULLF_type ;
  signal mmu_ram_tlbe_out_way1_s   : TLBEFULLF_type ;
  signal mmu_ram_me_s          : std_logic;
  signal mmu_ram_we_s          : std_logic;
  signal mmu_ram_way_s         : std_logic;
  signal mmu_ram_addr_s        : std_logic_vector(5 downto 0);


  signal mmu_ram_data_in_s     : std_logic_vector(99 downto 0);
  signal mmu_ram_data_in_way_s : std_logic_vector(49 downto 0);
  signal mmu_ram_data_out_s    : std_logic_vector(99 downto 0);
  signal mmu_ram_wem_s         : std_logic_vector(99 downto 0);
  signal CE_N_mmu_data_cut_s   : std_logic;
  signal GWE_N_mmu_data_cut_s  : std_logic;
  signal BWE_N_mmu_data_cut_s  : std_logic_vector(99 downto 0);
  

  
  
begin

  k1_mmu_0 : k1_mmu
  generic map(
    IO_MAP            => IO_MAP,
    i_utlb_nb_words   => i_utlb_nb_words,
    d_utlb_nb_words   => d_utlb_nb_words,
    l2_ltlb_nb_entries=> l2_ltlb_nb_entries,
    l2_jtlb_nb_line   => l2_jtlb_nb_line,
    pa_nbbits         => pa_nbbits
    )

  port map(
    clk    =>  clk,
    reset  => reset,

    mmu_enable_i          => mmu_enable_i,
    processor_in_debug_i  => processor_in_debug_i,
    k1_64_mode_i          => k1_64_mode_i,

    -- maintenance instructions interface with core
    tlbread_i      =>  tlbread_i,
    tlbwrite_i     =>  tlbwrite_i,
    tlbprobe_i     =>  tlbprobe_i,
    tlbindexl_i    =>  tlbindexl_i,
    tlbindexj_i    =>  tlbindexj_i,
    tlbinvald_i    =>  tlbinvald_i,
    tlbinvali_i    =>  tlbinvali_i,
    f_stall_mmu_o  =>  f_stall_mmu_o,
    rr_stall_mmu_o =>  rr_stall_mmu_o,

    -- data side proc interface
    e1_dcache_req_i          =>   e1_dcache_req_i,
    dcache_e3_stall_i        =>   dcache_e3_stall_i,
    e1_dcache_virt_addr_i    =>   e1_dcache_virt_addr_i,
    e1_dcache_opc_i          =>   e1_dcache_opc_i,
    e1_glob_acc_i            =>   e1_glob_acc_i,
    e1_dcache_size_i         =>   e1_dcache_size_i,
    e1_non_trapping_i        =>   e1_non_trapping_i,
    
    e2_non_trapping_ld_cancel_o =>  e2_non_trapping_ld_cancel_o,
    e2_trap_nomapping_o         =>  e2_trap_nomapping_o,
    e2_trap_protection_o        =>  e2_trap_protection_o,
    e2_trap_writetoclean_o      =>  e2_trap_writetoclean_o,
    e2_trap_atomictoclean_o     =>  e2_trap_atomictoclean_o,
    e2_trap_dmisalign_o         =>  e2_trap_dmisalign_o ,
    e2_trap_dsyserror_o         =>  e2_trap_dsyserror_o ,

    -- interface with dcache
    e2_dcache_phys_addr_o        =>  e2_dcache_phys_addr_o,
    e2_dcache_cluster_per_acc_o  =>  e2_dcache_cluster_per_acc_o,
    e2_dcache_policy_o           =>  e2_dcache_policy_o,
    e2_stall_o                   =>  e2_stall_o,
    dcache_e1_grant_i            =>  dcache_e1_grant_i,
    dcache_second_acc_d_i        =>  dcache_second_acc_d_i,

    -- instruction side proc/cache interface
    icache_req_i            =>  icache_req_i,
    icache_cancel_i         =>  icache_cancel_i,
    icache_virt_addr_i      =>  icache_virt_addr_i,
    icache_phys_addr_o      =>  icache_phys_addr_o,
    icache_cluster_per_acc_o=>  icache_cluster_per_acc_o,

    icache_datar_v_hacked_o =>   icache_datar_v_hacked_o,
    gate_icache_req_o       =>   gate_icache_req_o,
    gate_icache_grant_o     =>   gate_icache_grant_o,
    ins_trap_nomapping_o    =>   ins_trap_nomapping_o,
    ins_trap_protection_o   =>   ins_trap_protection_o,
    ins_trap_psyserror_o    =>   ins_trap_psyserror_o,

    -- interface with icache
    icache_grant_i          =>  icache_grant_i,
    icache_datar_v_i        =>  icache_datar_v_i,
    icache_replay_req_o     =>  icache_replay_req_o,
    icache_replay_addr_o    =>  icache_replay_addr_o,
    force_i_hit_o           =>  force_i_hit_o,
    i_cached_acc_o          =>  i_cached_acc_o,
    
    -- Far SFR interface
    -----------------------------------------------------------------------
    -- Core write interface
    -----------------------------------------------------------------------
    cpu_wr_reg_idx_i        =>  cpu_wr_reg_idx_i,
    cpu_wr_reg_val_i        =>  cpu_wr_reg_val_i,
    cpu_wr_reg_cmd_i        =>  cpu_wr_reg_cmd_i,
    privilege_mode_i        =>  privilege_mode_i,
    cpu_wr_reg_en_i         =>  cpu_wr_reg_en_i,

    -----------------------------------------------------------------------
    -- Core mmc HW updates interface
    -----------------------------------------------------------------------
    e3_update_mmc_ptc_i     =>  e3_update_mmc_ptc_i,
    e3_update_mmc_S_i       =>  e3_update_mmc_S_i,
    e3_mmc_ptc_i            =>  e3_mmc_ptc_i,
    e3_mmc_S_i              =>  e3_mmc_S_i,
    -----------------------------------------------------------------------
    -- Core read interface
    -----------------------------------------------------------------------
    f_sfr_read_en_i         =>  f_sfr_read_en_i,
    f_sfr_read_idx_i        =>  f_sfr_read_idx_i,
    rr_stall_i              =>  rr_stall_i,

    -----------------------------------------------------------------------
    -- smem config : 0, 1, 2, 3 or 4 MB
    -----------------------------------------------------------------------
    smem_ext_cfg_i         =>  smem_ext_cfg_i,          

    -----------------------------------------------------------------------
    -- Core result interface
    -----------------------------------------------------------------------
    rr_result_o            =>  rr_result_o,
    -----------------------------------------------------------------------
    -- JTLB ram interface
    -----------------------------------------------------------------------
    
    ram_tlbe_o       =>  mmu_ram_tlbe_in_s,
    ram_tlbe_way0_i  =>  mmu_ram_tlbe_out_way0_s,
    ram_tlbe_way1_i  =>  mmu_ram_tlbe_out_way1_s,
    ram_me_o         =>  mmu_ram_me_s,
    ram_we_o         =>  mmu_ram_we_s,
    ram_way_o        =>  mmu_ram_way_s,
    ram_addr_o       =>  mmu_ram_addr_s

    );
  


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MMU cut
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


  
  CE_N_mmu_data_cut_s  <= '0' when mmu_ram_me_s = '1' else '1';
  GWE_N_mmu_data_cut_s <= '0' when mmu_ram_we_s = '1' else '1';
  BWE_N_mmu_data_cut_s <= not(mmu_ram_wem_s);

  mmu_data_cut : dti_1pr_tm28hp_64x100_2bw3x_m
    port map(
      VDD   => open,
      VSS   => open,
      DO    => mmu_ram_data_out_s,
      A     => mmu_ram_addr_s(5 downto 0),
      DI    => mmu_ram_data_in_s,
      CE_N  => CE_N_mmu_data_cut_s,
      GWE_N => GWE_N_mmu_data_cut_s,
      BWE_N => BWE_N_mmu_data_cut_s,
      T_RWM => "011",
      CLK   => clk
      );
  

  mmu_ram_data_in_way_s(49 downto 30) <= mmu_ram_tlbe_in_s.tlbeh.PN;
  mmu_ram_data_in_way_s(29)           <= mmu_ram_tlbe_in_s.tlbeh.STANDARD;
  mmu_ram_data_in_way_s(28)           <= mmu_ram_tlbe_in_s.tlbeh.GLOBAL;
  mmu_ram_data_in_way_s(27 downto 19) <= mmu_ram_tlbe_in_s.tlbeh.ASN;
  mmu_ram_data_in_way_s(18)           <= mmu_ram_tlbe_in_s.tlbel.PER;
  mmu_ram_data_in_way_s(17 downto 8)  <= mmu_ram_tlbe_in_s.tlbel.FN(pa_nbbits-1 downto 12);
  -- do not store .AE that is useless in the cluster
  mmu_ram_data_in_way_s(7 downto 4)   <= mmu_ram_tlbe_in_s.tlbel.PA;
  mmu_ram_data_in_way_s(3 downto 2)   <= mmu_ram_tlbe_in_s.tlbel.CP;
  mmu_ram_data_in_way_s(1 downto 0)   <= mmu_ram_tlbe_in_s.tlbel.ES;

  mmu_ram_data_in_s <= mmu_ram_data_in_way_s & mmu_ram_data_in_way_s;

  mmu_ram_wem_s <= conv_std_logic_vector(0, 50) & conv_std_logic_vector(-1, 50) when mmu_ram_way_s = '0' and mmu_ram_we_s = '1' else
                   conv_std_logic_vector(-1, 50) & conv_std_logic_vector(0, 50) when mmu_ram_way_s = '1' and mmu_ram_we_s = '1' else
                   conv_std_logic_vector(0, 100);

  mmu_ram_tlbe_out_way0_s.tlbeh.PN       <= mmu_ram_data_out_s(49 downto 30);
  mmu_ram_tlbe_out_way0_s.tlbeh.STANDARD <= mmu_ram_data_out_s(29);
  mmu_ram_tlbe_out_way0_s.tlbeh.GLOBAL   <= mmu_ram_data_out_s(28);
  mmu_ram_tlbe_out_way0_s.tlbeh.ASN      <= mmu_ram_data_out_s(27 downto 19);
  mmu_ram_tlbe_out_way0_s.tlbel.PER      <= mmu_ram_data_out_s(18);
  mmu_ram_tlbe_out_way0_s.tlbel.FN       <= "0000000000" & mmu_ram_data_out_s(17 downto 8);
  mmu_ram_tlbe_out_way0_s.tlbel.AE       <= (others => '0');
  mmu_ram_tlbe_out_way0_s.tlbel.PA       <= mmu_ram_data_out_s(7 downto 4);
  mmu_ram_tlbe_out_way0_s.tlbel.CP       <= mmu_ram_data_out_s(3 downto 2);
  mmu_ram_tlbe_out_way0_s.tlbel.ES       <= mmu_ram_data_out_s(1 downto 0);

  mmu_ram_tlbe_out_way1_s.tlbeh.PN       <= mmu_ram_data_out_s(99 downto 80);
  mmu_ram_tlbe_out_way1_s.tlbeh.STANDARD <= mmu_ram_data_out_s(79);
  mmu_ram_tlbe_out_way1_s.tlbeh.GLOBAL   <= mmu_ram_data_out_s(78);
  mmu_ram_tlbe_out_way1_s.tlbeh.ASN      <= mmu_ram_data_out_s(77 downto 69);
  mmu_ram_tlbe_out_way1_s.tlbel.PER      <= mmu_ram_data_out_s(68);
  mmu_ram_tlbe_out_way1_s.tlbel.FN       <= "0000000000" & mmu_ram_data_out_s(67 downto 58);
  mmu_ram_tlbe_out_way1_s.tlbel.AE       <= (others => '0');
  mmu_ram_tlbe_out_way1_s.tlbel.PA       <= mmu_ram_data_out_s(57 downto 54);
  mmu_ram_tlbe_out_way1_s.tlbel.CP       <= mmu_ram_data_out_s(53 downto 52);
  mmu_ram_tlbe_out_way1_s.tlbel.ES       <= mmu_ram_data_out_s(51 downto 50);



  
end rtl;

