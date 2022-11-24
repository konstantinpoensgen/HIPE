********************************************************************************
*************************** SOEP & GKV Microdata Analysis **********************
********************************************************************************

cd "$hipe"

* Load data
use "$output/soep_gkv_match.dta", clear

* Final data cleaning & consistency ------------------------------------------ *

* Sample selection

	* Employment
	
		* Self-employment
		tab self_employment
			tab hi_switch if self_employment>0
			drop if self_employment>0
			
		tab occupation_position
			tab hi_switch if occupation_position>400 & occupation_position<500
			drop if occupation_position>400 & occupation_position<500	
			
		tab companysize
			drop if companysize==5
			
		* Employment status
		tab employment_status // all full-time employment
	
		* sector/occupation
		tab nace
		tab isco08
		
	* Health insurance
	
		* Health insurance type
		tab hi_type
			tab hi_switch if hi_type==2 // PKV only if switched
			//br pid year provider provider_l hi_switch hi_switch_lead if hi_type==2
			//br pid year provider provider_l hi_switch hi_switch_lead if pid==186404
	
		* Health insurance status
		tab hi_status // Compulsory member other few PKV 
		
		* Family co-insured PKV
		tab hi_pstatus
		drop if hi_pstatus==1
		
	* Education
	
		* degree
		tab degree
			tab age if degree==1
	
		* Bafoeg
		tab age if plc0168_h>0
		tab hi_switch if plc0168_h>0 
		drop if plc0168_h>0
		
		* currently receiving training
		tab plg0012
			tab age if plg0012==1 // not clear that this is "in school"
			tab hi_switch if plg0012==1
			
	* Marital status
	tab married
	
	* Drop individuals with income below 800€ (see Schmitz and Ziebarth, 2017)
	drop if income_gross<800
	
* Summary statistics --------------------------------------------------------- *

* Switches
	
	* Number of switches per year 
	
		* All switches identified
		
			// Contemporaneous effect
			table year hi_switch, c(count pid) row column
			table year, c(mean hi_switch) // shows % of change since hi_change binary
		
			// Forward t+1 effect
			table year hi_switch_lead, c(count pid) row column
			table year, c(mean hi_switch_lead)
			
		* Switches with provider information
		
			// define relevant providers
			cap drop info_l
				gen info_l = 1 if provider_l!="IKK/BIG" & provider_l!="LKK" & provider_l!="BKK" ///
				& provider_l!="PKV" & provider_l!="Other" & provider_!="AOK unattributable" ///
				& provider_l!="AOK Saarland" & provider_l!="AOK Rheinland-Pfalz" & provider!="AOK Schleswig-Holstein" ///
				& provider_l!="AOK Sachsen" & provider_l!="AOK Thueringen"
				
			//cap drop info
				gen info = 1 if provider!="IKK/BIG" & provider!="LKK" & provider!="BKK" ///
				& provider!="PKV" & provider!="Other" & provider!="AOK unattributable" ///
				& provider!="AOK Saarland" & provider!="AOK Rheinland-Pfalz" & provider!="AOK Schleswig-Holstein" ///
				& provider!="AOK Sachsen" & provider!="AOK Thueringen"
						
			// Contemporaneous effect
			table year hi_switch if info_l==1, c(count pid) row column
			table year if info_l==1, c(mean hi_switch)
		
			// Forward t+1 effect
			table year hi_switch_lead if info==1, c(count pid) row column
			table year if info==1, c(mean hi_switch_lead)
			
	
		* Observations and share of switches by provider
	
			// "contemporaneous" interpretation
			table year, c(n pid mean hi_switch) by(provider_l)
			table year hi_switch, c(n pid) by(provider_l)
		
			// "forward" interpretation
			table year, c(n pid mean hi_switch_lead) by(provider)
			
		* Export summary statistics
		
			// Switches per year 
				
				// All providers
				eststo switch_0: qui estpost tabstat hi_switch, stat(n) by(year) 
				eststo switch_1: qui estpost tabstat hi_switch if hi_switch==1, stat(n) by(year) 
				eststo switch_2: qui estpost tabstat hi_switch, stat(mean) by(year) 
			
				// Providers with info only
				eststo switch_3: qui estpost tabstat hi_switch if info_l==1, stat(n) by(year) 
				eststo switch_4: qui estpost tabstat hi_switch if hi_switch==1 & info_l==1, stat(n) by(year) 
				eststo switch_5: qui estpost tabstat hi_switch if info_l==1, stat(mean) by(year) 
				
				// Export final table
				esttab /*switch_0 switch_1 switch_2 */ switch_3 switch_4 switch_5 ///
					using "$tables/SummaryStats/Individual/sum_soep_gkv_obs_switches.tex" ///
					, replace c("count" "mean") ///
					noobs nogaps nonum booktabs ///
					mti("All obs." "All switches" "Share of switches" "Info obs." "Info switches" "Share of switches") ///
					title("Number of observations and HI provider switches"\label{tab:individualswitches})  ///
					addnotes("The total number of switches exceeds those with information on premium prices due missing granularity." ///
								"Table shows the contemporaneous effect interpretation." ///
								"Lead switches (forward t+1 interpretation) are analogously shifted backwards")

								
