********************************************************************************
*************************** SOEP & GKV REGRESSIONS *****************************
********************************************************************************

/* 	OBJECTIVES
	- Run LPM switching regressions for various control variable specifications
	- Contemporaneous and forward effect
	- With and without IV
	- Explore heterogeneity of effect

	HISTORY
	- An old version conducted probit regressions (_superseded/ 220731)
	
	OUTLINE
	0) 	Preliminaries 
	1) 	Data
	2) 	Define controls
	3) 	Period 2: 2015-2018
		3.1) Contemporaneous 
		3.2) Forward t+1
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
log using "$logs_analysis/`date'_analysis_soep_gkv_regressions_addon15.log", text replace	


* 1) Data
* ---------------------------------------------------------------------------- *

* Load data 
use "$data_final/soep_gkv_match_cleaned.dta", clear
	 	
* 2) Define controls --------------------------------------------------------- *

	/* Potential control variables
	
		Individual level:
			- baseline: 
				- age
				- gender
				- income_gross
				- degree
			- extensions:
				- married (based on marital_status)
				- nace, isco08
				- companysize
			- health variables:
				- health_view
				- health_satisfaction
				- health_health_worried
				- hospital_stay
				- active_sport
				- doctor_visits
				
		Provider level:
			- Addon premium:
				Contemporary effect
				- addon_prior
				- addon_change_prior
				- addon_diff_avg_prior
				- addon_diff_predicted_prior
				Forward t+1 effect
				- addon_l
				- addon_change_l
				- addon_diff_avg_l
				- addon_diff_predicted_l
			- Type
			- rating (relative)
			- members_ln (size)
			- Rechnungslegung:
				- expenditure_admin_pc_ln_prior
				- capital_reserves_pc_ln_prior
				- revenue_fund_pc_ln
			
		Year fixed effects	
	
		Switch level:
			- addon_diff_prior (= addon - addon_prior)
	*/		
	

* Define control variables

	* individual-level
	global baseline age gender tertiary income_gross_ln health_satisfaction // i.hospital_stay i.reported_sick
	global extension i.isco08 // i.married  i.companysize

	* provider-level
	global provider_baseline rating_relative_prior_00
	global provider_extension insured_initial  

* Adjust variables for coefficient display 

	* Rating 
	gen rating_relative_prior_00 	= rating_relative_prior
	gen rating_relative_00 			= rating_relative
		
		
