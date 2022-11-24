* 00_HIPE_master_build.do
* Major revise on February 8, 2022

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


* run building do-files
* ---------------------------------------------------------------------------- *

	* Prepare SOEP data
	do "$build_code/01_HIPE_soep_raw_clean.do"
	do "$build_code/02_HIPE_soep_join.do"
	
	* GKV aggregate data 
	do "$build_code/03_HIPE_GKV_Membership.do"
	do "$build_code/04_HIPE_GKV_Rechnungslegung.do"
	do "$build_code/05_HIPE_GKV_AddOnPremium.do"
	do "$build_code/06_HIPE_GKV_Rankings.do"
	do "$build_code/07_HIPE_GKV_AddOnRebate.do"
	do "$build_code/08_HIPE_GKV_merge"
	
	* SOEP and GKV aggregate merge & cleaning
	do "$build_code/09_HIPE_SOEP_gkv_matching.do"
	do "$build_code/10_HIPE_soep_gkv_matched_cleaning.do"

