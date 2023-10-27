********************************************************************************
************************ GKV AGGREGATE - EXPLORE DID ***************************
********************************************************************************

/* 	OBJECTIVES
	


	OUTLINE
	0) Preliminaries 
	1) Data
	2) Aggregate provider DiD 
*/


* 0) Preliminaries 
* ---------------------------------------------------------------------------- *
cap log close 
clear all

* Set user
local username = c(username)
di 	"`username'"
if "`username'" == "kpoens"  local path "C:/Users/`username'/Dropbox/Research/HIPE"

* Run folder declare
do "`path'/HIPE_folder_declare.do" 

* Open log file 
local date "$date"
log using "$logs_analysis/`date'_analysis_gkv_aggregate_expldid.log", text replace	


* 1) Data
* ---------------------------------------------------------------------------- *

* Load data
use "$data_final/GKV_aggregate", clear

* Set panel var
xtset id year


* 2) Aggregate provider DiD 
* ---------------------------------------------------------------------------- *

* Drop those that charged addon premium in 2010-12

	// Ever charged an add-on premium
	cap drop addon09_dummy_ever
	egen addon09_dummy_ever = max(addon09_dummy), by(provider)
	
		tab provider if addon09_dummy_ever==1
		drop if addon09_dummy_ever==1 
		drop if provider=="DAK-Gesundheit"
		

* DiD regression

		// log(insurees) after controlling for initial size
		qui reg insured_lead_ln ib2014.year##ib1.addon_did_group i.type insured_initial_ln if year <2019, vce(robust)
		
		qui margins ib2014.year#addon_did_group
		marginsplot ,  xline(2014.5, lp(dash) lcol(gs5)) ///
			title("") ytitle("log(enrollment)") legend(cols(3))
	
		local date $date
		graph export "$figures/DiD/Provider/`date'_DiD_Provider_insured_Lead_ln.pdf", replace

		// log(members) after controlling for initial size
		qui reg members_ln ib2014.year##ib1.addon_did_group i.type insured_initial_ln if year <2019, vce(robust)

		qui margins year#addon_did_group
		marginsplot ,  xline(2014.5, lp(dash) lcol(gs5)) ///
			title("") ytitle("log(members)") legend(cols(3))
		
		local date $date	
		graph export "$figures/DiD/Provider/`date'_DiD_Provider_members_ln.pdf", replace

		// %-Change in marketshare
		qui reg marketshare_change ib2014.year##ib1.addon_did_group if year <2019, vce(robust)

		qui margins year#addon_did_group
		marginsplot ,  xline(2014.5, lp(dash) lcol(gs5)) yline(0) ///
			title("") ytitle("% change market share") legend(cols(3))
	
		local date $date
		graph export "$figures/DiD/Provider/`date'_DiD_Provider_marketshare_change.pdf", replace
	
		// %-Change in net enrollment
		qui reg insured_change_perc i.year#i.addon_did_group if year <2019, vce(robust)

		qui margins year#addon_did_group
		marginsplot ,  xline(2014.5, lp(dash) lcol(gs5)) yline(0) ///
			title("") ytitle("% change net enrollment") legend(cols(3))
	
		local date $date
		graph export "$figures/DiD/Provider/`date'_DiD_Provider_insured_change_perc.pdf", replace

	
		// Play with other variables
		local var members_ln
		reg `var' i.year#i.addon_did_group i.type insured_initial_ln if year <2019, vce(robust)

		qui margins year#addon_did_group
		marginsplot ,  xline(2014.5, lp(dash) lcol(gs5)) yline(0, lcol(gs5)) ///
			title("Provider-level DiD `var'") ytitle("% change") legend(cols(3))
		
* Plot unconditional average for intuition	
		
preserve 
	local var marketshare_change
	collapse (mean) `var', by(year addon_did_group)
	drop if addon_did_group==.
	
	twoway (line `var' year if addon_did_group==1 & year>2009 & year<2019) ///
		(line `var' year if addon_did_group==2 & year>2009 & year<2019) ///
		(line `var' year if addon_did_group==3 & year>2009 & year<2019) /// 
		, legend(lab(1 "Below average") lab(2 "At average") lab(3 "Above average")) xline(2014.5, lp(dash))
	
restore

* Close log file
cap log close
