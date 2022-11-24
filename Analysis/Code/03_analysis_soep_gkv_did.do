********************************************************************************
************************ SOEP & GKV INDIVIDUAL DID *****************************
********************************************************************************

/* 	OBJECTIVES
	- Explorative analysis on individual-level DiD
		(i) DiD with all providesr
		(ii) DiD with only "vdek" providers
	
	OUTLINE
	0) 	Preliminaries 
	1) 	Data
	2) 	"DiD" among all providers
		2.1) Specification settings
		2.2) Period 1: 2009-14
		2.3) Period 2: 2015-18
	3) 	"DiD" among "vdek"
		3.1) Share of switches
		3.2) DID contemporaneous effect
		3.3) DID forward t+1 effect
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
log using "$logs_analysis/`date'_analysis_soep_gkv_did.log", text replace	


* 1) Data
* ---------------------------------------------------------------------------- *

* Load data 
use "$data_final/soep_gkv_match_cleaned.dta", clear


* 2) "DiD" among all providers 
* ---------------------------------------------------------------------------- *

	* 2.1) Specification settings
	* ........................................................................ *

	* Control variables

		* individual-level
		global baseline age i.gender i.tertiary income_gross_ln health_satisfaction // i.hospital_stay i.reported_sick
		global extension i.isco08 // i.married  i.companysize

		* provider-level
		global provider_baseline i.type_prior rating_relative_prior
		global provider_extension insured_initial  


	* Group thresholds
	sum addon_diff_avg, d


	* 2.2) Period 1: 2009-14
	* ........................................................................ *
	preserve 
	
		* Generate DiD group variable
		cap drop addon09_group
		gen addon09_group = 0 
		replace addon09_group = 1 if provider=="Deutsche Angestellten Krankenkasse" | provider=="KKH Kaufmaennische Krankenkasse"  | provider=="DAK-Gesundheit"
	
		* Run OLS regression
		qui probit hi_switch ib2012.year##ib0.addon09_group i.type $baseline if year<2015
		qui margins year#addon09_group
		marginsplot
	
	restore


	* 2.3) Period 2: 2015-18
	* ........................................................................ *
	
	* Pre-defined add-on groups from cleaning 
	tab addon_did_group

	* Run DiD Analysis
	preserve

		* Drop providers that charged 2010-12 addon09
		drop if provider=="Deutsche Angestellten Krankenkasse" 
		drop if provider=="KKH Kaufmaennische Krankenkasse" 
		drop if provider=="DAK-Gesundheit"

		* How many observations per group?
		tab addon_did_group

		* Run DiD
		qui probit hi_switch i.year#i.addon_did_group  $baseline //i.type
		qui margins year#addon_did_group

		* Plot DiD event study
		marginsplot ,  xline(2014.5, lp(dash)) yline(0) ///
			title("Individual-level switching probability difference-in-difference") ytitle("Pr(Switch=1)") legend(cols(3))
	
	restore
	
	
* 3) "DiD" among "vdek" ------------------------------------------------------ *

	* 3.1) Share of switches
	* ........................................................................ *

	* Contemporaneous effect
	preserve
	
		* Streamline provider name
		replace provider_l="BARMER" if provider_l=="BARMER GEK" | provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)"
		replace provider_l="DAK" if provider_l=="DAK-Gesundheit" | provider_l=="Deutsche Angestellten Krankenkasse"
		replace provider_l="KKH" if provider_l=="KKH Kaufmaennische Krankenkasse"
		replace provider_l="TK" if provider_l=="Techniker Krankenkasse (TK)"

		keep if provider_l=="BARMER" | provider_l=="DAK" | provider_l=="TK"

		* Collapse data
		collapse (mean) hi_switch, by(provider_l year)
		sort provider_l year

		* Plot share of switches in data
		graph twoway (line hi_switch year if provider_l=="BARMER") (line hi_switch year if provider_l=="TK") ///
			(line hi_switch year if provider_l=="DAK") (line hi_switch year if provider_l=="KKH") ///
				, xline(2010 2012 2015, lp(dash) lc(gs10)) xlab(2009(1)2018, labsize(3)) legend(lab(1 "BARMER") lab(2 "TK") lab(3 "DAK") lab(4 "KKH")) ///
				title("Share of switches by vdek provider") subtitle("Contemporaneous effect") xtitle("") ytitle("Share of swichers")

		* Export graph
		local date $date
		graph export "$figures/DiD/Individual/`date'_SimpleShare_contemporaneous.png", replace

	restore
				
	* Forward t+1 effect
	preserve
	
		* Streamline provider name
		replace provider="BARMER" if provider=="BARMER GEK" | provider=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)"
		replace provider="DAK" if provider=="DAK-Gesundheit" | provider=="Deutsche Angestellten Krankenkasse"
		replace provider="KKH" if provider=="KKH Kaufmaennische Krankenkasse"
		replace provider="TK" if provider=="Techniker Krankenkasse (TK)"

		keep if provider=="BARMER" | provider=="DAK" | provider=="TK"

		* Collapse data
		collapse (mean) hi_switch_lead, by(provider year)
		ren hi_switch_lead hi_switch
		sort provider year

		* Plot share of switches in data
		graph twoway (line hi_switch year if provider=="BARMER") (line hi_switch year if provider=="TK") ///
			(line hi_switch year if provider=="DAK") (line hi_switch year if provider=="KKH") ///
				, xline(2010 2012 2015, lp(dash) lc(gs10)) xlab(2009(1)2017, labsize(3)) legend(lab(1 "BARMER") lab(2 "TK") lab(3 "DAK") lab(4 "KKH")) ///
				title("Share of switches by vdek provider") subtitle("Forward effect") xtitle("") ytitle("Share of swichers")

		* Export graph
		local date $date
		graph export "$figures/DiD/Individual/`date'_SimpleShare_forward.png", replace

	restore
	
			
	* 3.2) DID contemporaneous effect
	* ........................................................................ *
	preserve

		* Prepare data

			* Streamline provider name
			replace provider_l="BARMER" if provider_l=="BARMER GEK" | provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)"
			replace provider_l="DAK" if provider_l=="DAK-Gesundheit" | provider_l=="Deutsche Angestellten Krankenkasse"
			replace provider_l="KKH" if provider_l=="KKH Kaufmaennische Krankenkasse"
			replace provider_l="TK" if provider_l=="Techniker Krankenkasse (TK)"

			keep if provider_l=="BARMER" | provider_l=="DAK" | provider_l=="TK"
	
			* encode provider name
			cap drop provider_id
			encode provider_l, gen(provider_id)	// important to use provider_l because we want to get the "outflow" switch
	
		* Run probit and marginsplot
		qui probit hi_switch i.provider_id#i.year i.year $baseline, vce(robust)
	
		qui margins year#provider_id
		marginsplot, title("") ///
			xline(2010 2012 2015, lp(dash) lc(gs10)) xlab(2009(1)2017, labsize(3)) xtitle("") ytitle("Pr(Switch=1)")
		
		* Export 
		local date $date
		graph export "$figures/DiD/Individual/`date'_DiD_vdek_contemporaneous.png", replace
	
	restore

	
	* 3.3) DID forward t+1 effect
	* ........................................................................ *

	preserve 

		* Prepare data
	
			* streamline provider name
			replace provider="BARMER" if provider=="BARMER GEK" | provider=="Barmer Ersatzkasse (BEK)" | provider=="Gmuender Ersatzkasse (GEK)"
			replace provider="DAK" if provider=="DAK-Gesundheit" | provider=="Deutsche Angestellten Krankenkasse"
			replace provider="KKH" if provider=="KKH Kaufmaennische Krankenkasse"
			replace provider="TK" if provider=="Techniker Krankenkasse (TK)"
	
			keep if provider=="BARMER" | provider=="DAK" | provider=="TK"

			* encode provider name
			cap drop provider_id
			encode provider, gen(provider_id)	// important to use provider_l because we want to get the "outflow" switch
	
		* Run probit and marginsplot
		qui probit hi_switch_lead i.provider_id#i.year i.year $baseline, vce(robust)
		
		qui margins year#provider_id
		marginsplot, title("") ///
			xline(2010 2012 2015, lp(dash) lc(gs10)) xlab(2009(1)2017, labsize(3)) xtitle("") ytitle("Pr(Switch=1)")
		
		* Export graph
		local date $date
		graph export "$figures/DiD/Individual/`date'_DiD_vdek_forward.png", replace

	restore

* Close log file 
cap log close 

* THE END 
