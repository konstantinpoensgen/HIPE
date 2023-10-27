********************************************************************************
************************** GKV Merge aggregate files ***************************
********************************************************************************

/*	DATA INPUT
	$data_input/Membership/GKV_aggregate_members
	$data_input/Premium/GKV_Spitzenverband_ZB
	$data_input/Rechnungslegung/GKV_Rechnungslegung
	$data_input/Ratings/FOCUS_Money_GKVtest
	$data_input/Premium/ZB_2009_2012_Pendzialek

	DATA OUTPUT
	$data_final/GKV_aggregate.dta
	$data_final/GKV_aggregate.csv	

	DO-FILE OUTLINE
	1) dfg-GKV ratings insured individuals 2009-2021
	2) GKV-Spitzenverband add-on premium 20215-2021 
	3) Bundesanzeiger GKV Rechnungslegung
	4) FOCUS Money GKV test Rating
	5) Add-on premium 2009-2012 Pendzialek 
	6) Data cleaning 
	7) Data consistency checks
	8) Save data
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
log using "$logs_build/`date'_HIPE_GKV_merge.log", text replace		


* 1) dfg-GKV ratings insured individuals 2009-2021 
* ---------------------------------------------------------------------------- *

	* Load data 
	use "$data_intermediate/GKV_aggregate_members.dta", clear
	
	// duplicates?
	duplicates report provider year
	
	// drop not necessary entries for cleaner merge_success overview
	drop if insured==. & year!=2009
	drop if insured_lead==. & year==2009
	table year

	
* 2) GKV-Spitzenverband add-on premium 20215-2021 
* ---------------------------------------------------------------------------- *

	* Merge data
	merge 1:1 provider year using "$data_input/Premium/GKV_Spitzenverband_ZB"
	
	* Check what is not merged
	* ........................................................................ *
	
	// Not merged from GKV Spitzenverband add-premium file
	tab provider if _merge==2
	
		/*
		- BKK Basell not in dfg GKV ranking
		- BKK Demag Krauss-Maffei not in dfg GKV ranking
		- BKK Schleswig-Holstein (S-H) not in dfg GKV ranking
		- BKK family not in dfg GKV ranking
		- HEAG BKK not in dfg GKV ranking
		- BKK Karl Mayer is only partly covered by dfg GKV ranking
		- BKK exklusiv is only partly covered by dfg GKV ranking
		- Koenig & Bauer only partly covered by dfg GKV ranking
		*/
	
		// drop data without information on # of insured individuals
		drop if _merge==2 // deletes 18 observations
	
	// Not matched from dfg GKV ranking
	table year if _merge==1, c(count insured)
	tab provider if _merge==1 & year>=2015
			
		/*
		BARMER GEK:
			- Merge is with "BARMER" in 2016 which is treated as BARMER and Deutsche BKK jointly
			- Drop below of "BARMER GEK" and "Deutsche BKK" does not lose anything because no insured_change for these two
		- Sozialversicherung fuer Landwirtschaft...		
		*/
		
		// BARMER vs. BARMER GEK
		drop if year==2016 & (provider=="BARMER GEK" | provider=="Deutsche BKK") // Treat 2016 values counterfactually jointly in "BARMER"
		
		// SVLG -> very special case, not keep in analysis
		drop if provider=="Sozialversicherung fuer Landwirtschaft Forsten und Gartenbau (SVLFG)"
	
	// Drop merge identifier
	drop _merge
	
	* Some cleaning
	* ........................................................................ *
	
	* Fill in missing types
	replace type="vdek" if provider=="BARMER" & year==2016
	replace type="AOK" if provider=="AOK Rheinland-Pfalz/Saarland" & year==2012
	replace type="vdek" if provider=="DAK-Gesundheit" & year==2011
	
	
* 3) Bundesanzeiger GKV Rechnungslegung 
* ---------------------------------------------------------------------------- *

	* Merge with GKV Rechnungslegung
	merge 1:1 provider year using "$data_input/Rechnungslegung/GKV_Rechnungslegung"
	
	* Check success of merges
	
		* Not matched from GKV-Rechnungslegung
		tab provider if _merge==2
		drop if _merge==2
		
		* Not matched from dfg GKV ranking
		tab year if _merge==1
		tab provider if _merge==1 & year>2012 & year<2020
		// br if _merge==1 & year>2012 & year<2020
	
			/* Systematically missing
			- BKK Grillo-Werke -> only available on Bundesanzeiger for 2013
			*/

		* drop _merge identifier
		drop _merge
	
	
* 4) FOCUS Money GKV test Rating 
* ---------------------------------------------------------------------------- *
	
	* Merge with FOCUS Money GKV test rating	
	merge 1:1 provider year using "$data_input/Ratings/FOCUS_Money_GKVtest"
	
	* Check success of merges
	
		// not matched from FOCUS Money GKV test 
		tab provider if _merge==2
		
		drop if _merge==2 & year!=2009
		drop _merge
				
				
