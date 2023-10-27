********************************************************************************
*********************** GKV AGGREGATE - DID CLEAN ******************************
********************************************************************************

/* 	OBJECTIVES
	
	OUTLINE
	0) Preliminaries
	1) Data	
	2) Prepare data for DiD
	3) Run regression for DiD with y = insured_lead_ln
	4) Plot figure 
	5) Additional tests
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
log using "$logs_analysis/`date'_analysis_gkv_DID_AboveBelow.log", text replace	

* ============================================================================ *
* Section : Below vs Above
* ============================================================================ *

* Initiate loop over group variable 
foreach cut in avg /*med*/ {

	di "-----------------------------------------------------------------------"
	di "No running version: `cut'"
	di "-----------------------------------------------------------------------"

	* 1) Data
	* -------------------------------------------------------------------------*

	* Load data
	use "$data_final/GKV_aggregate", clear

	* Set panel var
	xtset id year

	* Number of ratings variables available
	foreach var in rating service wahltarife bonusprogramme altmedicine healthsupport zusatz {
		gen `var'_d = (`var'!=.) if year>=2009 & year<=2018
		bysort provider: egen `var'_sum = total(`var'_d)
		tab `var'_sum
		//replace `var'=. if `var'_sum < 10 									// balanced panel
		//replace `var'_relative=. if `var'_sum < 10 							// balanced panel
		drop `var'_d
	}

	* Express ratings in terms of standard deviations 
	foreach var in insured_lead_ln rating service wahltarife bonusprogramme altmedicine healthsupport zusatz {
		gen `var'_sd = .
		forvalues y = 2009/2018 {	
			sum `var' if year==`y'
			replace `var'_sd = `var'/`r(sd)' if year==`y'
		} 
	}

	* 2) Prepare data for DiD
	* ------------------------------------------------------------------------ *

	* Drop those that charged addon premium in 2010-12

		// Ever charged an add-on premium
		cap drop addon09_dummy_ever
		bysort provider: egen addon09_dummy_ever = max(addon09_dummy)
		
			tab provider if addon09_dummy_ever==1
			drop if addon09_dummy_ever==1 
			drop if provider=="DAK-Gesundheit"
			
		// Drop providers without did group
		tab provider if addon_did_group==.
		drop if addon_did_group==.
		
	* Generate group dummys

		tab addon_did_`cut'_group

		bysort provider: gen temp = _n 
		tab addon_did_avg_group if temp == 1 
		tab addon_did_med_group if temp == 1

		// Below average
		cap drop below
		gen below = 1 if addon_did_`cut'_group==1
		replace below = 0 if below==.
		
		// Average 
		cap drop average
		gen average = 1 if addon_did_`cut'_group==2
		replace average = 0 if average==. 
		
		// Above average
		cap drop above
		gen above = 1 if addon_did_`cut'_group==3
		//replace above = 1 if addon_did_`cut'_group==2 // XX KP test this
		replace above = 0 if above==.
		

	* Keep only above and below average group 
	keep if above==1 | below==1
	//assert addon_did_`cut'_group!=2

	* Generate post dummy
	cap drop post
	gen post = 1 if year > 2014
	replace post = 0 if post==.
			
	* Add overall DiD coefficients
	cap drop did_below
	gen did_below = post*below

	cap drop did_above 
	gen did_above = post*above


	* 3) Run regression for DiD with y = insured_lead_ln
	* ------------------------------------------------------------------------ *
	foreach yvar in insured_lead_ln /*insured_change_perc*/ marketshare_change 		///
					members_ln rating_sd /*revenue_fund_pc_ln service_sd wahltarife_sd				///
					bonusprogramme_sd altmedicine_sd healthsupport_sd zusatz_sd*/  { 

		* Add overall DiD coefficients
		reghdfe `yvar' below did_below insured_initial_ln if year<2019, absorb(year type)
		local b_below = trim("`: di %10.3fc _b[did_below]'")
		local se_below = trim("`: di %10.3fc _se[did_below]'")

		* DiD over years	
			
		// DiD group dummies
		forvalues j=1/9 {
			
			// Above
			cap drop above`j'
			gen above`j' = 1 if addon_did_group==3
			replace above`j' = 0 if above`j'==.
			
			cap drop did_above`j'
			gen did_above`j' = post*did_above
			
			// Below
			cap drop below`j'
			gen below`j' = 1 if addon_did_group==1
			replace below`j' = 0 if below`j'==.
			
			cap drop did_below`j'
			gen did_below`j' = post*did_below
		}

		// Dummies for year
		forvalues i=2009/2018 {

			// Year dummies
			cap drop d_`i'
			gen d_`i'=(year==`i')
			
			// By year and group
			cap drop d_`i'_above_t
				gen d_`i'_above_t = (year==`i' & above==1)
				
			cap drop d_`i'_below_t
				gen d_`i'_below_t = (year==`i' & below==1)
		}

		// Drop baseline 
		drop d_2014 d_2014_above_t d_2014_below_t

		// Regression
		reghdfe `yvar' below d_*_below_t d_20* insured_initial_ln if year<2019, absorb(type)

		// Baseline effects (2014)
		cap drop ball_t
			gen ball_t=0 if year==2014

		// Assign coefficients and CI for graph
		foreach group in /*above*/ below {

			// Create variables for following assignment
			foreach var in ball upall lowall { 
			cap drop `var'_`group'
				gen `var'_`group'=.
			}

			// Pre
			forvalues y=2009/2013 {
				replace ball_`group' = _b[d_`y'_`group'_t] if year==`y'
				replace upall_`group' = _b[d_`y'_`group'_t] + 1.96*_se[d_`y'_`group'_t] if year==`y'
				replace lowall_`group' = _b[d_`y'_`group'_t] - 1.96*_se[d_`y'_`group'_t] if year==`y'
			}
			
			// Post
			forvalues y=2015/2018 {
				replace ball_`group' = _b[d_`y'_`group'_t] if year==`y'
				replace upall_`group' = _b[d_`y'_`group'_t]  + 1.96*_se[d_`y'_`group'_t] if year==`y'
				replace lowall_`group' = _b[d_`y'_`group'_t] - 1.96*_se[d_`y'_`group'_t] if year==`y'
			}
		}

		replace ball_below = 0 if year==2014
		//replace ball_above = 0 if year==2014

		sort year

		* 4) Plot figure
		* -------------------------------------------------------------------- *

		* Identify yscale
		qui sum upall_below   
		local ymin = -round(abs(`r(min)') + 0.05,0.1)
		qui sum upall_below 
		local ymax = round(`r(max)' + 0.05,0.1)
		di "(`ymin', `ymax')"

		* Overwrite yscale settings for paper graphs

			* Rating
			if "`yvar'"=="rating_relative" & "`cut'"=="avg" {
				local ymin 		= -20
				local ymax 		= 20 
				local ymin_text = -19
				local ymax_text = 19
			}

			* Rating_sd
			else if "`yvar'"=="rating_sd" & "`cut'"=="avg" {
				local ymin 		= -2.3
				local ymax 		= 2.3 
				local ymin_text = -2.2
				local ymax_text = 2.2
			}

			else if "`yvar'"=="rating_sd" & "`cut'"=="med" {
				local ymin 		= -1.6
				local ymax 		= 1.6 
				local ymin_text = -1.5
				local ymax_text = 1.5
			}

			* Net Enrollment
			else if "`yvar'"=="insured_lead_ln"  & "`cut'"=="avg" {
				local ymin 		= -0.6
				local ymax 		= 0.6 
				local ymin_text = -0.57
				local ymax_text = 0.57
			}

			else if "`yvar'"=="insured_lead_ln"  & "`cut'"=="med" {
				local ymin 		= -0.5
				local ymax 		= 0.5 
				local ymin_text = -0.47
				local ymax_text = 0.47
			}

			* Aggregate Membership
			else if "`yvar'"=="members_ln"  & "`cut'"=="avg" {
				local ymin 		= -0.6
				local ymax 		= 0.6 
				local ymin_text = -0.57
				local ymax_text = 0.57
			}

			else if "`yvar'"=="members_ln"  & "`cut'"=="med" {
				local ymin 		= -0.5
				local ymax 		= 0.5 
				local ymin_text = -0.47
				local ymax_text = 0.47
			}

			* Market share change
			else if "`yvar'"=="marketshare_change" & "`cut'"=="avg" {
				local ymin 		= -0.6
				local ymax 		= 0.6 
				local ymin_text = -0.57
				local ymax_text = 0.57
			}

			else if "`yvar'"=="marketshare_change" & "`cut'"=="med" {
				local ymin 		= -0.5
				local ymax 		= 0.5 
				local ymin_text = -0.47
				local ymax_text = 0.47
			}

			
			else if "`yvar'"=="revenue_fund_pc_ln" {
				local ymin = -0.6
				local ymax = 0.6
				local ymin_text = -0.5
				local ymax_text = 0.5
			}


			else  {
				sum `yvar'
				local ymin 		= `r(min)'
				local ymax 		= `r(max)' 
				local ymin_text = `r(min)'
				local ymax_text = `r(max)'
			}

		* Y-axis label 
		if "`yvar'"=="insured_lead_ln"  			local ytext "Effect on log(enrollment)"
		else if "`yvar'"=="insured_change_perc"  	local ytext "Effect on net enrollment change (%)"
		else if "`yvar'"=="marketshare_change"  	local ytext "Effect on market share change"
		else if "`yvar'"=="members_ln"  			local ytext "Effect on log(members)"
		else if "`yvar'"=="rating_relative"  		local ytext "Effect on relative rating (pp.)"
		else if "`yvar'"=="rating_sd"  				local ytext "Effect on rating (standard deviations)"
		else 										local ytext "Effect on `yvar'"

		* Adjust available years
		if "`yvar'"=="members_ln" | "`yvar'"=="revenue_fund_pc_ln" {
			foreach plotvar in /*ball_above upall_above lowall_above*/ ball_below upall_below lowall_below {
				replace `plotvar' = . if year<2012
			}
		}

		* Additional plot settings 
		if "`yvar'"=="rating_sd" & "`cut'"=="med" 		local ylab = "ylab(-1.5(0.5)1.5)"
		else if "`yvar'"!="rating_sd" & "`cut'"=="avg"  local ylab = "ylab(-0.6(0.2)0.6)"
		else if "`yvar'"!="rating_sd" & "`cut'"=="med"  local ylab = "ylab(-0.5(0.25)0.5)"
		else 											local ylab = ""

		* Plot graph
		local date $date
		graph twoway ///
			(connected ball_below year, msize(medsmall) lcolor(navy) mcolor(navy) lpattern(solid) lwidth(medthin)) ///
			(rcap upall_below lowall_below year, lcolor(navy) mcolor(navy) lpattern(solid)) ///
			if (year>=2009 & year<=2018) ///
			, yline(0, lcolor(black)) xtitle("Year", height(6)) xscale(range(2009 2018)) xlabel(2009 (1) 2018) yscale(range(`ymin' `ymax')) `ylab' ///
			xline(2014.5, lp(dash) lcol(gs5)) ///
			legend(order(1 "Below average")) ///
			text(`ymax_text' 2016.5 "ß_below = `b_below' (`se_below')", size(medsmall)) ///
			ytitle("`ytext'")
			
		graph export "$figures/DiD/Provider/`date'_DiD_Provider_`cut'_`yvar'_V2_BelowVSAbove.pdf", replace
		graph close

		* 5) Additional tests
		* -------------------------------------------------------------------- *	

		* Test for pre-trends
		test (d_2012=0) (d_2013=0) 


	} // close loop `yvar'
} // close loop `cut'


* Close log file 
cap log close 
