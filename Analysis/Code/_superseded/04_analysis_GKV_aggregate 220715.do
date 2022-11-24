version 15
capture log close
set more off
clear

********************************************************************************
******************* Analyis of GKV Aggregate Data ******************************
********************************************************************************

* Set directory
cd "$hipe"

* Load data
use "$output/GKV_aggregate", clear

* Set panel var
xtset id year

* --------------------------- Summary statistics ----------------------------- *

eststo clear

* Members and insured
	eststo sum_insured: quietly estpost summarize members insured_avg insured ///
		insured_change_abs insured_change_perc income_pc, d
	
* Add-on premium
	eststo sum_addon: quietly estpost summarize addon addon_change addon_diff_avg ///
		addon_diff_predicted addon_avg addon_predicted addon09_abs addon09_pct rebate09_abs, d


* Rechnungslegung
	eststo sum_rechnung: quietly estpost summarize capital_pc capital_reserves_pc ///
		capital_admin_pc revenue_pc revenue_fund_pc revenue_addon_pc ///
		expenditure_pc expenditure_admin_pc, d
		
* Joint summary statistics
preserve

	* Adjust unites of variables
	replace insured = insured/1000
	replace members = members/1000
	replace insured_change_abs = insured_change_abs/1000
	
	* Summarize data
	eststo sum_joint: qui estpost summarize insured insured_change_abs insured_change_perc members revenue_fund_pc revenue_addon_pc expenditure_pc expenditure_admin_pc ///
		capital_reserves_pc rating_relative addon addon_change if year<2019, d
		
restore