* Unique individuals 
preserve
	bysort pid: gen count = _n
	keep if count==1
	duplicates report pid
restore 
		
* Control variables	
				
	* Categorial individual-level characteristics
	table gender if hi_switch!=. & info_l==1, row c(freq)
	table married if hi_switch!=. & info_l==1, row c(freq)
	table degree if hi_switch!=. & info_l==1, row
		
	* Continuous individual-level characteristics
	sum age income_gross educ_years health_satisfaction doctor_visits /// 
		 if hi_switch!=. & info_l==1		
	
	* Categorial employment-related characteristics
	table nace if hi_switch!=. & info_l==1, row
	table isco08 if hi_switch!=. & info_l==1, row
	table companysize if hi_switch!=. & info_l==1, row
	
	* Health related variables
	table health_satisfaction if hi_switch!=. & info_l==1, row
	table health_worried if hi_switch!=. & info_l==1, row
	table reported_sick if hi_switch!=. & info_l==1, row
	table hospital_stay if hi_switch!=. & info_l==1, row
	table active_sport if hi_switch!=. & info_l==1, row
	
	* Provider level
	sum rating_relative if hi_switch!=. & info_l==1
	
	* Export summary statistics
	eststo sum_soep: qui estpost summarize age income_gross educ_years health_satisfaction doctor_visits ///
		if hi_switch!=. & info_l==1, d
	
	esttab sum_soep using "$tables/SummaryStats/Individual/sum_soep_summarystats.tex", replace ///
		cells("mean(fmt(2)) p5(fmt(2)) sd(fmt(1)) min(fmt(1)) max(fmt(1)) count(fmt(0))") ///
		title("Summary Statistics for Individual-Level Data (2009-18)"\label{tab:soepsummary}) booktabs compress nomtitles width(1\hsize) ///			nonumbers noobs 
		
	
	
	
	
********************************************************************************
***************************** Regression Analysis ******************************
********************************************************************************	
	
* define controls ------------------------------------------------------------ *

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

	// individual-level
	global baseline age i.gender i.tertiary income_gross_ln health_satisfaction // i.hospital_stay i.reported_sick
	global extension i.isco08 // i.married  i.companysize

	// provider-level
	global provider_baseline i.type_prior rating_relative_prior
	global provider_extension insured_initial  
	
	
* 2009-2014 ------------------------------------------------------------------ *

* Contemporaneous effect
	
	// No controls
	qui probit hi_switch i.addon09_dummy_prior if year>2008 & year<=2014, vce(robust)
		qui estimates store reg09_t0
		qui eststo reg09_t0_margins: margins, dydx(*) post 

	// Individual controls
	qui probit hi_switch i.addon09_dummy_prior i.year $baseline if year>2008 & year<=2014, vce(robust)
		qui estimates store reg09_individual_t0
		qui eststo reg09_individual_t0_margins: margins, dydx(*) post 

		
	// Provider controls
	qui probit hi_switch i.addon09_dummy_prior i.year $baseline $provider_baseline if year>2008 & year<=2014, vce(robust)
		qui estimates store reg09_provider_t0
		qui eststo reg09_provider_t0_margins: margins, dydx(*) post 
	
	// provider fixed effects
	qui probit hi_switch i.addon09_dummy_prior i.year $baseline $provider_baseline i.id if year>2008 & year<=2014 & addon09_dummy_prior!=., vce(robust)
		qui estimates store reg09_providerFE_t0	
		qui eststo reg09_providerFE_t0_margins: margins, dydx(*) post 		
		
		* Marginal effect for different ages
		// margins, dydx(addon09_dummy_prior) at(age=(20 25 30 35 40 45  50 55 60))
		// marginsplot
		
		* Calculate marginal effects for text
		//qui probit hi_switch i.addon09_dummy_prior i.year $baseline $provider_baseline i.id if year>2008 & year<=2014, vce(robust)
		//margins, dydx(i.addon09_dummy_prior age gender tertiary income_gross_ln health_satisfaction rating_relative_prior) 
			
