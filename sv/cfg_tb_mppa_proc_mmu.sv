/***********************************************************************************/
/*                                                                                 */
/*                             KALRAY-SA                                           */
/*     Reproduction and Communication of this document is strictly prohibited      */
/*       unless specifically authorized in writing by KALRAY-SA.                   */
/*                                                                                 */
/***********************************************************************************/
/*  Ver     Modified By      Date      Changes                                     */
/*  ---     -----------      ----      -------                                     */
/*  1.0     B. MINGUEZ     13/07/10    Initial version                             */
/***********************************************************************************/
/* Comments :                                                                      */
/*                                                                                 */
/***********************************************************************************/

`timescale 1 ns / 1 ps

config cfg_tb_mppa_proc_mmu;

   design lib_tb_mppa_proc_mmu_sv.tb_mppa_proc_mmu;
   default liblist lib_mppa_common_unit_vhdl lib_tb_mppa_proc_mmu_sv lib_tb_mppa_proc_mmu_vhdl lib_mppa_mem_cut_vlog;
//   instance tb_mppa_dma_cluster.tb_mppa_dma_cluster_wrapper_0.cluster_mppa_dma.dma_sb.dma_tx.dma_tx_packet_shaper.dma_tx_channel_arbiter.gen_dma2noc_fifo use lib_mppa_common_unit_vhdl.mppa_generic_fifo_fastout;
//   instance mppa_256_top_tb.i_mppa_256_top use lib_mppa_top_vhdl.cfg_mppa_256_top_mini:config;
//   instance mppa_256_top_tb.i_mppa_256_top.mppa_io_ddr_top_0.i_mppa_io_ddr_interconnect liblist lib_mppa_mshm_ddr_cluster_top_vhdl lib_mppa_mshm_interconnect_vlog lib_mppa_dma_vhdl;
//   instance mppa_256_top_tb.inst_mppa_pcie0_bfm use lib_tb_mppa_mshm_pcie_vlog.cfg_tb_mppa_pcie_bfm_empty:config;
//   instance mppa_256_top_tb.inst_mppa_pcie1_bfm use lib_tb_mppa_mshm_pcie_vlog.cfg_tb_mppa_pcie_bfm_empty:config;
//   instance mppa_256_top_tb.i_async_1Mx16 liblist lib_tb_mppa_mshm_soc_periph_flash_ctrl_sram;
  
endconfig
