********************************************************************************
*************************** SOEP & GKV SUMMARY STATS ***************************
********************************************************************************

/* 	OBJECTIVES
	- Explore the data with summary statistics
	- Export sum stats for (i) insurer switches and (ii) covariates
	
	OUTLINE
	0) Preliminaries
	1) Data
	2) Number of insurer switches per year
	3) Export summary statistics on insurer switches
	4) Control variable summary stats

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
log using "$logs_analysis/`date'_analysis_soep_gkv_sumstats.log", text replace	


* 1) Data
* ---------------------------------------------------------------------------- *

* Load data 
use "$data_final/soep_gkv_match_cleaned.dta", clear


* 2) Number of insurer switches per year
* ---------------------------------------------------------------------------- *	

* All switches identified

	* Contemporaneous effect
	table year hi_switch, c(count pid) row column
	table year, c(mean hi_switch) 												// shows % of change since hi_change binary

	* Forward t+1 effect
	table year hi_switch_lead, c(count pid) row column
	table year, c(mean hi_switch_lead)
	
* Switches with provider information
				
	* Contemporaneous effect
	table year hi_switch if info_l==1, c(count pid) row column
	table year if info_l==1, c(mean hi_switch)

	* Forward t+1 effect
	table year hi_switch_lead if info==1, c(count pid) row column
	table year if info==1, c(mean hi_switch_lead)
	

* Observations and share of switches by provider

	* "contemporaneous" interpretation
	table year, c(n pid mean hi_switch) by(provider_l)
	table year hi_switch, c(n pid) by(provider_l)

	* "forward" interpretation
	table year, c(n pid mean hi_switch_lead) by(provider)
	

* 3) Export summary statistics on insurer switches
* ---------------------------------------------------------------------------- *

	* Prepare summary stat
	forvalues j = 1/2 {

		* Sample condition
		if `j'==1 	local sample = "info_l==. | info_l==1"
		if `j'==2 	local sample = "info_l==1" 

		* Initiate tex-locals
		local tex_headrow 	= ""
		local tex_all`j'	= "N"
		local tex_count`j' 	= "\# Switches"
		local tex_share`j' 	= "\% Switches"

		* Summarize # and % for each year
		forvalues y = 2009/2018 {
			
			* Header row
			local tex_headrow = "`tex_headrow' & \textbf{`y'}"

			* Count # all
			qui count if hi_switch!=. & (`sample') & year==`y'
			local temp = trim("`: di %10.0fc `r(N)''") 
			local tex_all`j' = "`tex_all`j'' & `temp'"

			* Count # switches
			qui count if hi_switch==1 & (`sample') & year==`y'
			local temp = trim("`: di %10.0fc `r(N)''")
			local tex_count`j' = "`tex_count`j'' & `temp'"

			* Share % switches
			qui sum hi_switch if (`sample') & year==`y'
			local temp = trim("`: di %10.1fc 100*`r(mean)''")
			local tex_share`j' = "`tex_share`j'' & `temp'"
		}

		* Full period
			
			* Header row
			local tex_headrow = "`tex_headrow' & \textbf{2009--18}"

			* Count # all
			qui count if hi_switch!=. & (`sample')
			local temp = trim("`: di %10.0fc `r(N)''")
			local tex_all`j' = "`tex_all`j'' & `temp'"

			* Count # switches
			qui count if hi_switch==1 & (`sample')
			local temp = trim("`: di %10.0fc `r(N)''")
			local tex_count`j' = "`tex_count`j'' & `temp'"

			* Share % switches
			qui sum hi_switch if (`sample') 
			local temp = trim("`: di %10.1fc 100*`r(mean)''")
			local tex_share`j' = "`tex_share`j'' & `temp'"
	}

	* Export La-Tex table
	cap file close myfile

	local date $date
	file open myfile using "$tables/SummaryStats/Individual/`date'_sum_soep_gkv_obs_switches.tex", write replace

	# delimit ;
		file write myfile  																															
		"\begin{tabular}{l ccccccccccc}"	_n	
		"\toprule" _n
		"`tex_headrow' \\ \midrule" _n 
		//" \multicolumn{12}{l}{\textit{Panel A: General population of interest}}	\\ \midrule" _n
		//"`tex_count1' \\" _n 
		//"`tex_share1' \\" _n 
		//"`tex_all1' \\ \midrule" _n 
		//" \multicolumn{12}{l}{\textit{Panel B: Sample with insurer information}} \\ \midrule" _n
		"`tex_count2' \\" _n 
		"`tex_share2' \\ \midrule" _n 
		"`tex_all2' \\ \bottomrule" _n
		"\end{tabular}" _n 
		;  
 	#delimit cr
 	file close myfile 

 	// "The total number of switches exceeds those with information on premium prices due missing granularity." ///
	// "Table shows the contemporaneous effect interpretation." ///
	//	"Lead switches (forward t+1 interpretation) are analogously shifted backwards")



* 3) Control variable summary stats
* ---------------------------------------------------------------------------- * 

	* Recode variables for summary stats
	replace reported_sick = 0 if reported_sick==2
	gen health_worried2 = (health_worried==1)
	replace gender = (gender==2)
	replace married = (married==2)
	replace reported_sick = (reported_sick==1)

	* Initiate LaTeX table
	cap file close myfile 
	local date $date
	file open myfile using "$tables/SummaryStats/Individual/`date'_sum_soep_summarystats.tex", write replace

	* Table header
	#delimit ; 
		file write myfile
		"\begin{tabular*}{1\hsize}{@{\hskip\tabcolsep\extracolsep\fill}l | cccc | cccc}" _n
		"\toprule" _n 
		"& \multicolumn{4}{c |}{Sample of General Interest} & \multicolumn{4}{c}{Information on Switches} \\" _n 
		"& Mean & Median & SD & N & Mean & Median & SD & N \\ \midrule" _n
		; 
	#delimit cr

	* Summarize variable
	foreach var in 	age income_gross educ_years tertiary gender married  		///
					/*health_worried2 reported_sick*/ health_satisfaction		///
					doctor_visits {
	
		* Assign local
		if "`var'"=="age"					local tex_row = "Age"
		if "`var'"=="income_gross"			local tex_row = "Gross earnings"
		if "`var'"=="educ_years"			local tex_row = "Education (years)"
		if "`var'"=="tertiary"				local tex_row = "Tertiary degree"
		if "`var'"=="gender"				local tex_row = "Female"
		if "`var'"=="married"				local tex_row = "Married"
		if "`var'"=="health_satisfaction"	local tex_row = "Health satisfaction"
		if "`var'"=="health_worried2"		local tex_row = "Concerned with health"
		if "`var'"=="reported_sick"			local tex_row = "Reported sick"
		if "`var'"=="doctor_visits"			local tex_row = "Doctor visits"

		* Initiate sample condition (full & hi-switch-info sample)			
		forvalues j=1/2 {

			* Sample condition
			if `j'==1 	local sample = "pid!=."									// "hi_switch!=. & (info_l==. | info_l==1)"
			if `j'==2 	local sample = "hi_switch!=. & info_l==1"

			* Summarize variable of interest
			qui sum `var' if `sample' & year>=2015 & year<=2018, d
			
				* Mean
				if abs(`r(mean)') < 1 			local avg = trim("`: di %10.2fc `r(mean)''")
				else if abs(`r(mean)') < 10 	local avg = trim("`: di %10.1fc `r(mean)''")
				else if abs(`r(mean)') < 100	local avg = trim("`: di %10.1fc `r(mean)''")
				else 							local avg = trim("`: di %10.0fc `r(mean)''")

				* Median
				if abs(`r(p50)') < 1 		local med = trim("`: di %10.2fc `r(p50)''")
				else if abs(`r(p50)') < 10 	local med = trim("`: di %10.1fc `r(p50)''")
				else if abs(`r(p50)') < 100	local med = trim("`: di %10.1fc `r(p50)''")
				else 						local med = trim("`: di %10.0fc `r(p50)''")

				* SD
				if abs(`r(sd)') < 1 		local sd = trim("`: di %10.2fc `r(sd)''")
				else if abs(`r(sd)') < 10 	local sd = trim("`: di %10.1fc `r(sd)''")
				else if abs(`r(sd)') < 100	local sd = trim("`: di %10.1fc `r(sd)''")
				else 						local sd = trim("`: di %10.0fc `r(sd)''")

				* N 
				local N 		= trim("`: di %10.0fc `r(N)''")
				
			local tex_row 	= "`tex_row' & `avg' & `med' & `sd' & `N'"
	
		} // close loop j (sample condition)

		* Adjust row
		di "`tex_row'"
	
		* Add row to file
		file write myfile "`tex_row' \\ [2pt]" _n 

	} // close loop var 

	* Close table
	#delimit ; 
		file write myfile 
		"\bottomrule" _n 
		"\end{tabular*}"
		;
	#delimit cr
	file close myfile 



* Close log file 
cap log close 