* Forward t+1 effect

	// No controls
	qui probit hi_switch_lead i.addon09_dummy i.year if year>2008 & year<=2014, vce(robust)
		estimates store reg09_t1
	
	// Baseline individual
	qui probit hi_switch_lead i.addon09_dummy i.year $baseline if year>2008 & year<=2014, vce(robust)
		estimates store reg09_individual_t1
	
	// Baseline providers
	qui probit hi_switch_lead i.addon09_dummy i.year $baseline i.type rating_relative if year>2008 & year<=2014, vce(robust)
		estimates store reg09_provider_t1
	
* Export regression output

	* Contemporaneous effect (probit coefficients)
	esttab reg09_t0 reg09_individual_t0 reg09_provider_t0 reg09_providerFE_t0 ///
		using "$tables/RegressionOutput/Individual/Addon09/Individual_probit_addon09_contemporaneous.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression HI provider switch 2009-2014 (contemporaneous effect)"\label{tab:individual09cont}) addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) se booktabs width(0.95\hsize) ///
			coef(1.addon09_dummy_prior "Add-on 8 EUR" rating_relative_prior "Rating" income_gross_ln "log(income)" age "Age" 1.tertiary "Tertiary" 2.gender "Women" health_satisfaction "Health satisfaction") ///
			keep(1.addon09_dummy_prior age 2.gender 1.tertiary income_gross_ln health_satisfaction rating_relative_prior _cons) ///
			mti("No controls" "Individual baseline" "Provider controls" "Provider FE")		
	
	* Contemporaneous effect (marginal effects)
	esttab reg09_t0_margins reg09_individual_t0_margins reg09_provider_t0_margins reg09_providerFE_t0_margins ///
		using "$tables/RegressionOutput/Individual/Addon09/Individual_probit_addon09_contemporaneous_margins.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression HI provider switch 2009-2014 (contemporaneous effect marginal effects)"\label{tab:individual09contmarginal}) addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) se booktabs width(0.95\hsize) ///
			coef(1.addon09_dummy_prior "Add-on 8 EUR" rating_relative_prior "Rating" income_gross_ln "log(income)" age "Age" 1.tertiary "Tertiary" 2.gender "Women" health_satisfaction "Health satisfaction") ///
			keep(1.addon09_dummy_prior age 2.gender 1.tertiary income_gross_ln health_satisfaction rating_relative_prior) ///
			mti("No controls" "Individual baseline" "Provider controls" "Provider FE")		
			
	* Forward t+1 effect
	esttab reg09_t1 reg09_individual_t1 reg09_provider_t1 ///
		using "$tables/RegressionOutput/Individual/Addon09/Individual_probit_addon09_forward.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression HI provider switch 2009-2014 (forward effect)"\label{tab:individual09forw}) addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) ///
			coef(1.addon09_dummy "Add-on 8 EUR" rating_relative_prior "Rating" income_gross_ln "log(income)" age "Age" 1.tertiary "Tertiary" 2.gender "Women" health_satisfaction "Health satisfaction") ///
			drop(0.addon09_dummy 1.gender 0.tertiary 2009.year 2010.year 2011.year 2012.year 2013.year 2014.year 1.type 4.type 6.type) ///
			mti("No controls" "Individual baseline" "Provider controls" "Individual health")		
	

* 2015-2018 ------------------------------------------------------------------ *

eststo clear

