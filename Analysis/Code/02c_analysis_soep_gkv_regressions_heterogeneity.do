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
	3) 	Heterogeneity Analysis 	
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
log using "$logs_analysis/`date'_analysis_soep_gkv_regressions_heterogeneity.log", text replace	


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
	global baseline age female tertiary earnings health // i.hospital_stay i.reported_sick
	global extension i.isco08 // i.married  i.companysize

	* provider-level
	global provider_baseline rating_r
	global provider_extension insured_initial  

* Adjust variables for coefficient display 

	* Rating 
	gen rating_relative_prior_00 	= rating_relative_prior/100
	gen rating_relative_00 			= rating_relative/100

* 3) Heterogeneity Analysis 													
* ---------------------------------------------------------------------------- *
	
	* Period 2: 2015-2018
	* ........................................................................ *

	* Rename variables for easier loop
	ren health_satisfaction 		health 
	ren income_gross_ln			 	earnings
	ren rating_relative_prior_00 	rating_r
	drop addon 
	ren addon_prior 				addon  

	* Generate additional variables
	gen female=(gender==2) if gender!=.

	* Initiate locals
	foreach suffix in ols iv {
		local b_addon_`suffix' 	= "Add-on (pp.)"
		local se_addon_`suffix' = ""
		local b_cov_`suffix' 	= "Characteristic"
		local se_cov_`suffix' 	= ""
		local b_int_`suffix' 	= "Interaction"
		local se_int_`suffix' 	= ""

		local Controls_`suffix' = "Controls"
		local Type_`suffix' 	= "Provider-type FE"
		local Year_`suffix' 	= "Year-FE"

		local Mean_`suffix' 	= "Mean outcome"
		local N_`suffix' 		= "Observations"
		local Ins_`suffix'		= "Number of insurers"
	}

	* Regression loop
	foreach X in age female tertiary earnings health {

		* Create interaction term 
		cap drop var_int 
		gen var_int = addon*`X'

		* OLS regression 
		reghdfe hi_switch addon var_int $baseline rating_r if year>2014 & year<2019, absorb(year type_prior) cluster(provider_l) 
	
			* Store coefficients
			* ................................................................ *
			local b_addon 	= _b[addon] 
			local se_addon 	= _se[addon] 

			local b_cov 	= _b[`X']
			local se_cov 	= _se[`X']

			local b_int 	= _b[var_int]
			local se_int 	= _se[var_int]

			* Degrees of freedom
			local df = e(df_r)

			* Number of observations 
			local N_obs: di %10.0fc e(N)
			local N_ols = "`N_ols' & `N_obs'"

			* Number of insurers
			local N_ins: di %10.0fc e(N_clust)
			local Ins_ols = "`Ins_ols' & `N_ins'"

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean: di %10.3fc `r(mean)'
			local Mean_ols = "`Mean_ols' & `mean'"

			* Additional variables
			local Controls_ols 	= "`Controls_ols' & Yes"
			local Type_ols 		= "`Type_ols' & Yes"
			local Year_ols		= "`Year_ols' & Yes"

			* Format coefficients
			* ................................................................ *
			foreach Z in addon cov int {

				* p-value
				local p = 2 * ttail(`df', abs(`b_`Z''/`se_`Z''))

				* Format with stars
				local st = cond(`p'<.001,"***",cond(`p'<.01,"**",cond(`p'<.05,"*","")))

				* Format coefficient
				if `b_`Z''==0  		local b_`Z' = trim("`: di %10.3fc `b_`Z'''")
				else if `b_`Z''<1 	local b_`Z' = trim("`: di %10.3fc `b_`Z'''")
				else if `b_`Z''<10 	local b_`Z' = trim("`: di %10.3fc `b_`Z'''")
				else  				local b_`Z' = trim("`: di %10.2fc `b_`Z'''")

				local b_`Z' 	= "$`b_`Z''^{`st'}$"
				local b_`Z'_ols = "`b_`Z'_ols' & `b_`Z''"

				* Format standard errors
				if `se_`Z''==0 		local se_`Z' = trim("`: di %10.3fc `se_`Z'' '") 
				else if `se_`Z''<1 	local se_`Z' = trim("`: di %10.3fc `se_`Z'' '") 
				else if `se_`Z''<10 local se_`Z' = trim("`: di %10.3fc `se_`Z'' '") 
				else 				local se_`Z' = trim("`: di %10.2fc `se_`Z'' '") 

				local se_`Z' 	= "(`se_`Z'')"
				local se_`Z'_ols = "`se_`Z'_ols' & `se_`Z''"
			}			

		* IV 
		
			* Create interactions for X and Z
			cap drop var_int 
			gen var_int = addon*`X'
			cap drop Z_int 
			gen Z_int = expenditure_admin_pc_prior*`X'

			* IV regression
			ivregress 2sls hi_switch (addon var_int = expenditure_admin_pc_prior Z_int) $baseline rating_r i.year i.type_prior if year>2014 & year<2019, cluster(provider_l)

			* Store coefficients
			* ................................................................ *
			local b_addon 	= _b[addon] 
			local se_addon 	= _se[addon] 

			local b_cov 	= _b[`X']
			local se_cov 	= _se[`X']

			local b_int 	= _b[var_int]
			local se_int 	= _se[var_int]

			* Degrees of freedom
			local df = e(N) - e(df_m)

			* Number of observations 
			local N_obs: di %10.0fc e(N)
			local N_iv = "`N_iv' & `N_obs'"

			* Number of insurers
			local N_ins: di %10.0fc e(N_clust)
			local Ins_iv = "`Ins_iv' & `N_ins'"

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean: di %10.3fc `r(mean)'
			local Mean_iv = "`Mean_iv' & `mean'"

			* Additional variables
			local Controls_iv 	= "`Controls_iv' & Yes"
			local Type_iv 		= "`Type_iv' & Yes"
			local Year_iv		= "`Year_iv' & Yes"

			* Format coefficients
			* ................................................................ *
			foreach Z in addon cov int {

				* p-value
				local p = 2 * ttail(`df', abs(`b_`Z''/`se_`Z''))

				* Format with stars
				local st = cond(`p'<.001,"***",cond(`p'<.01,"**",cond(`p'<.05,"*","")))

				* Format coefficient
				if `b_`Z''==0  		local b_`Z' = trim("`: di %10.3fc `b_`Z'''")
				else if `b_`Z''<1 	local b_`Z' = trim("`: di %10.3fc `b_`Z'''")
				else if `b_`Z''<10 	local b_`Z' = trim("`: di %10.3fc `b_`Z'''")
				else  				local b_`Z' = trim("`: di %10.2fc `b_`Z'''")

				local b_`Z' 	= "$`b_`Z''^{`st'}$"
				local b_`Z'_iv = "`b_`Z'_iv' & `b_`Z''"

				* Format standard errors
				if `se_`Z''==0 		local se_`Z' = trim("`: di %10.3fc `se_`Z'' '") 
				else if `se_`Z''<1 	local se_`Z' = trim("`: di %10.3fc `se_`Z'' '") 
				else if `se_`Z''<10 local se_`Z' = trim("`: di %10.3fc `se_`Z'' '") 
				else 				local se_`Z' = trim("`: di %10.2fc `se_`Z'' '") 

				local se_`Z' 	= "(`se_`Z'')"
				local se_`Z'_iv = "`se_`Z'_iv' & `se_`Z''"
			}	

	} // close loop `X'

	
	* Write output table
	local date $date
	cap file close myfile
	file open myfile using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_LPM_addon15_heterogeneity_contemporaneous_horizontal.tex", write replace

	// Age Education Health Gender Earnings

	# delimit ; 
	file write myfile 
		"\begin{tabular*}{1\hsize}{@{\hskip\tabcolsep\extracolsep\fill}l*{5}{c}}" _n
		"\toprule" _n
		"& \multicolumn{5}{c}{Individual Characteristics} \\ \cmidrule{2-6}" _n 
		"& (1) & (2) & (3) & (4) & (5) \\" _n 
		"& Age & Female & Tertiary & Earnings & Health  \\ " _n
		" \footnotesize{Outcome: $\mathbf{1}\left( Switch = 1\right)$} 	& & & degree & (log) & satisfaction \\ \midrule" _n
		"\multicolumn{6}{l}{\textit{\textbf{Panel (a): Ordinary Least Squares}}} \\ [6pt] " _n
		" `b_addon_ols' 	\\" _n
		" `se_addon_ols'	\\ [3pt]" _n
		" `b_cov_ols'		\\" _n 
		" `se_cov_ols'		\\ [3pt]" _n 
		" `b_int_ols'		\\" _n 
		" `se_int_ols'		\\ [3pt] \midrule" _n 
		" `Controls_ols' 	\\ " _n
		" `Type_ols' 		\\" _n 
		" `Year_ols' 		\\ \midrule" _n
		" &&&&& \\ [-6pt]" _n  
		"\multicolumn{6}{l}{\textit{\textbf{Panel (b): Instrumental Variables}}} \\ [6pt]" _n
		" `b_addon_iv' 		\\" _n
		" `se_addon_iv'		\\ [3pt]" _n
		" `b_cov_iv'		\\" _n 
		" `se_cov_iv'		\\ [3pt]" _n 
		" `b_int_iv'		\\" _n 
		" `se_int_iv'		\\ [3pt] \midrule" _n 
		" `Controls_iv' 	\\" _n
		" `Type_iv'			\\" _n 
		" `Year_iv' 		\\ [3pt] \midrule" _n 
		" `Mean_iv' 		\\" _n
		" `N_iv'			\\ " _n 
		" `Ins_iv'			\\ \bottomrule" _n 
		"\end{tabular*}"
	;
	# delimit cr
	file close myfile 	
		
* Close log file 
cap log close 

* SCRIPT END