* Export tables in LaTex format
	foreach summary in insured addon rechnung joint { 
		esttab sum_`summary' using "$tables/SummaryStats/Aggregate/sum_GKV_aggregate_`summary'.tex", replace ///
			cells("mean(fmt(2)) p5(fmt(2)) sd(fmt(1)) min(fmt(1)) max(fmt(1)) count(fmt(0))") ///
			title("Summary stats for `summary'"\label{tab:gkvsum`summary'}) booktabs compress nomtitles width(1\hsize) ///
			nonumbers noobs 
		}
		
* -------------------------------- Figures ----------------------------------- *

set scheme s1color
local figures 0 

if `figures'==1 {

* Add-on premium and absolute change in insured individuals
	foreach xvar in addon addon_change addon_diff_avg addon_diff_predicted {
		foreach yvar in insured_change_abs insured_change_perc {

		// no outlier treatment
		graph twoway (scatter `yvar' `xvar') ///
			(lfit `yvar' `xvar') if year>=2015 & year<=2018 ///
			, legend(off) title("`yvar' and `xvar'") ///
				subtitle("Pooled over 2015-2018") ytitle() ///
				ylab( ,labsize(2.5)) yline(0, lstyle(major_grid)) xline(0, lstyle(major_grid)) 
		graph export "$figures/Exploratory/GKV_aggregate_addon_relationships/`xvar'_`yvar'.png", replace
		
		// exclude top and bottom 1% tail
		
		sum `yvar', d
			preserve
				keep if `yvar'<=r(p99) & `yvar'>=r(p1)
				
				graph twoway (scatter `yvar' `xvar') ///
					(lfit `yvar' `xvar') if year>=2015 & year<=2018 ///
					, legend(off) title("`yvar' and `xvar'") ///
						subtitle("Pooled over 2015-2018") ytitle() ///
						ylab( ,labsize(2.5)) ///
						yline(0, lstyle(major_grid)) xline(0, lstyle(major_grid)) 
				graph export "$figures/Exploratory/GKV_aggregate_addon_relationships/`xvar'_`yvar'_nooutlier.png", replace
		
			restore
		}
	}	
}

else disp "Figures not activated."


* -------------------------- Aggregate provider DiD -------------------------- *

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
	
		graph export "$figures/DiD/Provider/DiD_Provider_insured_Lead_ln.pdf", replace

		// log(members) after controlling for initial size
		qui reg members_ln ib2014.year##ib1.addon_did_group i.type insured_initial_ln if year <2019, vce(robust)

		qui margins year#addon_did_group
		marginsplot ,  xline(2014.5, lp(dash) lcol(gs5)) ///
			title("") ytitle("log(members)") legend(cols(3))
			
		graph export "$figures/DiD/Provider/DiD_Provider_members_ln.pdf", replace

		// %-Change in marketshare
		qui reg marketshare_change ib2014.year##ib1.addon_did_group if year <2019, vce(robust)

		qui margins year#addon_did_group
		marginsplot ,  xline(2014.5, lp(dash) lcol(gs5)) yline(0) ///
			title("") ytitle("% change market share") legend(cols(3))
	
		graph export "$figures/DiD/Provider/DiD_Provider_marketshare_change.pdf", replace
	
		// %-Change in net enrollment
		qui reg insured_change_perc i.year#i.addon_did_group if year <2019, vce(robust)

		qui margins year#addon_did_group
		marginsplot ,  xline(2014.5, lp(dash) lcol(gs5)) yline(0) ///
			title("") ytitle("% change net enrollment") legend(cols(3))
	
		graph export "$figures/DiD/Provider/DiD_Provider_insured_change_perc.pdf", replace

	
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
	
* ---------------------- OLS Regression analysis 2009-2014 ------------------- *

* Load data again
use "$output/GKV_aggregate", clear

* Set panel var
xtset id year
	
* How many entries with add-on or rebate between 2010 and 2014?
	tab addon09_dummy rebate09_dummy if year>=2009 & year<2015 & insured_lead_ln!=.
	tab provider if addon09_dummy==1 & insured_lead_ln!=.
 
* Baseline: log(insurees) ~ addon09_dummy + rebate09_dummy

	* Regressions

		// Pooled OLS w/o controlling for initial provider size
		qui reg insured_lead_ln addon09_dummy rebate09_dummy i.year i.type if year>2009 & year<2015, vce(robust)
			estimates store reg_lnins_POLS
		
		// Pooled OLS with controlling for initial provider size
		qui reg insured_lead_ln addon09_dummy rebate09_dummy i.year i.type insured_initial_ln if year>=2009 & year<2015, vce(robust)
			estimates store reg_lnins_POLS_initsize
	
		// Pooled OLS with controlling for initial provider size and ratings
		
			// Rating sample w/o controlling
			qui reg insured_lead_ln addon09_dummy rebate09_dummy i.year i.type insured_initial_ln if year>=2009 & year<2015 & rating_relative!=., vce(robust)
	
			// Rating sample with controlling	
			qui reg insured_lead_ln addon09_dummy rebate09_dummy rating_relative i.year i.type insured_initial_ln if year>=2009 & year<2015, vce(robust)
				estimates store reg_lnins_POLS_initsize_rat
	
		// Fixed effects w/o controlling for ratings
		qui xtreg insured_lead_ln addon09_dummy rebate09_dummy i.year if year>=2009 & year<2015, fe
			estimates store reg_lnins_fe						
	
		// Fixed effects with controlling for ratings
		
			// Ratings sample w/o controlling
			qui xtreg insured_lead_ln addon09_dummy rebate09_dummy i.year if year>=2009 & year<2015 & rating_relative!=., fe
	
			// Ratings sample with controlling
			qui xtreg insured_lead_ln addon09_dummy rebate09_dummy rating_relative i.year if year>=2009 & year<2015, fe
				estimates store reg_lnins_fe_rat
				
	* Regression tables
	
		// Stata view
		esttab reg_lnins_POLS reg_lnins_POLS_initsize reg_lnins_POLS_initsize_rat reg_lnins_fe reg_lnins_fe_rat ///
			, drop(2010.year 2011.year 2012.year 2013.year 2014.year 1.type 2.type 3.type 4.type 5.type 6.type)

		// LaTex output
		esttab reg_lnins_fe reg_lnins_fe_rat reg_lnins_POLS reg_lnins_POLS_initsize reg_lnins_POLS_initsize_rat ///
			using "$tables/RegressionOutput/Aggregate/OLS09/Aggregate_reg_0914_baseline.tex" ///
				, star(* 0.05 ** 0.01 *** 0.001) booktabs width(0.95\hsize) ///
				title("Regression results for absolute add-on premium and rebates between 2009-14 (log insurees)" \label{tab:Aggregate09baseline}) ///
				addnotes("Dependent variable is log(insurees)" "All specification include year-fixed effects." "Pooled OLS controls for provider-type." "Rating is annual relative to max. rating")  ///
				style(tex) label se scalars(N_g g_avg r2_a) replace ///
				coef(insured_lead_ln "log(insurees)" addon09_dummy "Addon (dummy)" rebate09_dummy "Rebate (dummy)" rating_relative "Rating" insured_initial_ln "log(InititalInsurees)") ///
				drop(2010.year 2011.year 2012.year 2013.year 2014.year 1.type 2.type 3.type 4.type 5.type 6.type) ///
				mti("FE 1" "FE 2" "POLS 1" "POLS 2" "POLS 3")
		
* Additional specifiations 
 
	* Adjust variable (entries) for estout output 

		* Rename variables for eststo command
		rename insured_change_abs ica 
		rename insured_change_perc icp
		rename insured_change_perc_weighted icpw
		rename marketshare_change msc

		* Change unit of insured_change_abs to thousands
		replace ica = ica/1000
		replace insured = insured/1000
		
	* Remove outliers? 
		sum ica if year<2015 & year>2009, d
		tab addon09_dummy if (ica<r(p1) | ica>r(p99)) & ica!=. // issue: removes three observations with addon09=1
		
		
	* Pooled OLS regression for 2009-2014
		foreach lhs in ica icp icpw msc {
	
			* No outlier treatment
			
				// Baseline
				qui reg `lhs' addon09_dummy rebate09_dummy i.type i.year if year<2015 & year>2009, vce(robust)
					estimates store reg_POLS_`lhs'_09
		
				// Rating
					
					// Rating sample w/o controlling
					qui reg `lhs' addon09_dummy rebate09_dummy i.type i.year if year<2015 & year>2009 & rating_relative!=., vce(robust)
						estimates store reg_POLS_`lhs'_09_rats
				
					// Rating sample and controlling 
					qui reg `lhs' addon09_dummy rebate09_dummy i.type i.year rating_relative if year<2015 & year>2009, vce(robust)
						estimates store reg_POLS_`lhs'_09_rat
		
		
			* Censoring lower and upper 1% tail
				sum `lhs' if year<2015 & year>2009, d
			
					preserve 
						// Keep only if in middle 98%
						keep if `lhs'>=r(p1) & `lhs'<=r(p99) & year<2015 & year>2009
				
						* Regressions 
					
							// Baseline
							qui reg `lhs' addon09_dummy rebate09_dummy i.type i.year if year<2015 & year>2009, vce(robust)
								estimates store reg_POLS_`lhs'_09_out
		
							// Rating
							
								// Rating sample w/o controlling
								qui reg `lhs' addon09_dummy rebate09_dummy i.type i.year if year<2015 & year>2009 & rating_relative!=., vce(robust)
									estimates store reg_POLS_`lhs'_09_rats_out
				
								// Rating sample and controlling 
								qui reg `lhs' addon09_dummy rebate09_dummy i.type i.year rating_relative if year<2015 & year>2009, vce(robust)
									estimates store reg_POLS_`lhs'_09_rat_out
				
					restore	
		}
		
		
	* Fixed effects regression for 2009-2014
		foreach lhs in ica icp icpw msc {
	
			* No outlier treatment
			
				// Baseline
				qui xtreg `lhs' addon09_dummy rebate09_dummy i.year if year<2015 & year>2009, fe
					estimates store reg_FE_`lhs'_09
		
				// Rating
					
					// Rating sample w/o controlling
					qui xtreg `lhs' addon09_dummy rebate09_dummy i.year if year<2015 & year>2009 & rating_relative!=., fe
						estimates store reg_FE_`lhs'_09_rats
				
					// Rating sample and controlling 
					qui xtreg `lhs' addon09_dummy rebate09_dummy i.year rating_relative if year<2015 & year>2009, fe
						estimates store reg_FE_`lhs'_09_rat
		
		
			* Censoring lower and upper 1% tail
				sum `lhs' if year<2015 & year>2009, d
			
					preserve 
						// Keep only if in middle 98%
						keep if `lhs'>=r(p1) & `lhs'<=r(p99) & year<2015 & year>2009
				
						* Regressions 
					
							// Baseline
							qui xtreg `lhs' addon09_dummy rebate09_dummy i.year if year<2015 & year>2009, fe
								estimates store reg_FE_`lhs'_09_out
		
							// Rating
							
								// Rating sample w/o controlling
								qui xtreg `lhs' addon09_dummy rebate09_dummy i.year if year<2015 & year>2009 & rating_relative!=., fe
									estimates store reg_FE_`lhs'_09_rats_out
				
								// Rating sample and controlling 
								qui xtreg `lhs' addon09_dummy rebate09_dummy i.year rating_relative if year<2015 & year>2009, fe
									estimates store reg_FE_`lhs'_09_rat_out
				
					restore	
		}
	
	
	
	* Regression tables

		// Stata view
			local lhs icp // ica icp icpw msc
			local outlier // _out
			esttab reg_POLS_`lhs'_09`outlier' reg_POLS_`lhs'_09_rats`outlier' reg_POLS_`lhs'_09_rat`outlier' ///
				reg_FE_`lhs'_09`outlier' reg_FE_`lhs'_09_rats`outlier' reg_FE_`lhs'_09_rat`outlier' ///
				, drop(1.type 2.type 3.type 4.type 5.type 6.type 2010.year 2011.year 2012.year 2013.year 2014.year)
				
		// LaTex output
		esttab reg_FE_icp_09 reg_FE_icp_09_rats reg_FE_icp_09_rat reg_FE_msc_09 reg_FE_msc_09_rats reg_FE_msc_09_rat ///
			using "$tables/RegressionOutput/Aggregate/OLS09/Aggregate_reg_0914_addlhs.tex", ///
				style(tex) se replace ///
				star(* 0.05 ** 0.01 *** 0.001) booktabs width(0.95\hsize) ///
				title("Fixed effects regression using alternative LHS variables for 2009-2014" \label{tab:Aggregate09addlhs}) ///
				addnotes("Includes provider and year fixed effects" "Robust to using pooled OLS controlling for provider type" "Robust to excluding bottom/top 1\% of lhs variable") ///
				coef(addon09_dummy "Addon (dummy)" rebate09_dummy "Rebate (dummy)" rating_relative "Rating") ///
				drop(2010.year 2011.year 2012.year 2013.year 2014.year) ///
				mti("ICP 1" "ICP 2" "ICP 3" "MSC 1" "MSC 2" "MSC 3")
	
	* Undo variable changes
	
		* Rename again
			rename ica insured_change_abs 
			rename icp insured_change_perc
			rename icpw insured_change_perc_weighted
			rename msc marketshare_change

		* Readjust units
			replace insured_change_abs = insured_change_abs*1000	
			replace insured = insured*1000
	
	
* ---------------------- OLS Regression analysis 2015-2018 ------------------- *
eststo clear
/*
Regressions build up: 
	1) type + year effects 
	2) + initial size
	3) + ratings
	
	// can consider log revenue from health fund as well... 
*/


* Adjust variables for loop

	* Rename variables for eststo command
		rename insured_lead_ln illn
		rename insured_change_abs ica 
		rename insured_change_perc icp
		rename insured_change_perc_weighted icpw
		rename marketshare_change msc

		rename addon ao
		rename addon_ln aoln
		rename addon_change aoc
		rename addon_diff_avg ada
		rename addon_diff_predicted adp
		
	* Relabel variables for esttab output
		label var rating_relative "Rating (relative)"
	
	* Change unit of insured_change_abs to thousands
		replace ica = ica/1000
	
	* Define variables used in regression
		
		* Dependent variables
		global depvar illn ica icp msc
		
		* Explanatory variables
		global explar ao aoln aoc

		
* Ultimate regression loop
	eststo clear

		foreach lhs in $depvar {
			foreach rhs in $explar { 
			
				* Pooled OLS
			
					* Provider-type and year fixed effects
					eststo `lhs'_`rhs'_POLS: qui reg `lhs' `rhs' i.type i.year if year>=2015 & year<=2018, vce(robust)
						
					* Initial size
					eststo `lhs'_`rhs'_is_POLS: qui reg `lhs' `rhs' i.type i.year insured_initial_ln if year>=2015 & year<=2018, vce(robust)
			
					* Log revenue from health fund pc
					eststo `lhs'_`rhs'_is_rf_POLS: qui reg `lhs' `rhs' i.type i.year insured_initial_ln revenue_fund_pc_ln if year>=2015 & year<=2018, vce(robust)
			
					* Ratings
					
						// W/o ratings but sample of control
						eststo `lhs'_`rhs'_is_ras_POLS: qui reg `lhs' `rhs' i.type i.year insured_initial_ln if year>=2015 & year<=2018 & rating_relative!=., vce(robust)
					
						// Ratings with control
						eststo `lhs'_`rhs'_is_ra_POLS: qui reg `lhs' `rhs' i.type i.year insured_initial_ln rating_relative if year>=2015 & year<=2018, vce(robust)
					
				* Fixed effects
					
					* Year fixed effects
					eststo `lhs'_`rhs'_FE: qui xtreg `lhs' `rhs' i.year if year>=2015 & year<=2018, fe
						
					* Log revenue from health fund pc
					eststo `lhs'_`rhs'_rf_FE: qui xtreg `lhs' `rhs' i.year revenue_fund_pc_ln if year>=2015 & year<=2018, fe
			
					* Ratings
					
						// W/o ratings but sample of control
						eststo `lhs'_`rhs'_ras_FE: qui xtreg `lhs' `rhs' i.year if year>=2015 & year<=2018 & rating_relative!=., fe
					
						// Ratings with control
						eststo `lhs'_`rhs'_ra_FE: qui xtreg `lhs' `rhs' i.year rating_relative if year>=2015 & year<=2018, fe
				
			}
		}

	* Rename variables again
		rename  illn insured_lead_ln
		rename  ica insured_change_abs
		rename  icp insured_change_perc
		rename  icpw insured_change_perc_weighted 
		rename  msc marketshare_change
		rename  ao addon
		rename  aoln addon_ln
		rename  aoc addon_change
		rename  ada addon_diff_avg
		rename  adp addon_diff_predicted

		
	* Change unit of insured_change_abs again to thousands
		replace insured_change_abs = insured_change_abs*1000		
	
* Create regression output tables

	* Stata view
	
		// POLS
		local lhs msc   // illn ica icp msc
		local rhs ao     // ao aoln aoc adp
		local type POLS
		
		esttab `lhs'_`rhs'_`type' `lhs'_`rhs'_is_`type' `lhs'_`rhs'_is_rf_`type' `lhs'_`rhs'_is_ras_`type' `lhs'_`rhs'_is_ra_`type' ///
			, se drop(1.type 2.type 3.type 4.type 6.type 2015.year 2016.year 2017.year 2018.year)
		
		// FE
		local lhs msc   // illn ica icp msc
		local rhs ao     // ao aoln aoc adp
		local type FE
		
		esttab `lhs'_`rhs'_`type' `lhs'_`rhs'_rf_`type' `lhs'_`rhs'_ras_`type' `lhs'_`rhs'_ra_`type' ///
			, se drop(2015.year 2016.year 2017.year 2018.year)
		
		
	* Customized LaTex output
		
		// Baseline specification: log(insurees) ~ addon
		esttab illn_ao_FE illn_ao_ras_FE illn_ao_ra_FE illn_ao_POLS illn_ao_is_ras_POLS illn_ao_is_ra_POLS ///
			using "$tables/RegressionOutput/Aggregate/OLS15/Aggregate_reg_1518_baseline.tex" ///
				, star(* 0.05 ** 0.01 *** 0.001) booktabs width(0.95\hsize) ///
				title("Regression results for absolute add-on premium and rebates between 2015-18 (log insurees)" \label{tab:Aggregate15baseline}) ///
				addnotes("Dependent variable is log(insurees)" "All specification include year-fixed effects." "Pooled OLS controls for provider-type instead of provider fixed effects." "Rating is annual relative to max. rating")  ///
				style(tex) label se replace ///
				coef(illn "log(insurees)" ao "Addon (pp.)" rating_relative "Rating" insured_initial_ln "log(InitialInsuree)" revenue_fund_pc_ln "log(risk-transfer)") ///
				drop(2015.year 2016.year 2017.year 2018.year 1.type 2.type 3.type 4.type 6.type) ///
				mti("FE 1" "FE 2" "FE 3" "POLS 1" "POLS 2" "POLS 3")
		
		// Alternative lhs variables 
		esttab ica_ao_is_ra_POLS  ica_ao_ra_FE icp_ao_is_ra_POLS icp_ao_ra_FE msc_ao_is_ra_POLS msc_ao_ra_FE  ///
			using "$tables/RegressionOutput/Aggregate/OLS15/Aggregate_reg_1518_addlhs.tex" ///
				, star(* 0.05 ** 0.01 *** 0.001) booktabs width(0.95\hsize) ///
				title("Regression results for absolute add-on premium and rebates between 2015-18 (additional lhs)" \label{tab:Aggregate15addlhs}) ///
				addnotes("Dependent variable is as specified in column" "All specification include year-fixed effects." "Pooled OLS controls for provider-type instead of provider fixed effects." "Rating is annual relative to max. rating")  ///
				style(tex) label se replace ///
				coef(illn "log(insurees)" ao "Addon (pp.)" rating_relative "Rating" insured_initial_ln "log(InitialInsuree)" revenue_fund_pc_ln "log(risk-transfer)") ///
				drop(2015.year 2016.year 2017.year 2018.year 1.type 2.type 3.type 4.type 6.type) ///
				mti("ICA POLS" "ICA FE" "ICP POLS" "ICP FE" "MSC POLS" "MSC FE")
		
		// Alternative rhs variables
		esttab illn_aoln_ra_FE illn_aoc_ra_FE icp_aoln_ra_FE icp_aoc_ra_FE msc_aoln_ra_FE msc_aoc_ra_FE ///
			using "$tables/RegressionOutput/Aggregate/OLS15/Aggregate_reg_1518_addrhs.tex" ///
				, star(* 0.05 ** 0.01 *** 0.001) booktabs width(0.95\hsize) ///
				title("Regression results for absolute add-on premium and rebates between 2015-18 (additional lhs)" \label{tab:Aggregate15addrhs}) ///
				addnotes("Dependent variable is as specified in column" "All specification include provider and year fixed effects." "Pooled OLS controlling for provider-type yields consistent results")  ///
				style(tex) label se replace ///
				coef(illn "log(insurees)" aoln "log(addon)" aoc "$\Delta$ addon" rating_relative "Rating" insured_initial_ln "log(InitialInsuree)" revenue_fund_pc_ln "log(risk-transfer)") ///
				drop(2015.year 2016.year 2017.year 2018.year) ///
				mti("log(insurees)" "log(insurees)" "ICP" "ICP" "MSC" "MSC") ///
				order(aoln aoc)

				
* ----------------- Instrumental Variable Estimation 2015-2018 --------------- *

* Relevance condition

	* Plot relationship addon and admin cost
	local plot 0 
	
	if `plot'==1 {
	
		twoway (scatter addon expenditure_admin_pc_ln) (lfit addon expenditure_admin_pc_ln) ///
			(lfit addon expenditure_admin_pc_ln if expenditure_admin_pc_ln>3.5) if year>=2015 & year <=2018 ///
			, legend(lab(1 "Scatter all") lab(2 "Fit all") lab(3 "Fit >3.5")) ///
			title("Relationship between add-on premium and admin costs pc") ///
			subtitle("Pooled over 2015-2018") ytitle("Percentage points")

			graph export "$figures/Exploratory/IVestimation/IV_relationship_ada_adminpc.png", replace
	
		}
	else{
		disp "Plot not activated."
		}
	
	* "first-stage" regression
	
		* admin cost only
		reg addon expenditure_admin_pc if year>2014 & year<2019
		
		* admin cost and reserves
		reg addon expenditure_admin_pc capital_reserves_pc if year>2014 & year<2019
		
		* admin costs, reserves and additional controls
		reg addon expenditure_admin_pc capital_reserves_pc insured_initial_ln i.year i.type ///
			revenue_fund_pc_ln if year>2014 & year<2019

	
* Exclusion restriction and independence condition

	// How to test it?
	// Currently seems violated?
	
	* Explore relationships between admin costs and other characteristics
	reg expenditure_admin_pc insured_initial_ln rating_relative ///
		i.year i.type ///
		if year>2014 & year<2019, vce(robust)
		
		// -> conditionally .. no significant correlation between rating and admin costs
		
	* Explore relationships between admin costs and other characteristics
	reg capital_reserves_pc insured_initial_ln rating_relative ///
		i.year i.type ///
		if year>2014 & year<2019, vce(robust)
		
		// -> conditionally .. no significant correlation between risk transfer and capital reserves		

* IV regression
		
	* Adjust variables for better estout output
		
		* Rename variables for eststo command
		rename insured_change_abs ica 
		rename insured_change_perc icp
		rename insured_lead_ln illn
		rename marketshare_change msc
		
		rename addon ao
		rename addon_change aoc
		rename addon_diff_avg ada
		rename addon_diff_predicted adp
		
	
		* Change unit of insured_change_abs to thousands
		replace ica = ica/1000
		
	* Second-stage estimation
			
		foreach lhs in illn icp msc {
			foreach rhs in ao {
		
		* No outlier treatment
		
			// IV regression
			qui ivreg2 `lhs' i.type i.year insured_initial_ln rating_relative ///
				(`rhs' = expenditure_admin_pc) ///
				if year>2014 & year<2019, robust 
			estimates store iv_`lhs'_`rhs'
				
			// OLS equivalent	
			qui reg `lhs' `rhs' i.type i.year insured_initial_ln rating_relative ///
				if year>2014 & year<2019 & expenditure_admin_pc!=., vce(robust)
			estimates store iv_ols_`lhs'_`rhs'
								
		* Outlier treatment
		
			// define outliers
				cap drop outlier
				gen outlier=0 
					label var outlier "Variable capturing whether variable is outlier"	
			
				foreach var in `lhs' expenditure_admin_pc {
					qui sum `var' if year>2014 & year<2019, d
						replace outlier=1 if (`var'<r(p1) | `var'>r(p99)) ///
						& (`var'!=. & year>2014 & year<2019)
				}
				
			// IV regression
			qui ivreg2 `lhs' i.type i.year insured_initial_ln rating_relative ///
				(`rhs' = expenditure_admin_pc ) ///
				if year>2014 & year<2019 & outlier==0, robust
			estimates store iv_`lhs'_`rhs'_out
			
			// OLS equivalent	
			qui reg `lhs' `rhs' i.type i.year insured_initial_ln rating_relative if year>2014 & year<2019 & expenditure_admin_pc!=. ///
				& outlier==0, vce(robust)
			estimates store iv_ols_`lhs'_`rhs'_out
			
			}
		}
	
	
		* Export second-stage regression results 
		
			// log(insurees) and icp
			esttab iv_ols_illn_ao iv_illn_ao iv_ols_msc_ao iv_msc_ao ///
				using "$tables/RegressionOutput/Aggregate/IV/Aggregate_IV_secondstage.tex" ///
					, replace booktabs star(* 0.05 ** 0.01 *** 0.001) width(0.95\hsize) ///
					style(tex) title("Second-stage results of IV of add-on premium"\label{tab:IVaggregatesecondstage}) se ///
					mti("OLS log(insurees)" "IV log(insurees)" "OLS MSC" "IV MSC") ///
					order(ao) ///
					coef(ao "Add-on (pp.)" revenue_fund_pc_ln "log(risk-transfer)" insured_initial_ln "log(InititalInsurees)" expenditure_admin_pc "Admin Exp. pc" rating_relative "Rating") ///
					drop(2015.year 2016.year 2017.year 2018.year 1.type 2.type 3.type 4.type 6.type)


		* Export first-stage results		
			
			// no outlier treatment
			eststo fs_illn: reg ao expenditure_admin_pc i.type i.year insured_initial_ln rating_relative ///
				if illn!=. & year>2014 & year<2019
				
			eststo fs_icp: reg ao expenditure_admin_pc i.type i.year insured_initial_ln rating_relative ///
				if icp!=. & year>2014 & year<2019
				
			eststo fs_msc: reg ao expenditure_admin_pc i.type i.year insured_initial_ln rating_relative ///
				if msc!=. & year>2014 & year<2019
	
			// export esttab results
			esttab fs_illn fs_msc using "$tables/RegressionOutput/Aggregate/IV/Aggregate_IV_firststage.tex" ///
				, replace booktabs star(* 0.05 ** 0.01 *** 0.001) width(0.95\hsize) ///
				style(tex) title("First-stage results of IV of add-on premium" \label{tab:IVaggregatefirststage}) se ///
				stats(N r2 ar2) ///
				mti("log(insurees)" "MSC") ///
				coef(expenditure_admin_pc "Admin pc" insured_initial_ln "log(InitialInsurees)" revenue_fund_pc_ln "log(risk-transfer)"  rating_relative "Rating") ///
				drop(2015.year 2016.year 2017.year 2018.year 1.type 2.type 3.type 4.type 6.type)
					
	
* Rename variables again
	rename  ica insured_change_abs
	rename  icp insured_change_perc
	rename  illn insured_lead_ln
	rename  msc marketshare_change

	rename  ao addon
	rename  aoc addon_change
	rename  ada addon_diff_avg
	rename  adp addon_diff_predicted	
		
	* Change unit of insured_change_abs again to thousands
	replace insured_change_abs = insured_change_abs*1000
	
* Can we also run IV including provider FE? No. First stage doesn't have predictive power anymore.
	xtivreg insured_lead_ln i.year rating_relative (addon = expenditure_admin_pc), fe first
