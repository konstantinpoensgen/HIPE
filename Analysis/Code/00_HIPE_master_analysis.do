* 00_HIPE_master_analysis.do * 

* ============================================================================ *
	
* run folder declare 
* ---------------------------------------------------------------------------- *

	* Set user
	local username = c(username)
	di 	"`username'"
	local user "`username'/Dropbox"
	if "`username'" == "kpoens"  local user "C:/Users/`username'/Dropbox/Research/HIPE"

	* Run setup file
	do "`user'/HIPE_folder_declare.do" 


* run analysis do-files
* ---------------------------------------------------------------------------- *

	* Individual level analysis
	do "$analysis_code/01_analysis_soep_gkv_sumstats.do"
	do "$analysis_code/02a_analysis_soep_gkv_regressions_addon09.do"
	do "$analysis_code/02b_analysis_soep_gkv_regressions_addon15.do"
	do "$analysis_code/02b_analysis_soep_gkv_regressions_heterogeneity.do"
	do "$analysis_code/03_analysis_soep_gkv_did.do"

	* Insurer level analysis
	do "$analysis_code/04_analysis_GKV_aggregate_sumstats.do" 
	do "$analysis_code/05_analysis_GKV_aggregate_explfigs.do" 
	do "$analysis_code/06_analysis_GKV_aggregate_expldid.do" 
	do "$analysis_code/07a_analysis_GKV_aggregate_regs_ols_addon09.do"
	do "$analysis_code/07b_analysis_GKV_aggregate_regs_ols_addon15.do"
	do "$analysis_code/08_analysis_GKV_aggregate_regs_iv.do" 
	do "$analysis_code/09_GKV_DiD.do"

	* Intext statistics
	do "$analysis_code/10_analysis_intext.do"