* Contemporaneous 

	* Rename variables for easier esttab outpu
		rename addon_prior aop
		rename addon_change_prior aocp
		rename addon_diff_avg_prior adap
		rename addon_diff_predicted_prior adpp
		
	// Marginal effects	
	//probit hi_switch aop $baseline $provider_baseline $health $extension if year>2014 & year<2019, vce(robust)	
	//margins, dydx(aop gender income_gross_ln) at(age=(20 30 40 50 60))
	//marginsplot
		
	* Regression loop
	
	foreach rhs in aop aocp {
		
		// No controls
		qui probit hi_switch `rhs' if year>2014 & year<2019, vce(robust)		
			qui estimates store reg15_t0_`rhs'
			qui eststo t0_`rhs'_margins: margins, dydx(*) post 

		// Baseline individuals
		qui probit hi_switch `rhs' $baseline i.year if year>2014 & year<2019, vce(robust)	
			qui estimates store reg15_base_t0_`rhs'
			qui eststo base_t0_`rhs'_margins: margins, dydx(*) post 
		
		// Baseline provider						
		qui probit hi_switch `rhs' $baseline i.year $provider_baseline if year>2014 & year<2019, vce(robust)							
			qui estimates store reg15_prov_t0_`rhs'
			qui eststo prov_t0_`rhs'_margins: margins, dydx(*) post 
	
		// Health individual
		qui probit hi_switch `rhs' $baseline i.year $provider_baseline $health if year>2014 & year<2019, vce(robust)							
			qui estimates store reg15_health_t0_`rhs'
			qui eststo health_t0_`rhs'_margins: margins, dydx(*) post
			
		// Extension individual
		qui probit hi_switch `rhs' $baseline i.year $provider_baseline $health $extension if year>2014 & year<2019, vce(robust)							
			qui estimates store reg15_ext_t0_`rhs'
			qui eststo ext_t0_`rhs'_margins: margins, dydx(*) post
			
		// Export regression output
		esttab reg15_t0_`rhs' reg15_base_t0_`rhs' reg15_prov_t0_`rhs' reg15_health_t0_`rhs' reg15_ext_t0_`rhs' ///
		using "$tables/RegressionOutput/Individual/Addon15/Individual_probit_addon15_`rhs'_contemporaneous.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression `rhs' HI provider switch 2015-2018 (contemporaneous effect)") addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(`rhs' "`rhs'" rating_relative_prior "Rating" health_satisfaction "Health satisfaction") ///
			drop(0.isco08 2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08) ///
			mti("No controls" "Individual baseline" "Provider baseline" "Individual health" "Individual extension")	
		} 
		
	* Undo variable name changes
		rename aop addon_prior 
		rename aocp addon_change_prior 
		rename adap addon_diff_avg_prior 
		rename adpp addon_diff_predicted_prior 
		
		
