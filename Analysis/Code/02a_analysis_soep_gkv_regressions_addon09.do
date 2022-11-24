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
	3) 	Period 1: 2009-2014
		3.1) Contemporaneous effect
		3.2) Forward t+1 effect
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
log using "$logs_analysis/`date'_analysis_soep_gkv_regressions_addon09.log", text replace	


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
	gen rating_relative_prior_00 	= rating_relative_prior/100
	gen rating_relative_00 			= rating_relative/100
	
	
* 3) Period 1: 2009-2014 ----------------------------------------------------- *

	* 3.1) Contemporaneous effect
	* ........................................................................ *
	
	* No controls
	reghdfe hi_switch addon09_dummy_prior if year>2008 & year<=2014, noabsorb cluster(provider_l)

		* Store coefficients
		local b_addon_1 	= _b[addon09_dummy_prior]
		local se_addon_1 	= _se[addon09_dummy_prior]

		* Degrees of freedom 
		local df_1 = e(df_r)

		* Number of observations 
		local N1: di %10.0fc e(N)

		* Number of insurers
		local N1_ins: di %10.0fc e(N_clust)

		* Mean dependent variable 
		sum hi_switch if e(sample)==1
		local mean1: di %10.3fc `r(mean)'

	* + Individual controls
	reghdfe hi_switch addon09_dummy_prior $baseline if year>2008 & year<=2014, absorb(year) cluster(provider_l)

		* Store coefficients
		local b_addon_2 		= _b[addon09_dummy_prior]
		local se_addon_2 		= _se[addon09_dummy_prior]

		local b_age_2 			= _b[age]
		local se_age_2 			= _se[age]

		local b_female_2 		= _b[gender]
		local se_female_2 		= _se[gender]

		local b_tertiary_2 		= _b[tertiary]
		local se_tertiary_2 	= _se[tertiary]

		local b_earnings_2 		= _b[income_gross_ln]
		local se_earnings_2 	= _se[income_gross_ln]

		local b_health_2 		= _b[health_satisfaction]
		local se_health_2 		= _se[health_satisfaction]

		* Degrees of freedom 
		local df_2 		= e(df_r)

		* Number of observations 
		local N2: di %10.0fc e(N)

		* Number of insurers
		local N2_ins: di %10.0fc e(N_clust)

		* Mean dependent variable 
		sum hi_switch if e(sample)==1
		local mean2: di %10.3fc `r(mean)'

	* Rating sample

		* Identify the rating sample
		reghdfe hi_switch addon09_dummy_prior $baseline $provider_baseline if year>2008 & year<=2014, absorb(year type_prior) cluster(provider_l)
		cap drop temp_sample
		gen temp_sample = (e(sample)==1)

		* Run individual controls version with rating sample
		reghdfe hi_switch addon09_dummy_prior $baseline if year>2008 & year<=2014 & temp_sample==1, absorb(year) cluster(provider_l)

			* Store coefficients
			local b_addon_3 		= _b[addon09_dummy_prior]
			local se_addon_3 		= _se[addon09_dummy_prior]

			local b_age_3 			= _b[age]
			local se_age_3 			= _se[age]

			local b_female_3 		= _b[gender]
			local se_female_3 		= _se[gender]

			local b_tertiary_3 		= _b[tertiary]
			local se_tertiary_3 	= _se[tertiary]

			local b_earnings_3 		= _b[income_gross_ln]
			local se_earnings_3 	= _se[income_gross_ln]

			local b_health_3 		= _b[health_satisfaction]
			local se_health_3 		= _se[health_satisfaction]

			* Degrees of freedom 
			local df_3 		= e(df_r)

			* Number of observations 
			local N3: di %10.0fc e(N)

			* Number of insurers
			local N3_ins: di %10.0fc e(N_clust)

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean3: di %10.3fc `r(mean)'	
		
	* + Provider controls
	reghdfe hi_switch addon09_dummy_prior $baseline $provider_baseline if year>2008 & year<=2014, absorb(year type_prior) cluster(provider_l)

		* Store coefficients
		local b_addon_4 		= _b[addon09_dummy_prior]
		local se_addon_4 		= _se[addon09_dummy_prior]

		local b_age_4 			= _b[age]
		local se_age_4 			= _se[age]

		local b_female_4 		= _b[gender]
		local se_female_4 		= _se[gender]

		local b_tertiary_4 		= _b[tertiary]
		local se_tertiary_4 	= _se[tertiary]

		local b_earnings_4 		= _b[income_gross_ln]
		local se_earnings_4 	= _se[income_gross_ln]

		local b_health_4 		= _b[health_satisfaction]
		local se_health_4 		= _se[health_satisfaction]

		local b_rating_4 		= _b[rating_relative_prior_00]
		local se_rating_4		= _se[rating_relative_prior_00]

		* Degrees of freedom 
		local df_4 	= e(df_r)

		* Number of observations 
		local N4: di %10.0fc e(N)

		* Number of insurers
		local N4_ins: di %10.0fc e(N_clust)

		* Mean dependent variable 
		sum hi_switch if e(sample)==1
		local mean4: di %10.3fc `r(mean)'

	* + provider fixed effects
	reghdfe hi_switch addon09_dummy_prior $baseline $provider_baseline if year>2008 & year<=2014, absorb(year provider_l) cluster(provider_l)

		* Store coefficients
		local b_addon_5 	= _b[addon09_dummy_prior]
		local se_addon_5 	= _se[addon09_dummy_prior]

		local b_age_5 		= _b[age]
		local se_age_5 		= _se[age]

		local b_female_5 	= _b[gender]
		local se_female_5 	= _se[gender]

		local b_tertiary_5 	= _b[tertiary]
		local se_tertiary_5 = _se[tertiary]

		local b_earnings_5 	= _b[income_gross_ln]
		local se_earnings_5 = _se[income_gross_ln]

		local b_health_5 	= _b[health_satisfaction]
		local se_health_5 	= _se[health_satisfaction]

		local b_rating_5 	= _b[rating_relative_prior_00]
		local se_rating_5	= _se[rating_relative_prior_00]

		* Degrees of freedom 
		local df_5 	= e(df_r)

		* Number of observations 
		local N5: di %10.0fc e(N)

		* Number of insurers
		local N5_ins: di %10.0fc e(N_clust)

		* Mean dependent variable 
		sum hi_switch if e(sample)==1
		local mean5: di %10.3fc `r(mean)'

	* Format table entrants
	foreach var in addon age female tertiary earnings health rating {

		if 		"`var'"=="addon" 	local J = 1
		else if "`var'"=="rating" 	local J = 4
		else 						local J = 2

		* For each relevant column 
		forvalues j = `J'/5 {

			* p-value
			local p = 2 * ttail(`df_`j'', abs(`b_`var'_`j''/`se_`var'_`j''))

			* Format with stars
			local st = cond(`p'<.001,"***",cond(`p'<.01,"**",cond(`p'<.05,"*","")))

			* Format coefficient
			if `b_`var'_`j''==0  		local b_`var'_`j' 	= trim("`: di %10.3fc `b_`var'_`j'''")
			else if `b_`var'_`j''<1 	local b_`var'_`j' 	= trim("`: di %10.3fc `b_`var'_`j'''")
			else if `b_`var'_`j''<10 	local b_`var'_`j' 	= trim("`: di %10.3fc `b_`var'_`j'''")
			else  						local b_`var'_`j' 	= trim("`: di %10.2fc `b_`var'_`j'''")

			local b_`var'_`j' = "$`b_`var'_`j''^{`st'}$"

			* Format standard errors
			if `se_`var'_`j''==0 		local se_`var'_`j' = trim("`: di %10.3fc `se_`var'_`j'' '") 
			else if `se_`var'_`j''<1 	local se_`var'_`j' = trim("`: di %10.3fc `se_`var'_`j'' '") 
			else if `se_`var'_`j''<10 	local se_`var'_`j' = trim("`: di %10.3fc `se_`var'_`j'' '") 
			else 						local se_`var'_`j' = trim("`: di %10.2fc `se_`var'_`j'' '") 

			local se_`var'_`j' = "(`se_`var'_`j'')"

			* Display coefficient and standard error 
			di "`var':  `b_`var'_`j''  `se_`var'_`j''  `p'"

		}  // close loop J 

		local row_b_`var' = " `b_`var'_1' & `b_`var'_2' & `b_`var'_3' & `b_`var'_4' & `b_`var'_5' "
		local row_se_`var' = " `se_`var'_1' & `se_`var'_2' & `se_`var'_3' & `se_`var'_4' & `se_`var'_5'"

	} // close loop var 

	* Write output table
	local date $date
	cap file close myfile
	file open myfile using "$tables/RegressionOutput/Individual/Addon09/`date'_Individual_LPM_addon09_contemporaneous.tex", write replace

	//addon age female tertiary earnings health rating

	# delimit ; 
	file write myfile 
		"\begin{tabular}{l ccccc}" _n 
		"\toprule" _n 
		"& (1) & (2) & (3) & (4) & (5) \\" _n 
		"\footnotesize{Outcome: $\mathbf{1}\left( Switch = 1\right)$} & No controls & Individual controls & Rating sample & Provider controls & Provider FE \\ \midrule" _n
		"Add-on (Dummy) 		& `row_b_addon' 	\\" _n
		"						& `row_se_addon'	\\ " _n
		"Age 					& `row_b_age'		\\" _n 
		"						& `row_se_age'		\\" _n 
		"Female 				& `row_b_female'	\\" _n 
		"						& `row_se_female'	\\" _n 
		"Tertiary degree		& `row_b_tertiary'	\\" _n
		"						& `row_se_tertiary' \\" _n 
		"Earnings (log)			& `row_b_earnings'	\\" _n 
		"						& `row_se_earnings' \\" _n 
		"Health satisfaction 	& `row_b_health' 	\\" _n 
		"						& `row_se_health'	\\" _n
		"Rating 				& `row_b_rating'	\\" _n 
		"						& `row_se_rating'	\\ \midrule" _n 
		"Provider-type FE 		& No & No & No & Yes & No \\" _n
		"Provider FE 			& No & No & No & No & Yes \\" _n 
		"Year FE 				& No & Yes & Yes & Yes & Yes \\ \midrule" _n
		"Mean outcome 			& `mean1' & `mean2' & `mean3' & `mean4' & `mean5'\\ " _n
		"Observations 			& `N1' & `N2' & `N3' & `N4' & `N5'\\ " _n 
		"Number of insurers   	& `N1_ins' & `N2_ins' & `N3_ins' & `N4_ins' & `N5_ins' \\ \bottomrule" _n 
		"\end{tabular}"
	;
	# delimit cr
	file close myfile 

 	
	* 3.2) Forward t+1 effect
	* ........................................................................ *

	* No controls
	reghdfe hi_switch_lead addon09_dummy if year>2008 & year<=2014, noabsorb cluster(provider)

		* Store coefficients
		local b_addon_1 	= _b[addon09_dummy]
		local se_addon_1 	= _se[addon09_dummy]

		* Degrees of freedom 
		local df_1 = e(df_r)

		* Number of observations 
		local N1: di %10.0fc e(N)

		* Number of insurers 
		local N1_ins: di %10.0fc e(N_clust)

		* Mean dependent variable 
		sum hi_switch if e(sample)==1
		local mean1: di %10.3fc `r(mean)'
	
	* + Individual controls
	reghdfe hi_switch_lead addon09_dummy $baseline if year>2008 & year<=2014, absorb(year) cluster(provider)

		* Store coefficients
		local b_addon_2 		= _b[addon09_dummy]
		local se_addon_2 		= _se[addon09_dummy]

		local b_age_2 			= _b[age]
		local se_age_2 			= _se[age]

		local b_female_2 		= _b[gender]
		local se_female_2 		= _se[gender]

		local b_tertiary_2 		= _b[tertiary]
		local se_tertiary_2 	= _se[tertiary]

		local b_earnings_2 		= _b[income_gross_ln]
		local se_earnings_2 	= _se[income_gross_ln]

		local b_health_2 		= _b[health_satisfaction]
		local se_health_2 		= _se[health_satisfaction]

		* Degrees of freedom 
		local df_2 		= e(df_r)

		* Number of observations 
		local N2: di %10.0fc e(N)

		* Number of insurers 
		local N2_ins: di %10.0fc e(N_clust)

		* Mean dependent variable 
		sum hi_switch if e(sample)==1
		local mean2: di %10.3fc `r(mean)'


	* Rating Sample 

		* Identify the sample
		reghdfe hi_switch_lead addon09_dummy $baseline rating_relative_00 if year>2008 & year<=2014, absorb(year type) cluster(provider)
		cap drop temp_sample 
		gen temp_sample = (e(sample)==1)

		* Individual controls version with rating sample 
		reghdfe hi_switch_lead addon09_dummy $baseline if year>2008 & year<=2014 & temp_sample==1, absorb(year) cluster(provider)

			* Store coefficients
			local b_addon_3 		= _b[addon09_dummy]
			local se_addon_3 		= _se[addon09_dummy]

			local b_age_3 			= _b[age]
			local se_age_3 			= _se[age]

			local b_female_3 		= _b[gender]
			local se_female_3 		= _se[gender]

			local b_tertiary_3 		= _b[tertiary]
			local se_tertiary_3 	= _se[tertiary]

			local b_earnings_3 		= _b[income_gross_ln]
			local se_earnings_3 	= _se[income_gross_ln]

			local b_health_3 		= _b[health_satisfaction]
			local se_health_3 		= _se[health_satisfaction]

			* Degrees of freedom 
			local df_3 		= e(df_r)

			* Number of observations 
			local N3: di %10.0fc e(N)

			* Number of insurers 
			local N3_ins: di %10.0fc e(N_clust)

			* Mean dependent variable 
			sum hi_switch if e(sample)==1
			local mean3: di %10.3fc `r(mean)'


	* + Provider controls
	reghdfe hi_switch_lead addon09_dummy $baseline rating_relative_00 if year>2008 & year<=2014, absorb(year type) cluster(provider)

		* Store coefficients
		local b_addon_4 		= _b[addon09_dummy]
		local se_addon_4 		= _se[addon09_dummy]

		local b_age_4 			= _b[age]
		local se_age_4 			= _se[age]

		local b_female_4 		= _b[gender]
		local se_female_4 		= _se[gender]

		local b_tertiary_4 		= _b[tertiary]
		local se_tertiary_4 	= _se[tertiary]

		local b_earnings_4 		= _b[income_gross_ln]
		local se_earnings_4 	= _se[income_gross_ln]

		local b_health_4 		= _b[health_satisfaction]
		local se_health_4 		= _se[health_satisfaction]

		local b_rating_4 		= _b[rating_relative_00]
		local se_rating_4		= _se[rating_relative_00]

		* Degrees of freedom 
		local df_4 	= e(df_r)

		* Number of observations 
		local N4: di %10.0fc e(N)

		* Number of insurers 
		local N4_ins: di %10.0fc e(N_clust)

		* Mean dependent variable 
		sum hi_switch if e(sample)==1
		local mean4: di %10.3fc `r(mean)'

	* + provider fixed effects
	reghdfe hi_switch_lead addon09_dummy $baseline rating_relative_00 if year>2008 & year<=2014, absorb(year provider) cluster(provider)

		* Store coefficients
		local b_addon_5 	= _b[addon09_dummy]
		local se_addon_5 	= _se[addon09_dummy]

		local b_age_5 		= _b[age]
		local se_age_5 		= _se[age]

		local b_female_5 	= _b[gender]
		local se_female_5 	= _se[gender]

		local b_tertiary_5 	= _b[tertiary]
		local se_tertiary_5 = _se[tertiary]

		local b_earnings_5 	= _b[income_gross_ln]
		local se_earnings_5 = _se[income_gross_ln]

		local b_health_5 	= _b[health_satisfaction]
		local se_health_5 	= _se[health_satisfaction]

		local b_rating_5 	= _b[rating_relative_00]
		local se_rating_5	= _se[rating_relative_00]

		* Degrees of freedom 
		local df_5 	= e(df_r)

		* Number of observations 
		local N5: di %10.0fc e(N)

		* Number of insurers 
		local N5_ins: di %10.0fc e(N_clust)

		* Mean dependent variable 
		sum hi_switch if e(sample)==1
		local mean5: di %10.3fc `r(mean)'

	* Format table entrants
	foreach var in addon age female tertiary earnings health rating {

		if 		"`var'"=="addon" 	local J = 1
		else if "`var'"=="rating" 	local J = 4
		else 						local J = 2

		* For each relevant column 
		forvalues j = `J'/5 {

			* p-value
			local p = 2 * ttail(`df_`j'', abs(`b_`var'_`j''/`se_`var'_`j''))

			* Format with stars
			local st = cond(`p'<.01,"***",cond(`p'<.05,"**",cond(`p'<.1,"*","")))

			* Format coefficient
			if `b_`var'_`j''==0  		local b_`var'_`j' 	= trim("`: di %10.3fc `b_`var'_`j'''")
			else if `b_`var'_`j''<1 	local b_`var'_`j' 	= trim("`: di %10.3fc `b_`var'_`j'''")
			else if `b_`var'_`j''<10 	local b_`var'_`j' 	= trim("`: di %10.3fc `b_`var'_`j'''")
			else  						local b_`var'_`j' 	= trim("`: di %10.2fc `b_`var'_`j'''")

			local b_`var'_`j' = "$`b_`var'_`j''^{`st'}$"

			* Format standard errors
			if `se_`var'_`j''==0 		local se_`var'_`j' = trim("`: di %10.3fc `se_`var'_`j'' '") 
			else if `se_`var'_`j''<1 	local se_`var'_`j' = trim("`: di %10.3fc `se_`var'_`j'' '") 
			else if `se_`var'_`j''<10 	local se_`var'_`j' = trim("`: di %10.3fc `se_`var'_`j'' '") 
			else 						local se_`var'_`j' = trim("`: di %10.2fc `se_`var'_`j'' '") 

			local se_`var'_`j' = "(`se_`var'_`j'')"

			* Display coefficient and standard error 
			di "`var':  `b_`var'_`j''  `se_`var'_`j''  `p'"

		}  // close loop J 

		local row_b_`var' = " `b_`var'_1' & `b_`var'_2' & `b_`var'_3' & `b_`var'_4' & `b_`var'_5' "
		local row_se_`var' = " `se_`var'_1' & `se_`var'_2' & `se_`var'_3' & `se_`var'_4' & `se_`var'_5' "

	} // close loop var 

	* Write output table
	local date $date
	cap file close myfile
	file open myfile using "$tables/RegressionOutput/Individual/Addon09/`date'_Individual_LPM_addon09_forward.tex", write replace

	//addon age female tertiary earnings health rating

	# delimit ; 
	file write myfile 
		"\begin{tabular}{l ccccc}" _n 
		"\toprule" _n 
		"& (1) & (2) & (3) & (4) \\" _n 
		"\footnotesize{Outcome: $\mathbf{1}\left( Switch = 1\right)$} & No controls & Individual controls & Rating sample & Provider controls & Provider FE \\ \midrule" _n
		"Add-on (Dummy) 		& `row_b_addon' 	\\" _n
		"						& `row_se_addon'	\\ " _n
		"Age 					& `row_b_age'		\\" _n 
		"						& `row_se_age'		\\" _n 
		"Female 				& `row_b_female'	\\" _n 
		"						& `row_se_female'	\\" _n 
		"Tertiary degree		& `row_b_tertiary'	\\" _n
		"						& `row_se_tertiary' \\" _n 
		"Earnings (log) 		& `row_b_earnings'	\\" _n 
		"						& `row_se_earnings' \\" _n 
		"Health satisfaction 	& `row_b_health' 	\\" _n 
		"						& `row_se_health'	\\" _n
		"Rating 				& `row_b_rating'	\\" _n 
		"						& `row_se_rating'	\\ \midrule" _n 
		"Provider-type FE 		& No & No & No & Yes & No \\" _n
		"Provider FE 			& No & No & No & No & Yes \\" _n 
		"Year FE 				& No & Yes & Yes & Yes & Yes \\ \midrule" _n
		"Mean outcome 			& `mean1' & `mean2' & `mean3' & `mean4' & `mean5'\\ " _n
		"Observations 			& `N1' & `N2' & `N3' & `N4' & `N5' \\" _n 
		"Number of insurers 	& `N1_ins' & `N2_ins' & `N3_ins' & `N4_ins' & `N5_ins' \\ \bottomrule" _n 
		"\end{tabular}"
	;
	# delimit cr
	file close myfile 	
	

* Close log file 
cap log close 

* SCRIPT END