* 5) Add-on premium 2009-2012 Pendzialek 
* ---------------------------------------------------------------------------- *
	
	* Merge with Pendzialek et al 2015 add-on 2009-2012 data
	merge 1:1 provider year using "$data_input/Premium/ZB_2009_2012_Pendzialek"
		
	* Check success of merges
	
		// not matched from using data
		tab provider if _merge==2
		
		drop if _merge==2 & year!=2009
		drop _merge
		

* 6) Data cleaning 
* ---------------------------------------------------------------------------- *	

	* Order variables
	order provider type gkv_type year rank members insured_avg insured insured_lead ///
		insured_change_abs insured_change_perc premium addon addon_change addon_diff_avg ///
		addon_diff_predicted addon_avg addon_predicted addon_abs addon_pct addon_dummy ///
		rebate_abs rebate_abs_dummy capital capital_pc capital_reserves capital_reserves_pc ///
		capital_admin capital_admin_pc revenue revenue_pc revenue_fund revenue_fund_pc ///
		revenue_addon revenue_addon_pc expenditure expenditure_pc expenditure_admin ///
		expenditure_admin_pc rating rating_relative service service_relative	///
		merger merge_date comment_dfg comment_rechnungslegung

	* Drop unrelevant variables
	drop gkv_type
		
	* Adjust variables
	* ........................................................................ *
	
	* Add-on and rebate 2009-2012
	foreach var in addon_abs addon_pct addon_dummy rebate_abs rebate_abs_dummy {
		replace `var' = 0 if `var'==.
		}
	
	* rename variables
	rename addon_abs addon09_abs
	rename addon_dummy addon09_dummy
	rename addon_pct addon09_pct
	rename rebate_abs rebate09_abs
	rename rebate_abs_dummy rebate09_dummy

	* encode variables
		// gkv type
		encode type, gen(gkv_type)
			drop type
			rename gkv_type type
		// provider
		encode provider, gen(id)
	
	* Back-out (proxy) average income pc by provider
	cap drop income_pc
	gen income_pc = (revenue_addon/members)*(100/addon)*(1/12) if revenue_addon!=. & revenue_addon!=0
	label var income_pc "Proxy for average income pc by provider-year (likely lower bound)"	
		
		sum income_pc, d
		replace income_pc=. if income_pc<100
		table type, c(mean income_pc)
	
	* Gen logged variables
		foreach var in members insured_avg insured insured_lead ///
			capital capital_pc capital_reserves capital_reserves_pc capital_admin ///
			capital_admin_pc revenue revenue_pc revenue_fund revenue_fund_pc revenue_addon ///
			revenue_addon_pc expenditure expenditure_pc expenditure_admin expenditure_admin_pc ///
			rating_relative service_relative rebate09_abs addon09_abs income_pc insured_initial ///
			premium addon {
		
			cap drop `var'_ln
			gen `var'_ln = ln(`var')
			}		
		
	* Generate DiD group variable over full range
		
		* Average
		cap drop addon_did_group
		egen addon_did_group = max(addon_group_fixed), by(provider)
			label values addon_did_group addon_group_label
		
		gen addon_did_avg_group = addon_did_group 	

			tab addon_did_group

		* Median
		cap drop addon_did_med_group
		egen addon_did_med_group = max(addon_med_group_fixed), by(provider)
			label values addon_did_med_group addon_group_label
			
			tab addon_did_med_group


	* Change order of variables
	order provider type year
		
* 7) Data consistency checks
* ---------------------------------------------------------------------------- *

	* Data availability by year
	table year, c(count insured count insured_change_abs count addon count revenue_fund ///
		count rating_relative)
		
	* members and insured individuals
	sum members insured_avg insured
	sum insured, d
	
	* change in insured individuals
		
		// absolute
		sum insured_change_abs, d
			tab provider if (insured_change_abs<r(p1) | insured_change_abs>r(p99)) & insured_change_abs!=.
	
		// percentage
		sum insured_change_perc, d
			tab provider if (insured_change_perc<r(p1) | insured_change_perc>r(p99)) & insured_change_perc!=.
	
		// relationship absolute and percentage change in insured individuals
		/* twoway (scatter insured_change_abs insured_change_perc) ///
			(lfit insured_change_abs insured_change_perc) /// 
			if insured_change_perc<28 & insured_change_perc>-6 ///
				& insured_change_abs<131536 & insured_change_abs>-103905 
		*/
		
	* addon premium
	sum addon addon_change addon_diff_avg addon_diff_predicted addon_avg addon_predicted ///
		addon09_abs addon09_pct rebate09_abs
	
	* Rechnungslegung stats
	sum capital_pc capital_reserves_pc capital_admin_pc revenue_pc revenue_fund_pc ///
		revenue_addon_pc expenditure_pc expenditure_admin_pc
	
	* Focus Money Rating
	sum rating rating_relative 
	sum service service_relative
	

* 8) Save data 
* ---------------------------------------------------------------------------- *

	* Save data
	drop if insured_lead==. & year==2009

	save "$data_final/GKV_aggregate.dta", replace
	export delimited  "$data_final/GKV_aggregate.csv", replace delim(";")

* Close log-file 
log close 