* Contemporaneous IV

	* Rename variables for easier esttab outpu
		rename addon_prior aop
	
	* Regression loop
				
		local rhs aop
		
		qui ivprobit hi_switch $baseline i.year $provider_baseline (`rhs' = expenditure_admin_pc_prior) ///
			if year>2014 & year<2019
			
			estimates store reg15_prov_IV_t0_`rhs'
		
		// Health + extension individual
		qui ivprobit hi_switch $baseline i.year $provider_baseline $health $extension (`rhs' = expenditure_admin_pc_prior) ///
			if year>2014 & year<2019							
			
			estimates store reg15_ext_IV_t0_`rhs'
						
		// Export regression output
		esttab reg15_prov_IV_t0_`rhs' reg15_ext_IV_t0_`rhs'   ///
		using "$tables/RegressionOutput/Individual/Addon15/Individual_probitIV_addon15_`rhs'_contemporaneous.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("IV Probit regression `rhs' HI provider switch 2015-2018 (contemporaneous effect)") addnotes("Instruments: admin pc and capital reserves pc" "probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(`rhs' "`rhs'" rating_relative_prior "Rating" health_satisfaction "Health satisfaction") ///
			drop(2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08) ///
			mti("No controls" "Individual baseline" "Provider baseline" "Individual health" "Individual extension")	
		
	* Undo variable name changes
		rename aop addon_prior 
	
* Contemporaneous PLUS

	* Rename variables for easier esttab outpu
		rename addon_prior aop
		rename addon_change_prior aocp
		rename addon_diff_avg_prior adap
		rename addon_diff_predicted_prior adpp
		
		rename addon_l aop_l
		rename addon_change_l aocp_l
		rename addon_diff_avg_l adap_l
		rename addon_diff_predicted adpp_l		
	
	* Regression loop

	foreach rhs in aop aocp adap {
		
		// No controls
		qui probit hi_switch `rhs' `rhs'_l if year>2014 & year<2019, vce(robust)		
			estimates store reg15_t0_plus_`rhs'
		
		// Baseline individuals
		qui probit hi_switch `rhs' `rhs'_l $baseline if year>2014 & year<2019, vce(robust)	
			estimates store reg15_base_t0_plus_`rhs'
		
		// Baseline provider						
		qui probit hi_switch `rhs' `rhs'_l $baseline $provider_baseline if year>2014 & year<2019, vce(robust)							
			estimates store reg15_prov_t0_plus_`rhs'
	
		// Health individual
		qui probit hi_switch `rhs' `rhs'_l $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)							
			estimates store reg15_health_t0_plus_`rhs'
		
		// Extension individual
		qui probit hi_switch `rhs' `rhs'_l $baseline $provider_baseline $health $extension if year>2014 & year<2019, vce(robust)							
			estimates store reg15_ext_t0_plus_`rhs' 
			
		// Export regression output
		esttab reg15_t0_`rhs' reg15_base_t0_plus_`rhs' reg15_prov_t0_plus_`rhs' reg15_health_t0_plus_`rhs' reg15_ext_t0_plus_`rhs' ///
		using "$tables/RegressionOutput/Individual/Addon15/Individual_probit_addon15_`rhs'_contemporaneous_plus.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regression `rhs' HI provider switch 2015-2018 (contemporaneous PLUS effect)") addnotes("probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(`rhs' "`rhs'" `rhs'_l "rhs lagged" rating_relative_prior "Rating" health_satisfaction "Health satisfaction") ///
			drop(2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08) ///
			mti("No controls" "Individual baseline" "Provider baseline" "Individual health" "Individual extension")	
		
		} 
		
	* Undo variable name changes
		rename aop addon_prior 
		rename aocp addon_change_prior 
		rename adap addon_diff_avg_prior 
		rename adpp addon_diff_predicted_prior 
		
		rename aop_l addon_l
		rename aocp_l addon_change_l
		rename adap_l addon_diff_avg_l
		rename adpp_l addon_diff_predicted
		
		
* Forward t+1 

	* Rename variables for easier esttab outpu
		rename addon ao
		rename addon_change aoc
		rename addon_diff_avg ada
		rename addon_diff_predicted adp
	
	* Regression loop

	foreach rhs in ao aoc ada adp {

		// No controls
		qui probit hi_switch_lead `rhs' if year>2014 & year<2019, vce(robust)		
			estimates store reg15_t1_`rhs'
		
		// Baseline individuals
		qui probit hi_switch_lead `rhs' $baseline if year>2014 & year<2019, vce(robust)	
			estimates store reg15_base_t1_`rhs'
		
		// Baseline provider						
		qui probit hi_switch_lead `rhs' $baseline i.type rating_relative if year>2014 & year<2019, vce(robust)							
			estimates store reg15_prov_t1_`rhs'
	
		// Health individual
		qui probit hi_switch_lead `rhs' $baseline i.type rating_relative $health if year>2014 & year<2019, vce(robust)							
			estimates store reg15_health_t1_`rhs'
		
		// Extension individual
		qui probit hi_switch_lead `rhs' $baseline i.type rating_relative $health $extension if year>2014 & year<2019, vce(robust)							
			estimates store reg15_ext_t1_`rhs' 
			
		// Export regression output
		esttab reg15_t1_`rhs' reg15_base_t1_`rhs' reg15_prov_t1_`rhs' reg15_health_t1_`rhs' reg15_ext_t1_`rhs' ///
		using "$tables/RegressionOutput/Individual/Addon15/Individual_probit_addon15_`rhs'_forward.tex" ///
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
	
	
	* Export selected regressions for publication
	
		// Contemporaneous effect (probit coefficients)
		esttab reg15_t0_aop reg15_ext_t0_aop reg15_ext_IV_t0_aop reg15_t0_aocp reg15_ext_t0_aocp ///
			using "$tables/RegressionOutput/Individual/Addon15/Individual_joint_addon15_contemporaneous.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regressions provider switch 2015-2018 (contemporaneous effect)"\label{tab:individual15cont}) addnotes("Instruments: admin pc and capital reserves pc" "probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(aop "Add-on (pp.)" aocp "$\Delta$ add-on" rating_relative_prior "Rating" health_satisfaction "Health satisfaction" age "Age" 1.tertiary "Tertiary" income_gross_ln "log(income)") ///
			drop(0.isco08 2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08 1.gender 0.tertiary 2015.year 2016.year 2017.year 2018.year 1.type_prior 4.type_prior 6.type_prior) ///
			order(aop aocp) ///
			mti("No controls" "Controls" "Probit IV" "No controls" "Controls")
			
		// Contemporaneous effect (marginal effects) -- excludes marginal effects for IVprobit
		esttab t0_aop_margins ext_t0_aop_margins t0_aocp_margins ext_t0_aocp_margins ///
			using "$tables/RegressionOutput/Individual/Addon15/Individual_joint_addon15_contemporaneous_margins.tex" ///
			, replace star(* 0.05 ** 0.01 *** 0.001)  ///
			title("Probit regressions provider switch 2015-2018 (contemporaneous effect)"\label{tab:individual15contmarginal}) addnotes("Instruments: admin pc and capital reserves pc" "probit coefficients (i.e. not mmarginal effects)")  ///
			style(tex) label se booktabs width(0.95\hsize) compress ///
			coef(aop "Add-on (pp.)" aocp "$\Delta$ add-on" rating_relative_prior "Rating" health_satisfaction "Health satisfaction" age "Age" 1.tertiary "Tertiary" income_gross_ln "log(income)") ///
			drop(0.isco08 2.isco08 3.isco08 4.isco08 5.isco08 6.isco08 7.isco08 8.isco08 9.isco08 1.gender 0.tertiary 2015.year 2016.year 2017.year 2018.year 1.type_prior 4.type_prior 6.type_prior) ///
			order(aop aocp) ///
			mti("No controls" "Controls" "No controls" "Controls")
	
* Heterogeneity -> cannot pick up any effect

	// Age
	probit hi_switch addon_change_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_prior c.addon_change_prior#c.age $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	// Tertiary
	probit hi_switch addon_change_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_change_prior c.addon_change_prior#i.tertiary $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	// Income
	probit hi_switch addon_change_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_change_prior c.addon_change_prior#c.income_gross_ln $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	// Health satisfaction
	probit hi_switch addon_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_change_prior c.addon_change_prior#c.health_satisfaction $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	// Gender
	probit hi_switch addon_change_prior $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)
	probit hi_switch addon_change_prior c.addon_change_prior#i.gender $baseline $provider_baseline $health if year>2014 & year<2019, vce(robust)

	
* "DiD" among all providers -------------------------------------------------- *

// Does not really show effects
// Change group addon thresholds first?

* Group thresholds
sum addon_diff_avg, d

* 2009-14

	preserve 
	
		// Generate DiD group variable
		cap drop addon09_group
		gen addon09_group = 0 
		replace addon09_group = 1 if provider=="Deutsche Angestellten Krankenkasse" | provider=="KKH Kaufmaennische Krankenkasse"  | provider=="DAK-Gesundheit"
	
	
		// Run OLS regression
		qui probit hi_switch i.year#i.addon09_group i.type $baseline if year<2015
		qui margins year#addon09_group
		marginsplot
	
	restore


* 2015-18

	preserve

		// Drop providers that charged 2010-12 addon09
		drop if provider=="Deutsche Angestellten Krankenkasse" 
		drop if provider=="KKH Kaufmaennische Krankenkasse" 
		drop if provider=="DAK-Gesundheit"

		// Run DiD
		qui probit hi_switch i.year#i.addon_did_group i.type $baseline

		qui margins year#addon_did_group

		marginsplot ,  xline(2014.5, lp(dash)) yline(0) ///
			title("Individual-level switching probability difference-in-difference") ytitle("Pr(Switch=1)") legend(cols(3))
	
	restore
	
	
* "DiD" among "vdek" --------------------------------------------------------- *


* Share of switches

	* Contemporaneous effect
		preserve
		
			// streamline provider name
			replace provider_l="BARMER" if provider_l=="BARMER GEK" | provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)"
			replace provider_l="DAK" if provider_l=="DAK-Gesundheit" | provider_l=="Deutsche Angestellten Krankenkasse"
			replace provider_l="KKH" if provider_l=="KKH Kaufmaennische Krankenkasse"
			replace provider_l="TK" if provider_l=="Techniker Krankenkasse (TK)"

			keep if provider_l=="BARMER" | provider_l=="DAK" | provider_l=="TK"
	
			// collapse data
			collapse (mean) hi_switch, by(provider_l year)
			sort provider_l year

			// Plot share of switches in data
			graph twoway (line hi_switch year if provider_l=="BARMER") (line hi_switch year if provider_l=="TK") ///
				(line hi_switch year if provider_l=="DAK") (line hi_switch year if provider_l=="KKH") ///
					, xline(2010 2012 2015, lp(dash) lc(gs10)) xlab(2009(1)2018, labsize(3)) legend(lab(1 "BARMER") lab(2 "TK") lab(3 "DAK") lab(4 "KKH")) ///
					title("Share of switches by vdek provider") subtitle("Contemporaneous effect") xtitle("") ytitle("Share of swichers")
	
				graph export "$figures/DiD/Individual/SimpleShare_contemporaneous.png", replace
	
		restore
				
	* Forward t+1 effect
		preserve
		
			// streamline provider name
			replace provider="BARMER" if provider=="BARMER GEK" | provider=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)"
			replace provider="DAK" if provider=="DAK-Gesundheit" | provider=="Deutsche Angestellten Krankenkasse"
			replace provider="KKH" if provider=="KKH Kaufmaennische Krankenkasse"
			replace provider="TK" if provider=="Techniker Krankenkasse (TK)"

			keep if provider=="BARMER" | provider=="DAK" | provider=="TK"
	
			// collapse data
			collapse (mean) hi_switch_lead, by(provider year)
			sort provider year

			// Plot share of switches in data
			graph twoway (line hi_switch year if provider=="BARMER") (line hi_switch year if provider=="TK") ///
				(line hi_switch year if provider=="DAK") (line hi_switch year if provider=="KKH") ///
					, xline(2010 2012 2015, lp(dash) lc(gs10)) xlab(2009(1)2017, labsize(3)) legend(lab(1 "BARMER") lab(2 "TK") lab(3 "DAK") lab(4 "KKH")) ///
					title("Share of switches by vdek provider") subtitle("Forward effect") xtitle("") ytitle("Share of swichers")
	
				graph export "$figures/DiD/Individual/SimpleShare_forward.png", replace
	
		restore
	
			
