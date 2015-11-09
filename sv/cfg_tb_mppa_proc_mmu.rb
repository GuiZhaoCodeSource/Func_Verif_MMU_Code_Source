#QuestaParams.svlib = "-sv_lib #{ENV["MPPA_BUILD"]}/questa_#{Opt[:TOOL_POSTFIX]}/obj/tb_mppa_dma/cpp/libmppa_dma_cluster_m#{Opt[:CPU_MODE]}"

QuestaParams.do_post_run << "exit"
QuestaParams.timeout = "100ms"
QuestaParams.check << " && grep \"UVM_FATAL :    0\" transcript && grep \"END of Test Detected\" transcript && grep \"END of Check Detected\" transcript"
QuestaParams.eot << "END of Test Detected"
#QuestaParams.eot << "END of Check Detected"
#QuestaParams.vopt_opt = "-noUnrollVhGen"

if Opt.is_defined(:UVM_TEST_ROOT_NAME)
  QuestaParams.do_pre_run << "set SolveArrayResizeMax 20000; coverage save -onexit #{Opt[:UVM_TEST_ROOT_NAME]}.ucdb;"
end

## Non-regression parameters
NonRegression.regtype = "UVM"
NonRegression.rtlparamname = "PARAM"
NonRegression.rtlparamsets << "cluster"

# Test list
# format is <test name> [<max random seed>]
# <max random seed> is used to limit number of runs of a specific test in seed appocach
# for example it is no needed to run several time a directed tests with long runtime
NonRegression.tclist << "only_4k_pages_aligned_global_one_tnm_dis_tmm_dis"
NonRegression.tclist << "only_4k_pages_aligned_global_one_tnm_en_tmm_dis"
#NonRegression.tclist << "only_4k_pages_aligned_global_one_tnm_en_tmm_en" // It is not meaningful(multi mapping enable with golobal 1)
NonRegression.tclist << "only_4k_pages_no_aligned_global_one_tnm_dis_tmm_dis"
NonRegression.tclist << "only_4k_pages_no_aligned_global_one_tnm_en_tmm_dis"
#NonRegression.tclist << "only_4k_pages_no_aligned_global_one_tnm_en_tmm_en"// It is not meaningful(multi mapping enable with golobal 1)

NonRegression.tclist << "only_4k_pages_aligned_global_zero_tnm_dis_tmm_dis"
NonRegression.tclist << "only_4k_pages_aligned_global_zero_tnm_en_tmm_dis"
NonRegression.tclist << "only_4k_pages_aligned_global_zero_tnm_en_tmm_en"
NonRegression.tclist << "only_4k_pages_no_aligned_global_zero_tnm_dis_tmm_dis"
NonRegression.tclist << "only_4k_pages_no_aligned_global_zero_tnm_en_tmm_dis"
NonRegression.tclist << "only_4k_pages_no_aligned_global_zero_tnm_en_tmm_en"

NonRegression.tclist << "random_pages_all_tlb_aligned_global_one_tnm_dis_tmm_dis"
NonRegression.tclist << "random_pages_all_tlb_aligned_global_one_tnm_en_tmm_dis"
NonRegression.tclist << "random_pages_all_tlb_no_aligned_global_one_tnm_dis_tmm_dis"
NonRegression.tclist << "random_pages_all_tlb_no_aligned_global_one_tnm_en_tmm_dis"

NonRegression.tclist << "random_pages_all_tlb_aligned_global_zero_tnm_dis_tmm_dis"
NonRegression.tclist << "random_pages_all_tlb_aligned_global_zero_tnm_en_tmm_dis"
NonRegression.tclist << "random_pages_all_tlb_no_aligned_global_zero_tnm_dis_tmm_dis"
NonRegression.tclist << "random_pages_all_tlb_no_aligned_global_zero_tnm_en_tmm_dis"
NonRegression.tclist << "test_tlb_maintenance_all_tlb_4K"
NonRegression.tclist << "test_tlb_maintenance_all_tlb_small_size_page_tmm_en"
