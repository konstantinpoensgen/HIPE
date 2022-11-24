********************************************************************************
*********************** GKV AGGREGATE - REGRESSIONS ****************************
********************************************************************************

/* 	OBJECTIVES
	


	OUTLINE
	0) Preliminaries
	1) Data
	2) IV conditions
	3) IV regressions
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
log using "$logs_analysis/`date'_analysis_gkv_aggregate_regs_iv.log", text replace	


* 1) Data
* ---------------------------------------------------------------------------- *

* Load data
use "$data_final/GKV_aggregate", clear

* Set panel var
xtset id year

//drop addon 
//ren addon_ln addon 

* 2) IV conditions
* ---------------------------------------------------------------------------- *

	* Relevance condition
	* ..........................................................................

	* Plot relationship addon and admin cost
	local plot 0 
	
	if `plot'==1 {
	
		twoway (scatter addon expenditure_admin_pc_ln) (lfit addon expenditure_admin_pc_ln) ///
			(lfit addon expenditure_admin_pc_ln if expenditure_admin_pc_ln>3.5) if year>=2015 & year <=2018 ///
			, legend(lab(1 "Scatter all") lab(2 "Fit all") lab(3 "Fit >3.5")) ///
			title("Relationship between add-on premium and admin costs pc") ///
			subtitle("Pooled over 2015-2018") ytitle("Percentage points")

			local date $date
			graph export "$figures/Exploratory/IVestimation/`date'_IV_relationship_ada_adminpc.png", replace
	
	}
	
	* "first-stage" regression - Explorations

		* admin cost only
		reg addon expenditure_admin_pc if year>2014 & year<2019
		
		* admin cost and reserves
		reg addon expenditure_admin_pc capital_reserves_pc if year>2014 & year<2019
		
		* admin costs, reserves and additional controls
		reg addon expenditure_admin_pc capital_reserves_pc insured_initial_ln i.year i.type ///
			revenue_fund_pc_ln if year>2014 & year<2019

	* Final first-stage regression

		* Regression
		reghdfe addon expenditure_admin_pc insured_initial_ln rating_relative 	///
			if year>=2015 & year<=2018, vce(cluster provider) absorb(type year)

	
	* Exclusion restriction and independence condition
	* ..........................................................................

	// In general, this condition cannot be tested. 
	
	* Express in standard deviations 
	foreach var in rating_relative expenditure_admin_pc capital_reserves_pc addon {
		sum `var'
		local sd = `r(sd)'
		cap drop `var'_sd
		gen `var'_sd = `var' / `sd' 
	}

	* Corr(instrument, rating) 
	reg rating_relative_sd expenditure_admin_pc_sd insured_initial_ln i.year i.type if year>2014 & year<2019, vce(robust)
	
	// (i) no significant correlation between rating and admin costs
	// (ii) 95% CI rules out large effect: 1 sd higher admin expenditure, leads to [-0.17,0.04]
		
	* Corr(instrument, rating) + Corr(instrument2, rating)
	reg rating_relative_sd expenditure_admin_pc_sd capital_reserves_pc_sd insured_initial_ln i.year i.type if year>2014 & year<2019, vce(robust)
	

* 3) IV regression
* ------------------------------------------------------------------------------	
foreach end_rhs in premium_ln addon {
foreach fe in t p {

	* Assign instrument
	if "`end_rhs'" == "premium_ln"	local Z_var expenditure_admin_pc_ln
	if "`end_rhs'" == "addon"		local Z_var expenditure_admin_pc

	* Adjust variables for better estout output
		
		* Rename variables for eststo command
		rename insured_change_perc icp
		rename insured_lead_ln illn
		rename marketshare_change msc
		ren members_ln mln 
		
		ren `end_rhs' ao
		ren `Z_var' admin

		ren insured_initial_ln 	initial
		ren rating_relative_ln 	rating2


	* ..........................................................................
	* Second-stage estimation	
	* ..........................................................................

	* Set fixed effect 
	if "`fe'"=="t"		local FE "type"
	else if "`fe'"=="t"	local FE "provider"
	else 				local FE "provider"

	* Set control variable for initial-enrollment
	if "`fe'"=="t"		local controls = "initial rating2"
	else  				local controls = ""


	* Identify OLS sample
	cap drop sample_ols
	qui reghdfe illn ao `controls' if year>=2015 & year<=2018, cluster(provider) absorb(provider year)
	gen sample_ols = e(sample) 

	* Run IV and OLS regression
	local j = 1
	foreach lhs in illn /*icp msc*/ mln {												
		foreach rhs in ao {
	
			* IV regression
			ivreghdfe `lhs' (`rhs' = admin /*capital_reserves_pc*/) 	///
				`controls' if year>2014 & year<2019 & sample_ols==1, 		///
				absorb(`FE' year) cluster(provider) savefp(first_`fe'_`lhs'_`end_rhs') 			// XX KP (22-08-27): changed to clustered SE
stop
				* Store estimates
				estimates store iv_`fe'_`lhs'_`rhs'
				local N_iv_`lhs'  = trim("`: di %10.0fc e(N)'") 
				local N2_iv_`lhs' = trim("`: di %10.0fc e(N_clust)'")

				* Sample mean
				qui sum `lhs' if e(sample)==1
				local mean_`lhs'_iv = trim("`: di %10.2fc `r(mean)''")

			* OLS equivalent
			reghdfe `lhs' `rhs' `controls' if year>2014 & year<2019 & admin!=. & sample_ols==1, ///
				absorb(`FE' year) vce(cluster provider)

				* Store estimates
				estimate store ols_`fe'_`lhs'_`rhs' 
				local N_ols_`lhs' 	= trim("`: di %10.0fc e(N)'") 	
				local N2_ols_`lhs' 	= trim("`: di %10.0fc e(N_clust)'")

				* Sample mean
				qui sum `lhs' if e(sample)==1
				local mean_`lhs'_ols = trim("`: di %10.2fc `r(mean)''")	

			* Store output for latex table
			foreach X in `rhs' initial rating2 {
				
				* Initiate latex row 
				if `j'==1 {
					local b_`X' = ""
					local se_`X' = ""
				}
				
				* Is the coefficient available?
				cap di _b[`X']

				* No? 
				if _rc {
					local b_`X'		= "`b_`X'' & "
					local se_`X'	= "`se_`X'' & "
				}

				else {
				foreach reg in ols iv {
						
					* Restore estimates
					estimates restore `reg'_`fe'_`lhs'_`rhs'

					* Coef and SE
					local coef 	= trim("`: display %10.3fc _b[`X']'")
					local se	= trim("`: display %10.3fc _se[`X']'")
	
					* Format with stars
					local p 	= 2 * ttail(e(df_r), abs(_b[`X']/_se[`X']))
					local st	= cond(`p'<.001,"***",cond(`p'<.01,"**",cond(`p'<.05,"*","")))
					
					* Format 
					local b_`X' 	= "`b_`X'' & `coef'`st'" 
					local se_`X' 	= "`se_`X'' & (`se')"
				}
				}

			} 
		} 																		// close loop `rhs'
		local j = `j' + 1 
	} 																			// close loop `lhs'
		
	* Export second stage latex output

	if "`end_rhs'"=="premium_ln"	local text_ao = "Premium (log)"
	if "`end_rhs'"=="addon"			local text_ao = "Add-on (pp.)"

	if "`fe'"=="t" {
		capture file close myfile
		local date = "$date"
		file open myfile using "$tables/RegressionOutput/Aggregate/IV/`date'_Aggregate_IV_secondstage_`end_rhs'.tex", write replace
		
		# delimit ;
		file write myfile 		"\begin{tabular*}{\textwidth}{@{\hskip\tabcolsep\extracolsep\fill}l*{4}{c}}  " _n
								"\toprule" _n 
								"& \multicolumn{2}{|c}{Enrollment (log)} & \multicolumn{2}{|c}{Paying Members (log)} \\" _n 
								"& \multicolumn{1}{|c}{(1)} & (2) & \multicolumn{1}{|c}{(3)} & (4) \\" _n 
								"& \multicolumn{1}{|c}{OLS} & IV & \multicolumn{1}{|c}{OLS} & IV \\ \midrule" _n 
								" `text_ao' `b_ao' 	\\" _n
								"		 		`se_ao'	\\ [6pt]" _n
								"Initial enrollment (log)	`b_initial' \\" _n
								"		 					`se_initial' \\ [6pt]" _n
								"Rating (log)		`b_rating2' \\" _n
								"		 	`se_rating2' \\ [6pt] \midrule" _n
								"Provider-type FE & Yes & Yes & Yes & Yes \\" _n 
								"Year FE & Yes & Yes & Yes & Yes \\ \midrule" _n 
								"Mean outcome & `mean_illn_ols' & `mean_illn_iv' & `mean_mln_ols' & `mean_mln_iv' \\" _n 
								"Observations & `N_ols_illn' & `N_iv_illn' & `N_ols_mln' & `N_iv_mln' \\" _n 
								"Number of insurers & `N2_ols_illn' & `N2_iv_illn' & `N2_ols_illn' & `N2_iv_illn' \\ \bottomrule" _n 
								"\end{tabular*}"
		 ;
		# delimit cr
		file close myfile
	}

	if "`fe'"=="p" {
		capture file close myfile
		local date = "$date"
		file open myfile using "$tables/RegressionOutput/Aggregate/IV/`date'_Aggregate_IV_secondstage_`end_rhs'_providerFE.tex", write replace
		
		# delimit ;
		file write myfile 		"\begin{tabular*}{\textwidth}{@{\hskip\tabcolsep\extracolsep\fill}l*{4}{c}}  " _n
								"\toprule" _n 
								"& \multicolumn{2}{|c}{Enrollment (log)} & \multicolumn{2}{|c}{Paying Members (log)} \\" _n 
								"& \multicolumn{1}{|c}{(1)} & (2) & \multicolumn{1}{|c}{(3)} & (4) \\" _n 
								"& \multicolumn{1}{|c}{OLS} & IV & \multicolumn{1}{|c}{OLS} & IV \\ \midrule" _n 
								" `text_ao' `b_ao' 	\\" _n
								"		 		`se_ao'	\\ [6pt] \midrule " _n
								"Provider FE & Yes & Yes & Yes & Yes \\" _n 
								"Year FE & Yes & Yes & Yes & Yes \\ \midrule" _n 
								"Mean outcome & `mean_illn_ols' & `mean_illn_iv' & `mean_mln_ols' & `mean_mln_iv' \\" _n 
								"Observations & `N_ols_illn' & `N_iv_illn' & `N_ols_mln' & `N_iv_mln' \\" _n 
								"Number of insurers & `N2_ols_illn' & `N2_iv_illn' & `N2_ols_illn' & `N2_iv_illn' \\ \bottomrule" _n 
								"\end{tabular*}"
		 ;
		# delimit cr
		file close myfile
	}
	

	* Rename variables back 
	ren icp insured_change_perc
	ren illn insured_lead_ln
	ren msc marketshare_change
	ren mln members_ln
	
	ren ao `end_rhs' 
	ren admin `Z_var'

	ren initial insured_initial_ln 
	ren rating2 rating_relative_ln 

} // close loop `fe'
} // close loop `end_rhs'


	* ..........................................................................
	* Second-stage estimation & exclusion explorations 	
	* ..........................................................................	

	* Rename variables
	ren expenditure_admin_pc admin 
	ren insured_lead_ln illn
	ren insured_initial_ln initial
	ren addon ao 

	* First-stage - Premium (log)
	estimates restore first_t_illn_premium_lnao

		* Store coefficients
		foreach X in admin initial rating2 {

			* Observations and clusters
			local N_first_pr  = trim("`: di %10.0fc e(N)'") 
			local N2_first_pr = trim("`: di %10.0fc e(N_clust)'")

			* Coef and SE
			local coef 	= trim("`: display %10.3fc _b[`X']'")
			local se	= trim("`: display %10.3fc _se[`X']'")

			* Format with stars
			local p 	= 2 * ttail(e(df_r), abs(_b[`X']/_se[`X']))
			local st	= cond(`p'<.01,"***",cond(`p'<.05,"**",cond(`p'<.1,"*","")))
			
			* Format 
			local b_`X'_first_pr 	= "`coef'`st'" 
			local se_`X'_first_pr 	= "(`se')"
		}


		* Mean outcome
		sum premium_ln if year>2014 & year<2019 & admin!=. & ao!=. & illn!=. & rating!=. & initial!=. & sample_ols==1
		//assert `r(N)' == `N_iv_illn'
		local mean_first_pr = trim("`: di %10.2fc `r(mean)''")

	* First-stage - Addon (pp.)
	estimates restore first_t_illn_addonao

		* Store coefficients
		foreach X in admin initial rating2 {

			* Observations and clusters
			local N_first  = trim("`: di %10.0fc e(N)'") 
			local N2_first = trim("`: di %10.0fc e(N_clust)'")

			* Coef and SE
			local coef 	= trim("`: display %10.3fc _b[`X']'")
			local se	= trim("`: display %10.3fc _se[`X']'")

			* Format with stars
			local p 	= 2 * ttail(e(df_r), abs(_b[`X']/_se[`X']))
			local st	= cond(`p'<.01,"***",cond(`p'<.05,"**",cond(`p'<.1,"*","")))
			
			* Format 
			local b_`X'_first 	= "`coef'`st'" 
			local se_`X'_first 	= "(`se')"
		}


		* Mean outcome
		sum ao if year>2014 & year<2019 & admin!=. & ao!=. & illn!=. & rating!=. & initial!=. & sample_ols==1
		//assert `r(N)' == `N_iv_illn'
		local mean_first = trim("`: di %10.2fc `r(mean)''")


	* Exclusion restriction tests	
	
		* Rename 
		cap drop rev2
		gen rev2 = revenue_fund_ln				  
		ren rating_relative_ln rating2 

		* Loop over outcomes
		foreach y in rating2 rev2  {

			* Regression
			if "`y'"=="rating2" 	local controls = "initial"
			else 					local controls = "initial rating2"

			//local controls = ""

			reghdfe `y' admin `controls' if year>2014 & year<2019 & admin!=. & ao!=. & illn!=. & rating!=. & initial!=. & sample_ols==1, absorb(type year) vce(cluster provider)

			* Store coefficients

				* Observations and clusters
				local N_`y'  = trim("`: di %10.0fc e(N)'") 
				local N2_`y' = trim("`: di %10.0fc e(N_clust)'")

				* Store coefficients
				foreach X in admin `controls' {

					* Coef and SE
					if 	_b[`X'] < 100 			local coef 	= trim("`: display %10.3fc _b[`X']'")
					else if	_b[`X'] < 1000 		local coef 	= trim("`: display %10.1fc _b[`X']'")
					else 						local coef 	= trim("`: display %10.0fc _b[`X']'")

					if 	_se[`X'] < 10 			local se	= trim("`: display %10.3fc _se[`X']'")
					else if _se[`X'] < 1000 	local se	= trim("`: display %10.1fc _se[`X']'")
					else 						local se	= trim("`: display %10.0fc _se[`X']'")
					
					* Format with stars
					local p 	= 2 * ttail(e(df_r), abs(_b[`X']/_se[`X']))
					local st	= cond(`p'<.01,"***",cond(`p'<.05,"**",cond(`p'<.1,"*","")))
					
					* Format 
					local b_`X'_`y' 	= "`coef'`st'" 
					local se_`X'_`y' 	= "(`se')"
				}

			* Mean outcome
			sum `y' if e(sample)==1
			if `r(mean)' < 1000 	local mean_`y' = trim("`: di %10.2fc `r(mean)''")
			else  					local mean_`y' = trim("`: di %10.0fc `r(mean)''")
		}

	* Export table
	capture file close myfile
	local date = "$date"
	file open myfile using "$tables/RegressionOutput/Aggregate/IV/`date'_Aggregate_IV_firststage.tex", write replace
	
	# delimit ;
	file write myfile 		"\begin{tabular*}{\textwidth}{@{\hskip\tabcolsep\extracolsep\fill}l*{4}{c}}  " _n
							"\toprule" _n 
							"& (1) & (2) & (3) & (4) \\" _n
							"& Premium (log)	& Add-on (pp.) & Rating (log) & Health fund (log) \\ \midrule" _n 
							"Admin expenditure 	& `b_admin_first_pr' & `b_admin_first' & `b_admin_rating2' & `b_admin_rev2' \\" _n
							"					& `se_admin_first_pr' & `se_admin_first' & `se_admin_rating2' & `se_admin_rev2' \\ [6pt]" _n
							"Initial enrollment (log) 	& `b_initial_first_pr' & `b_initial_first' & `b_initial_rating2' & 0.023 \\" _n
							"							& `se_initial_first_pr' & `se_initial_first' & `se_initial_rating2' & (0.027)  \\ [6pt]" _n
							"Rating (log) 	& `b_rating2_first_pr' & `b_rating2_first' &  & -0.140 \\" _n
							"				& `se_rating2_first_pr' & `se_rating2_first' &  & (0.145) \\ [6pt] \midrule" _n
							"Provider-type FE & Yes & Yes & Yes  & Yes \\" _n 
							"Year FE & Yes & Yes & Yes & Yes \\ \midrule" _n 
							"Mean outcome & `mean_first_pr' & `mean_first' & `mean_rating2' & `mean_rev2' \\" _n 
							"Observations & `N_first_pr' & `N_first' & `N_rating2' & `N_rev2' \\" _n 
							"Number of insurers & `N2_first_pr' & `N2_first' & `N2_rating2' & `N2_rev2' \\ \bottomrule" _n 
							"\end{tabular*}"
	 ;
	# delimit cr
	file close myfile

	
* Close log file
cap log close