* DID contemporaneous effect

	preserve
		* Prepare data

			// streamline provider name
			replace provider_l="BARMER" if provider_l=="BARMER GEK" | provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)"
			replace provider_l="DAK" if provider_l=="DAK-Gesundheit" | provider_l=="Deutsche Angestellten Krankenkasse"
			replace provider_l="KKH" if provider_l=="KKH Kaufmaennische Krankenkasse"
			replace provider_l="TK" if provider_l=="Techniker Krankenkasse (TK)"

			keep if provider_l=="BARMER" | provider_l=="DAK" | provider_l=="TK"
	
			// encode provider name
			cap drop provider_id
			encode provider_l, gen(provider_id)	// important to use provider_l because we want to get the "outflow" switch
	
		* Run probit and marginsplot
		qui probit hi_switch i.provider_id#i.year i.year $baseline, vce(robust)
	
		qui margins year#provider_id
		marginsplot, title("") ///
			xline(2010 2012 2015, lp(dash) lc(gs10)) xlab(2009(1)2017, labsize(3)) xtitle("") ytitle("Pr(Switch=1)")
		
			graph export "$figures/DiD/Individual/DiD_vdek_contemporaneous.png", replace
	
	restore

	
* DID forward t+1 effect

	preserve 

		* Prepare data
	
			// streamline provider name
			replace provider="BARMER" if provider=="BARMER GEK" | provider=="Barmer Ersatzkasse (BEK)" | provider=="Gmuender Ersatzkasse (GEK)"
			replace provider="DAK" if provider=="DAK-Gesundheit" | provider=="Deutsche Angestellten Krankenkasse"
			replace provider="KKH" if provider=="KKH Kaufmaennische Krankenkasse"
			replace provider="TK" if provider=="Techniker Krankenkasse (TK)"
	
			keep if provider=="BARMER" | provider=="DAK" | provider=="TK"

			// encode provider name
			cap drop provider_id
			encode provider, gen(provider_id)	// important to use provider_l because we want to get the "outflow" switch
	
		* Run probit and marginsplot
		qui probit hi_switch_lead i.provider_id#i.year i.year $baseline, vce(robust)
		
		qui margins year#provider_id
		marginsplot, title("") ///
			xline(2010 2012 2015, lp(dash) lc(gs10)) xlab(2009(1)2017, labsize(3)) xtitle("") ytitle("Pr(Switch=1)")
		
			graph export "$figures/DiD/Individual/DiD_vdek_forward.png", replace

	restore



* SCRIPT END
