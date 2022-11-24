********************************************************************************
*************************** SOEP & GKV REGRESSIONS *****************************
********************************************************************************

/* 	OBJECTIVES
	- Run probit switching regressions for various control variable specifications
	- Contemporaneous and forward effect
	- With and without IV
	- Explore heterogeneity of effect
	
	OUTLINE
	0) 	Preliminaries 
	1) 	Data
	2) 	Define controls
	3) 	Period 1: 2009-2014
		3.1) Contemporaneous effect
		3.2) Forward t+1 effect
		3.3) Export regression output
	4) 	Period 2: 2015-2018
		4.1) Contemporaneous 
		4.2) Contemporaneous IV
		4.3) Contemporaneous PLUS
		4.4) Forward t+1 
	5) 	Export selected regressions for publication
	6) 	Heterogeneity Analysis 	
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
log using "$logs_analysis/`date'_analysis_soep_gkv_regressions.log", text replace	


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
	global baseline age i.gender i.tertiary income_gross_ln health_satisfaction // i.hospital_stay i.reported_sick
	global extension i.isco08 // i.married  i.companysize

	* provider-level
	global provider_baseline i.type_prior rating_relative_prior
	global provider_extension insured_initial  
	
	
* 3) Period 1: 2009-2014 ----------------------------------------------------- *

	* 3.1) Contemporaneous effect
	* ........................................................................ *
	
	* No controls
	qui probit hi_switch i.addon09_dummy_prior if year>2008 & year<=2014, vce(robust)
		qui estimates store reg09_t0
		qui eststo reg09_t0_margins: margins, dydx(*) post 

	* + Individual controls
	qui probit hi_switch i.addon09_dummy_prior i.year $baseline if year>2008 & year<=2014, vce(robust)
		qui estimates store reg09_individual_t0
		qui eststo reg09_individual_t0_margins: margins, dydx(*) post 

		
	* + Provider controls
	qui probit hi_switch i.addon09_dummy_prior i.year $baseline $provider_baseline if year>2008 & year<=2014, vce(robust)
		qui estimates store reg09_provider_t0
		qui eststo reg09_provider_t0_margins: margins, dydx(*) post 
	
	* + provider fixed effects
	qui probit hi_switch i.addon09_dummy_prior i.year $baseline $provider_baseline i.id if year>2008 & year<=2014 & addon09_dummy_prior!=., vce(robust)
		qui estimates store reg09_providerFE_t0	
		qui eststo reg09_providerFE_t0_margins: margins, dydx(*) post 		
		
		* Marginal effect for different ages
		//margins, dydx(addon09_dummy_prior) at(age=(20 25 30 35 40 45  50 55 60))
		//marginsplot
		
		* Calculate marginal effects for text
		//qui probit hi_switch i.addon09_dummy_prior i.year $baseline $provider_baseline i.id if year>2008 & year<=2014, vce(robust)
		//margins, dydx(i.addon09_dummy_prior age gender tertiary income_gross_ln health_satisfaction rating_relative_prior) 
			
	
	* 3.2) Forward t+1 effect
	* ........................................................................ *

	* No controls
	qui probit hi_switch_lead i.addon09_dummy i.year if year>2008 & year<=2014, vce(robust)
		estimates store reg09_t1
	
	* Baseline individual
	qui probit hi_switch_lead i.addon09_dummy i.year $baseline if year>2008 & year<=2014, vce(robust)
		estimates store reg09_individual_t1
	
	* Baseline providers
	qui probit hi_switch_lead i.addon09_dummy i.year $baseline i.type rating_relative if year>2008 & year<=2014, vce(robust)
		estimates store reg09_provider_t1
	
	
	* 3.3) Export regression output
	* ........................................................................ *

	local date $date

	* Contemporaneous effect (probit coefficients)
	esttab reg09_t0 reg09_individual_t0 reg09_provider_t0 reg09_providerFE_t0 ///
		using "$tables/RegressionOutput/Individual/Addon09/`date'_Individual_probit_addon09_contemporaneous.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression HI provider switch 2009-2014 (contemporaneous effect)"\label{tab:individual09cont}) addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) se booktabs width(0.95\hsize) ///
			coef(1.addon09_dummy_prior "Add-on 8 EUR" rating_relative_prior "Rating" income_gross_ln "log(income)" age "Age" 1.tertiary "Tertiary" 2.gender "Women" health_satisfaction "Health satisfaction") ///
			keep(1.addon09_dummy_prior age 2.gender 1.tertiary income_gross_ln health_satisfaction rating_relative_prior _cons) ///
			mti("No controls" "Individual baseline" "Provider controls" "Provider FE")		
	
	* Contemporaneous effect (marginal effects)
	esttab reg09_t0_margins reg09_individual_t0_margins reg09_provider_t0_margins reg09_providerFE_t0_margins ///
		using "$tables/RegressionOutput/Individual/Addon09/`date'_Individual_probit_addon09_contemporaneous_margins.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression HI provider switch 2009-2014 (contemporaneous effect marginal effects)"\label{tab:individual09contmarginal}) addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) se booktabs width(0.95\hsize) ///
			coef(1.addon09_dummy_prior "Add-on 8 EUR" rating_relative_prior "Rating" income_gross_ln "log(income)" age "Age" 1.tertiary "Tertiary" 2.gender "Women" health_satisfaction "Health satisfaction") ///
			keep(1.addon09_dummy_prior age 2.gender 1.tertiary income_gross_ln health_satisfaction rating_relative_prior) ///
			mti("No controls" "Individual baseline" "Provider controls" "Provider FE")		
			
	* Forward t+1 effect
	esttab reg09_t1 reg09_individual_t1 reg09_provider_t1 ///
		using "$tables/RegressionOutput/Individual/Addon09/`date'_Individual_probit_addon09_forward.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression HI provider switch 2009-2014 (forward effect)"\label{tab:individual09forw}) addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) ///
			coef(1.addon09_dummy "Add-on 8 EUR" rating_relative_prior "Rating" income_gross_ln "log(income)" age "Age" 1.tertiary "Tertiary" 2.gender "Women" health_satisfaction "Health satisfaction") ///
			drop(0.addon09_dummy 1.gender 0.tertiary 2009.year 2010.year 2011.year 2012.year 2013.year 2014.year 1.type 4.type 6.type) ///
			mti("No controls" "Individual baseline" "Provider controls" "Individual health")		
	

* 4) Period 2: 2015-2018 ----------------------------------------------------- *

	* Clear estimates
	eststo clear

	
	* 4.1) Contemporaneous 
	* ........................................................................ *

	* Rename variables for easier esttab outpu
	ren addon_prior 				aop
	ren addon_change_prior 			aocp
	ren addon_diff_avg_prior 		adap
	ren addon_diff_predicted_prior 	adpp
		
	* Marginal effects	
	probit hi_switch aop $baseline $provider_baseline $health $extension if year>2014 & year<2019, vce(robust)	
	margins, dydx(aop gender income_gross_ln) at(age=(20 30 40 50 60))
	marginsplot
		
	* Regression loop
	foreach rhs in aop aocp adap {
		
		* No controls
		qui probit hi_switch `rhs' if year>2014 & year<2019, vce(robust)		
			qui estimates store reg15_t0_`rhs'
			qui eststo t0_`rhs'_margins: margins, dydx(*) post 

		* + Baseline individuals
		qui probit hi_switch `rhs' $baseline i.year if year>2014 & year<2019, vce(robust)	
			qui estimates store reg15_base_t0_`rhs'
			qui eststo base_t0_`rhs'_margins: margins, dydx(*) post 
		
		* + Baseline provider						
		qui probit hi_switch `rhs' $baseline i.year $provider_baseline if year>2014 & year<2019, vce(robust)							
			qui estimates store reg15_prov_t0_`rhs'
			qui eststo prov_t0_`rhs'_margins: margins, dydx(*) post 
	
		* + Health individual
		qui probit hi_switch `rhs' $baseline i.year $provider_baseline $health if year>2014 & year<2019, vce(robust)							
			qui estimates store reg15_health_t0_`rhs'
			qui eststo health_t0_`rhs'_margins: margins, dydx(*) post
			
		* + Extension individual
		qui probit hi_switch `rhs' $baseline i.year $provider_baseline $health $extension if year>2014 & year<2019, vce(robust)							
			qui estimates store reg15_ext_t0_`rhs'
			qui eststo ext_t0_`rhs'_margins: margins, dydx(*) post
			
		* Export regression output
		local date $date 
		esttab reg15_t0_`rhs' reg15_base_t0_`rhs' reg15_prov_t0_`rhs' reg15_health_t0_`rhs' reg15_ext_t0_`rhs' ///
		using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_probit_addon15_`rhs'_contemporaneous.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression `rhs' HI provider switch 2015-2018 (contemporaneous effect)") addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(`rhs' "`rhs'" rating_relative_prior "Rating" health_satisfaction "Health satisfaction") ///
			drop(0.isco08 2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08) ///
			mti("No controls" "Individual baseline" "Provider baseline" "Individual health" "Individual extension")	
		} 
		
	* Undo variable name changes
	ren aop addon_prior 
	ren aocp addon_change_prior 
	ren adap addon_diff_avg_prior 
	ren adpp addon_diff_predicted_prior 
		
		
	* 4.2) Contemporaneous IV
	* ........................................................................ *

	* Rename variables for easier esttab outpu
	ren addon_prior aop
	
	* Regression loop		
	foreach rhs in aop {
		
		qui ivprobit hi_switch $baseline i.year $provider_baseline (`rhs' = expenditure_admin_pc_prior) ///
			if year>2014 & year<2019
			
			estimates store reg15_prov_IV_t0_`rhs'
		
		* Health + extension individual
		qui ivprobit hi_switch $baseline i.year $provider_baseline $health $extension (`rhs' = expenditure_admin_pc_prior) ///
			if year>2014 & year<2019							
			
			estimates store reg15_ext_IV_t0_`rhs'
						
		* Export regression output
		local date $date 
		esttab reg15_prov_IV_t0_`rhs' reg15_ext_IV_t0_`rhs'   ///
		using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_probitIV_addon15_`rhs'_contemporaneous.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("IV Probit regression `rhs' HI provider switch 2015-2018 (contemporaneous effect)") addnotes("Instruments: admin pc and capital reserves pc" "probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(`rhs' "`rhs'" rating_relative_prior "Rating" health_satisfaction "Health satisfaction") ///
			drop(2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08) ///
			mti("No controls" "Individual baseline" "Provider baseline" "Individual health" "Individual extension")	
		
	}

	* Undo variable name changes
	ren aop addon_prior 
	
	
	* 4.3) Contemporaneous PLUS
	* ........................................................................ *

	* Rename variables for easier esttab outpu
	ren addon_prior aop
	ren addon_change_prior aocp
	ren addon_diff_avg_prior adap
	ren addon_diff_predicted_prior adpp
	
	ren addon_l aop_l
	ren addon_change_l aocp_l
	ren addon_diff_avg_l adap_l
	ren addon_diff_predicted adpp_l		
	
	* Regression loop
	foreach rhs in aop aocp adap {
		
		* No controls
		qui probit hi_switch `rhs' `rhs'_l if year>2014 & year<2019, vce(robust)		
			estimates store reg15_t0_plus_`rhs'
		
		* Baseline individuals
		qui probit hi_switch `rhs' `rhs'_l $baseline if year>2014 & year<2019, vce(robust)	
			estimates store reg15_base_t0_plus_`rhs'
		
		* Baseline provider						
		qui probit hi_switch `rhs' `rhs'_l $baseline $provider_baseline if year>2014 & year<2019, vce(robust)							
			estimates store reg15_prov_t0_plus_`rhs'
	
		* Health individual
		qui probit hi_switch `rhs' `rhs'_l $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)							
			estimates store reg15_health_t0_plus_`rhs'
		
		* Extension individual
		qui probit hi_switch `rhs' `rhs'_l $baseline $provider_baseline $health $extension if year>2014 & year<2019, vce(robust)							
			estimates store reg15_ext_t0_plus_`rhs' 
			
		* Export regression output
		local date $date 
		esttab reg15_t0_`rhs' reg15_base_t0_plus_`rhs' reg15_prov_t0_plus_`rhs' reg15_health_t0_plus_`rhs' reg15_ext_t0_plus_`rhs' ///
		using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_probit_addon15_`rhs'_contemporaneous_plus.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression `rhs' HI provider switch 2015-2018 (contemporaneous PLUS effect)") addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(`rhs' "`rhs'" `rhs'_l "rhs lagged" rating_relative_prior "Rating" health_satisfaction "Health satisfaction") ///
			drop(2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08) ///
			mti("No controls" "Individual baseline" "Provider baseline" "Individual health" "Individual extension")	
		
		} 
		
	* Undo variable name changes
	ren aop addon_prior 
	ren aocp addon_change_prior 
	ren adap addon_diff_avg_prior 
	ren adpp addon_diff_predicted_prior 
	
	ren aop_l addon_l
	ren aocp_l addon_change_l
	ren adap_l addon_diff_avg_l
	ren adpp_l addon_diff_predicted
		
		
	* 4.4) Forward t+1 
	* ........................................................................ *
	
	* Rename variables for easier esttab outpu
	ren addon ao
	ren addon_change aoc
	ren addon_diff_avg ada
	ren addon_diff_predicted adp
	
	* Regression loop
	foreach rhs in ao aoc ada adp {

		* No controls
		qui probit hi_switch_lead `rhs' if year>2014 & year<2019, vce(robust)		
			estimates store reg15_t1_`rhs'
		
		* Baseline individuals
		qui probit hi_switch_lead `rhs' $baseline if year>2014 & year<2019, vce(robust)	
			estimates store reg15_base_t1_`rhs'
		
		* Baseline provider						
		qui probit hi_switch_lead `rhs' $baseline i.type rating_relative if year>2014 & year<2019, vce(robust)							
			estimates store reg15_prov_t1_`rhs'
	
		* Health individual
		qui probit hi_switch_lead `rhs' $baseline i.type rating_relative $health if year>2014 & year<2019, vce(robust)							
			estimates store reg15_health_t1_`rhs'
		
		* Extension individual
		qui probit hi_switch_lead `rhs' $baseline i.type rating_relative $health $extension if year>2014 & year<2019, vce(robust)							
			estimates store reg15_ext_t1_`rhs' 
			
		* Export regression output
		local date $date
		esttab reg15_t1_`rhs' reg15_base_t1_`rhs' reg15_prov_t1_`rhs' reg15_health_t1_`rhs' reg15_ext_t1_`rhs' ///
		using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_probit_addon15_`rhs'_forward.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression `rhs' HI provider switch 2015-2018 (forward effect)") addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(`rhs' "`rhs'" rating_relative "Rating" health_satisfaction "Heath satisfaction") ///
			drop(0.isco08 2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08) ///
			mti("No controls" "Individual baseline" "Provider baseline" "Individual health" "Individual extension")	
		} 
		
			
	* Undo variable name changes
		rename ao addon 
		rename aoc addon_change 
		rename ada addon_diff_avg
		rename adp addon_diff_predicted
	
	
* 5) Export selected regressions for publication
* ---------------------------------------------------------------------------- *
	
	local date $date

	* Contemporaneous effect (probit coefficients)
	esttab reg15_t0_aop reg15_ext_t0_aop reg15_ext_IV_t0_aop reg15_t0_aocp reg15_ext_t0_aocp ///
		using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_joint_addon15_contemporaneous.tex" ///
		, replace star(* 0.05 ** 0.01 *** 0.001)  ///
		title("Probit regressions provider switch 2015-2018 (contemporaneous effect)"\label{tab:individual15cont}) addnotes("Instruments: admin pc and capital reserves pc" "probit coefficients (i.e. not mmarginal effects)")  ///
		style(tex) label se booktabs width(0.95\hsize) compress ///
		coef(aop "Add-on (pp.)" aocp "$\Delta$ add-on" rating_relative_prior "Rating" health_satisfaction "Health satisfaction" age "Age" 1.tertiary "Tertiary" income_gross_ln "log(income)") ///
		drop(0.isco08 2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08 1.gender 0.tertiary 2015.year 2016.year 2017.year 2018.year 1.type_prior 4.type_prior 6.type_prior) ///
		order(aop aocp) ///
		mti("No controls" "Controls" "Probit IV" "No controls" "Controls")
		
	* Contemporaneous effect (marginal effects) -- excludes marginal effects for IVprobit
	esttab t0_aop_margins ext_t0_aop_margins t0_aocp_margins ext_t0_aocp_margins ///
		using "$tables/RegressionOutput/Individual/Addon15/`date'_Individual_joint_addon15_contemporaneous_margins.tex" ///
		, replace star(* 0.05 ** 0.01 *** 0.001)  ///
		title("Probit regressions provider switch 2015-2018 (contemporaneous effect)"\label{tab:individual15contmarginal}) addnotes("Instruments: admin pc and capital reserves pc" "probit coefficients (i.e. not mmarginal effects)")  ///
		style(tex) label se booktabs width(0.95\hsize) compress ///
		coef(aop "Add-on (pp.)" aocp "$\Delta$ add-on" rating_relative_prior "Rating" health_satisfaction "Health satisfaction" age "Age" 1.tertiary "Tertiary" income_gross_ln "log(income)") ///
		drop(0.isco08 2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08 1.gender 0.tertiary 2015.year 2016.year 2017.year 2018.year 1.type_prior 4.type_prior 6.type_prior) ///
		order(aop aocp) ///
		mti("No controls" "Controls" "No controls" "Controls")
	


* 6) Heterogeneity Analysis 													// cannot pick up any effect
* ---------------------------------------------------------------------------- *

	* Age
	probit hi_switch addon_change_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_prior c.addon_change_prior#c.age $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	* Tertiary
	probit hi_switch addon_change_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_change_prior c.addon_change_prior#i.tertiary $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	* Income
	probit hi_switch addon_change_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_change_prior c.addon_change_prior#c.income_gross_ln $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	* Health satisfaction
	probit hi_switch addon_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_change_prior c.addon_change_prior#c.health_satisfaction $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	* Gender
	probit hi_switch addon_change_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_change_prior c.addon_change_prior#i.gender $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)


* Close log file 
cap log close 

* SCRIPT END