* 3) Period 2: 2015-2018 ----------------------------------------------------- *

	* Clear estimates
	eststo clear

	* 3.1) Contemporaneous 
	* ........................................................................ *

	* Rename variables for easier esttab output
	ren addon_prior 				aop
	ren addon_change_prior 			aocp
	ren addon_diff_avg_prior 		adap
	ren addon_diff_predicted_prior 	adpp
		
	* Regression loop 
	foreach rhs in aop aocp {

		* Set instrument
		if "`rhs'"=="aop"		local Z_instr = "expenditure_admin_pc_prior"
		else if "`rhs'"=="aocp"	local Z_instr = "admin_pc_change_prior"

		* No controls OLS
		reghdfe hi_switch `rhs' if year>2014 & year<2019, noabsorb cluster(provider_l)

			* Store coefficients
			local b_`rhs'_`rhs'_1	= _b[`rhs']
			local se_`rhs'_`rhs'_1 	= _se[`rhs']

			* Degrees of freedom 
			local df_`rhs'_1 = e(df_r)

			* Number of observations 
			local N_`rhs'_1: di %10.0fc e(N)

			* Number of insurers
			local Ins_`rhs'_1: di %10.0fc e(N_clust)

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean_`rhs'_1: di %10.3fc `r(mean)'

		* Full controls OLS
		reghdfe hi_switch `rhs' $baseline rating_relative_prior_00 if year>2014 & year<2019, absorb(year type_prior) cluster(provider_l)	

			* Store coefficients
			local b_`rhs'_`rhs'_2		= _b[`rhs']
			local se_`rhs'_`rhs'_2 		= _se[`rhs']

			local b_age_`rhs'_2			= _b[age]
			local se_age_`rhs'_2		= _se[age]

			local b_female_`rhs'_2 		= _b[gender]
			local se_female_`rhs'_2 	= _se[gender]

			local b_tertiary_`rhs'_2 	= _b[tertiary]
			local se_tertiary_`rhs'_2 	= _se[tertiary]

			local b_earnings_`rhs'_2 	= _b[income_gross_ln]
			local se_earnings_`rhs'_2	= _se[income_gross_ln] 

			local b_health_`rhs'_2		= _b[health_satisfaction]
			local se_health_`rhs'_2 	= _se[health_satisfaction]

			local b_rating_`rhs'_2  	= _b[rating_relative_prior_00]
			local se_rating_`rhs'_2  	= _se[rating_relative_prior_00] 

			* Degrees of freedom 
			local df_`rhs'_2 = e(df_r)

			* Number of observations 
			local N_`rhs'_2: di %10.0fc e(N)

			* Number of insurers
			local Ins_`rhs'_2: di %10.0fc e(N_clust)

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean_`rhs'_2: di %10.3fc `r(mean)'


		* Full controls IV
		ivregress 2sls hi_switch (`rhs' = `Z_instr' /*capital_reserves_pc_prior*/) $baseline rating_relative_prior_00 i.year i.type_prior if year>2014 & year<2019, cluster(provider_l)

			* Store coefficients
			local b_`rhs'_`rhs'_3		= _b[`rhs']
			local se_`rhs'_`rhs'_3 		= _se[`rhs']

			local b_age_`rhs'_3			= _b[age]
			local se_age_`rhs'_3		= _se[age]

			local b_female_`rhs'_3 		= _b[gender]
			local se_female_`rhs'_3 	= _se[gender]

			local b_tertiary_`rhs'_3 	= _b[tertiary]
			local se_tertiary_`rhs'_3 	= _se[tertiary]

			local b_earnings_`rhs'_3 	= _b[income_gross_ln]
			local se_earnings_`rhs'_3	= _se[income_gross_ln] 

			local b_health_`rhs'_3		= _b[health_satisfaction]
			local se_health_`rhs'_3 	= _se[health_satisfaction]

			local b_rating_`rhs'_3  	= _b[rating_relative_prior_00]
			local se_rating_`rhs'_3  	= _se[rating_relative_prior_00] 

			* Degrees of freedom 
			local df_`rhs'_3 = e(N) - e(df_m)

			* Number of observations 
			local N_`rhs'_3: di %10.0fc e(N)

			* Number of insurers
			local Ins_`rhs'_3: di %10.0fc e(N_clust)

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean_`rhs'_3: di %10.3fc `r(mean)'

	}

	* Format table entrants
	foreach rhs in aop aocp {
	foreach var in `rhs' age female tertiary earnings health rating {

		* Define controls for which columns 
		if 	"`var'"=="`rhs'"	local J = 1
		else  					local J = 2

		* Initiate tex_row local
		if "`rhs'"=="aop" {
			local row_b_`var'  = ""
			local row_se_`var' = ""
		}

		* For each relevant column
		forvalues j = `J'/3 {

			* p-value
			local p = 2 * ttail(`df_`rhs'_`j'', abs(`b_`var'_`rhs'_`j''/`se_`var'_`rhs'_`j''))

			* Format with stars
			local st = cond(`p'<.01,"***",cond(`p'<.05,"**",cond(`p'<.1,"*","")))

			* Format coefficient
			if `b_`var'_`rhs'_`j''==0  		local b_`var'_`rhs'_`j' 	= trim("`: di %10.3fc `b_`var'_`rhs'_`j'''")
			else if `b_`var'_`rhs'_`j''<1 	local b_`var'_`rhs'_`j' 	= trim("`: di %10.3fc `b_`var'_`rhs'_`j'''")
			else if `b_`var'_`rhs'_`j''<10 	local b_`var'_`rhs'_`j' 	= trim("`: di %10.3fc `b_`var'_`rhs'_`j'''")
			else  							local b_`var'_`rhs'_`j' 	= trim("`: di %10.2fc `b_`var'_`rhs'_`j'''")

			local b_`var'_`rhs'_`j' = "$`b_`var'_`rhs'_`j''^{`st'}$"

			* Format standard errors
			if `se_`var'_`rhs'_`j''==0 		local se_`var'_`rhs'_`j' = trim("`: di %10.3fc `se_`var'_`rhs'_`j'' '") 
			else if `se_`var'_`rhs'_`j''<1 	local se_`var'_`rhs'_`j' = trim("`: di %10.3fc `se_`var'_`rhs'_`j'' '") 
			else if `se_`var'_`rhs'_`j''<10 local se_`var'_`rhs'_`j' = trim("`: di %10.3fc `se_`var'_`rhs'_`j'' '") 
			else 							local se_`var'_`rhs'_`j' = trim("`: di %10.2fc `se_`var'_`rhs'_`j'' '") 

			local se_`var'_`rhs'_`j' = "(`se_`var'_`rhs'_`j'')"

			* Display coefficient and standard error 
			di "`var':  `b_`var'_`rhs'_`j''  `se_`var'_`rhs'_`j''  `p'"

		}  // close loop J 

		local row_b_`var' = "`row_b_`var'' & `b_`var'_`rhs'_1' & `b_`var'_`rhs'_2' & `b_`var'_`rhs'_3'"
		local row_se_`var' = "`row_se_`var'' & `se_`var'_`rhs'_1' & `se_`var'_`rhs'_2' & `se_`var'_`rhs'_3'"

	} // close loop var
	} // close loop rhs 	


	* Write output table
	local date $date
	cap file close myfile
	file open myfile using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_LPM_addon15_contemporaneous.tex", write replace

	// aop aocp age female tertiary earnings health rating

	# delimit ; 
	file write myfile 
		"\begin{tabular}{l ccc  ccc}" _n 
		"\toprule" _n 
		" & \multicolumn{3}{|c}{Add-On (Levels)} & \multicolumn{3}{|c}{$\Delta$ Add-On (Changes)} \\" _n 
		"& \multicolumn{1}{|c}{(1)} & (2) & (3) & \multicolumn{1}{|c}{(4)} & (5) & (6) \\" _n 
		"\footnotesize{Outcome: $\mathbf{1}\left( Switch = 1\right)$} & \multicolumn{1}{|c}{No controls} & Controls & Controls IV & \multicolumn{1}{|c}{No controls} & Controls & Controls IV \\ \midrule" _n
		"Add-on (pp.) 			 `row_b_aop' &&& 	\\" _n
		"						 `row_se_aop' &&&	\\ " _n
		"$\Delta$ Add-on (pp.)	 &&& `row_b_aocp'	\\" _n 
		"						 &&& `row_se_aocp'	\\" _n 
		"Age 					 `row_b_age'		\\" _n 
		"						 `row_se_age'		\\" _n 
		"Female 				 `row_b_female'		\\" _n 
		"						 `row_se_female'	\\" _n 
		"Tertiary degree		 `row_b_tertiary'	\\" _n
		"						 `row_se_tertiary' \\" _n 
		" Earnings (log)		 `row_b_earnings'	\\" _n 
		"						 `row_se_earnings' \\" _n 
		"Health satisfaction 	 `row_b_health' 	\\" _n 
		"						 `row_se_health'	\\" _n
		"Rating 				 `row_b_rating'	\\" _n 
		"						 `row_se_rating'	\\ \midrule" _n 
		"Provider-type FE 		& No & Yes & Yes & No & Yes & Yes \\" _n
		"Year FE 				& No & Yes & Yes & No & Yes & Yes \\ \midrule" _n
		"Mean outcome 			& `mean_aop_1' & `mean_aop_2' & `mean_aop_3' & `mean_aocp_1' & `mean_aocp_2' & `mean_aocp_3' \\" _n 
		"Observations 			& `N_aop_1' & `N_aop_2' & `N_aop_3' & `N_aocp_1' & `N_aocp_2' & `N_aocp_3' \\"  _n 
		"Number of insurers 	& `Ins_aop_1' & `Ins_aop_2' & `Ins_aop_3' & `Ins_aocp_1' & `Ins_aocp_2' & `Ins_aocp_3' \\ \bottomrule" _n 
		"\end{tabular}"
	;
	# delimit cr
	file close myfile 	
		
	* Undo variable name changes
	ren aop addon_prior 
	ren aocp addon_change_prior 
	ren adap addon_diff_avg_prior 
	ren adpp addon_diff_predicted_prior 
	
	
	* 3.2) Forward t+1 
	* ........................................................................ *

	* Rename variables for easier esttab output
	ren addon 			ao
	ren addon_change 	aoc
		
	* Regression loop 
	foreach rhs in ao aoc {

		* Set instrument
		if "`rhs'"=="aop"		local Z_instr = "expenditure_admin_pc"
		else if "`rhs'"=="aocp"	local Z_instr = "admin_pc_change"

		* No controls OLS
		reghdfe hi_switch_lead `rhs' if year>2014 & year<2019, noabsorb cluster(provider)

			* Store coefficients
			local b_`rhs'_`rhs'_1	= _b[`rhs']
			local se_`rhs'_`rhs'_1 	= _se[`rhs']

			* Degrees of freedom 
			local df_`rhs'_1 = e(df_r)

			* Number of observations 
			local N_`rhs'_1: di %10.0fc e(N)

			* Number of insurers
			local Ins_`rhs'_1: di %10.0fc e(N_clust)

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean_`rhs'_1: di %10.3fc `r(mean)'

		* Full controls OLS
		reghdfe hi_switch_lead `rhs' $baseline rating_relative_00 if year>2014 & year<2019, absorb(year type) cluster(provider)	

			* Store coefficients
			local b_`rhs'_`rhs'_2		= _b[`rhs']
			local se_`rhs'_`rhs'_2 		= _se[`rhs']

			local b_age_`rhs'_2			= _b[age]
			local se_age_`rhs'_2		= _se[age]

			local b_female_`rhs'_2 		= _b[gender]
			local se_female_`rhs'_2 	= _se[gender]

			local b_tertiary_`rhs'_2 	= _b[tertiary]
			local se_tertiary_`rhs'_2 	= _se[tertiary]

			local b_earnings_`rhs'_2 	= _b[income_gross_ln]
			local se_earnings_`rhs'_2	= _se[income_gross_ln] 

			local b_health_`rhs'_2		= _b[health_satisfaction]
			local se_health_`rhs'_2 	= _se[health_satisfaction]

			local b_rating_`rhs'_2  	= _b[rating_relative_00]
			local se_rating_`rhs'_2  	= _se[rating_relative_00] 

			* Degrees of freedom 
			local df_`rhs'_2 = e(df_r)

			* Number of observations 
			local N_`rhs'_2: di %10.0fc e(N)

			* Number of insurers
			local Ins_`rhs'_2: di %10.0fc e(N_clust)

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean_`rhs'_2: di %10.3fc `r(mean)'

		* Full controls IV
		ivregress 2sls hi_switch_lead (`rhs' = `Z_instr' /* capital_reserves_pc */) $baseline rating_relative_00 i.year i.type if year>2014 & year<2019, cluster(provider)

			* Store coefficients
			local b_`rhs'_`rhs'_3		= _b[`rhs']
			local se_`rhs'_`rhs'_3 		= _se[`rhs']

			local b_age_`rhs'_3			= _b[age]
			local se_age_`rhs'_3		= _se[age]

			local b_female_`rhs'_3 		= _b[gender]
			local se_female_`rhs'_3 	= _se[gender]

			local b_tertiary_`rhs'_3 	= _b[tertiary]
			local se_tertiary_`rhs'_3 	= _se[tertiary]

			local b_earnings_`rhs'_3 	= _b[income_gross_ln]
			local se_earnings_`rhs'_3	= _se[income_gross_ln] 

			local b_health_`rhs'_3		= _b[health_satisfaction]
			local se_health_`rhs'_3 	= _se[health_satisfaction]

			local b_rating_`rhs'_3  	= _b[rating_relative_00]
			local se_rating_`rhs'_3  	= _se[rating_relative_00] 

			* Degrees of freedom 
			local df_`rhs'_3 = e(N) - e(df_m)

			* Number of observations 
			local N_`rhs'_3: di %10.0fc e(N)

			* Number of insurers
			local Ins_`rhs'_3: di %10.0fc e(N_clust)

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean_`rhs'_3: di %10.3fc `r(mean)'

	}

	* Format table entrants
	foreach rhs in ao aoc {
	foreach var in `rhs' age female tertiary earnings health rating {

		* Define controls for which columns 
		if 	"`var'"=="`rhs'"	local J = 1
		else  					local J = 2

		* Initiate tex_row local
		if "`rhs'"=="ao" {
			local row_b_`var'  = ""
			local row_se_`var' = ""
		}

		* For each relevant column
		forvalues j = `J'/3 {

			* p-value
			local p = 2 * ttail(`df_`rhs'_`j'', abs(`b_`var'_`rhs'_`j''/`se_`var'_`rhs'_`j''))

			* Format with stars
			local st = cond(`p'<.01,"***",cond(`p'<.05,"**",cond(`p'<.1,"*","")))

			* Format coefficient
			if `b_`var'_`rhs'_`j''==0  		local b_`var'_`rhs'_`j' 	= trim("`: di %10.3fc `b_`var'_`rhs'_`j'''")
			else if `b_`var'_`rhs'_`j''<1 	local b_`var'_`rhs'_`j' 	= trim("`: di %10.3fc `b_`var'_`rhs'_`j'''")
			else if `b_`var'_`rhs'_`j''<10 	local b_`var'_`rhs'_`j' 	= trim("`: di %10.3fc `b_`var'_`rhs'_`j'''")
			else  							local b_`var'_`rhs'_`j' 	= trim("`: di %10.2fc `b_`var'_`rhs'_`j'''")

			local b_`var'_`rhs'_`j' = "$`b_`var'_`rhs'_`j''^{`st'}$"

			* Format standard errors
			if `se_`var'_`rhs'_`j''==0 		local se_`var'_`rhs'_`j' = trim("`: di %10.3fc `se_`var'_`rhs'_`j'' '") 
			else if `se_`var'_`rhs'_`j''<1 	local se_`var'_`rhs'_`j' = trim("`: di %10.3fc `se_`var'_`rhs'_`j'' '") 
			else if `se_`var'_`rhs'_`j''<10 local se_`var'_`rhs'_`j' = trim("`: di %10.3fc `se_`var'_`rhs'_`j'' '") 
			else 							local se_`var'_`rhs'_`j' = trim("`: di %10.2fc `se_`var'_`rhs'_`j'' '") 

			local se_`var'_`rhs'_`j' = "(`se_`var'_`rhs'_`j'')"

			* Display coefficient and standard error 
			di "`var':  `b_`var'_`rhs'_`j''  `se_`var'_`rhs'_`j''  `p'"

		}  // close loop J 

		local row_b_`var' = "`row_b_`var'' & `b_`var'_`rhs'_1' & `b_`var'_`rhs'_2' & `b_`var'_`rhs'_3'"
		local row_se_`var' = "`row_se_`var'' & `se_`var'_`rhs'_1' & `se_`var'_`rhs'_2' & `se_`var'_`rhs'_3'"

	} // close loop var
	} // close loop rhs 	


	* Write output table
	local date $date
	cap file close myfile
	file open myfile using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_LPM_addon15_forward.tex", write replace

	// ao aoc age female tertiary earnings health rating

	# delimit ; 
	file write myfile 
		"\begin{tabular}{l ccc  ccc}" _n 
		"\toprule" _n 
		" & \multicolumn{3}{|c}{Add-On (Levels)} & \multicolumn{3}{|c}{$\Delta$ Add-On (Changes)} \\" _n 
		"& \multicolumn{1}{|c}{(1)} & (2) & (3) & \multicolumn{1}{|c}{(4)} & (5) & (6) \\" _n 
		"\footnotesize{Outcome: $\mathbf{1}\left( Switch = 1\right)$} & \multicolumn{1}{|c}{No controls} & Controls & Controls IV & \multicolumn{1}{|c}{No controls} & Controls & Controls IV \\ \midrule" _n
		"Add-On (pp.) 			 `row_b_ao' &&& 	\\" _n
		"						 `row_se_ao' &&&	\\ " _n
		"$\Delta$ Add-on (pp.)	 &&& `row_b_aoc'	\\" _n 
		"						 &&& `row_se_aoc'	\\" _n 
		"Age 					 `row_b_age'		\\" _n 
		"						 `row_se_age'		\\" _n 
		"Female 				 `row_b_female'		\\" _n 
		"						 `row_se_female'	\\" _n 
		"Tertiary degree		 `row_b_tertiary'	\\" _n
		"						 `row_se_tertiary' \\" _n 
		" Earnings (log)		 `row_b_earnings'	\\" _n 
		"						 `row_se_earnings' \\" _n 
		"Health satisfaction 	 `row_b_health' 	\\" _n 
		"						 `row_se_health'	\\" _n
		"Rating 				 `row_b_rating'	\\" _n 
		"						 `row_se_rating'	\\ \midrule" _n 
		"Provider-type FE 		& No & Yes & Yes & No & Yes & Yes \\" _n
		"Year FE 				& No & Yes & Yes & No & Yes & Yes \\ \midrule" _n
		"Mean outcome 			& `mean_ao_1' & `mean_ao_2' & `mean_ao_3' & `mean_aoc_1' & `mean_aoc_2' & `mean_aoc_3' \\" _n 
		"Observations 			& `N_ao_1' & `N_ao_2' & `N_ao_3' & `N_aoc_1' & `N_aoc_2' & `N_aoc_3' \\"  _n 
		"Number of insurers 	& `Ins_aop_1' & `Ins_aop_2' & `Ins_aop_3' & `Ins_aocp_1' & `Ins_aocp_2' & `Ins_aocp_3' \\ \bottomrule" _n 
		"\end{tabular}"
	;
	# delimit cr
	file close myfile 	

	* Undo variable name changes
	ren ao 	addon
	ren aoc addon_change 



* Close log file 
cap log close 

* SCRIPT END
