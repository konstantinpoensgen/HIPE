********************************************************************************
*********************** GKV AGGREGATE - REGRESSIONS ****************************
********************************************************************************

/* 	OBJECTIVES
	Run the OLS regressions on the aggregate level for 
	(i) 2009--2014
	(ii) 2015--2018

	OUTLINE
	0) Preliminaries
	1) Data
	2) OLS Regression analysis 2015-2018
*/


* 0) Preliminaries 
* ---------------------------------------------------------------------------- *
cap log close 
clear all
eststo clear

* Set user
local username = c(username)
di 	"`username'"
if "`username'" == "kpoens"  local path "C:/Users/`username'/Dropbox/Research/HIPE"

* Run folder declare
do "`path'/HIPE_folder_declare.do" 

* Open log file 
local date "$date"
log using "$logs_analysis/`date'_analysis_gkv_aggregate_regs_ols_addon15.log", text replace	


* ============================================================================ *
* 1) Data
* ============================================================================ *

* Load data
use "$data_final/GKV_aggregate", clear

* Set panel var
xtset id year
	
* ============================================================================ *
* 3) Aggregate OLS Regression analysis 2015-2018 
* ============================================================================ *
foreach end_rhs in addon premium_ln {

	di "-----------------------------------------------------------------------"
	di "Now running: `end_rhs'"
	di "-----------------------------------------------------------------------"

	* 3.1) OLS Regression analysis 2015-2018
	* ------------------------------------------------------------------------ *

	* Set administrative cost variable 
	if "`end_rhs'"=="addon" 		local Z_var "expenditure_admin_pc"
	if "`end_rhs'"=="premium_ln" 	local Z_var "expenditure_admin_pc_ln"

	* Adjust variables for loop
	ren insured_lead_ln illn
	ren `end_rhs' ao
	ren rating_relative_ln rr
	ren insured_initial_ln iiln 
	ren `Z_var' Z 

	* Estimation samples 
	
		* Full sample
		cap drop sample*
		reghdfe illn ao iiln if year>=2015 & year<=2018, absorb(provider year) cluster(provider)
		gen sample1=e(sample)
		local sample1 = "if sample1==1"

		* Rating sample (include admin pc restriction)
		reghdfe illn ao iiln rr if year>=2015 & year<=2018 & Z!=., absorb(provider year) cluster(provider)
		gen sample2=e(sample)
		local sample2 = "if sample2==1"

	* Initiate latex rows

		* Additional information
		local FE_row_t 	= "Provider-type FE"
		local FE_row_p	= "Provider FE"
		local FE_y 		= "Year FE"
		local N_row 	= "Observations"
		local N_ins_row = "Number of insurers" 
		local mean_row 	= "Mean outcome"

		* Locals for coefficients 
		foreach X in ao iiln rr {
			local row_b_`X' 	= ""
			local row_se_`X'	= ""
		}

	* Initiate regression loop 
	foreach fe in t p {
	forvalues v = 1/4 {

		* Skip a specification? 
		if `v'==2 & "`fe'"=="p" continue 											// same as v==1 & fe==p

		* Set FE 
		if "`fe'"=="t"	{
			local FE 		= "type"
			local FE_t_text = "Yes"
			local FE_p_text = "No"
		}

		else if "`fe'"=="p"	{
			local FE 		= "provider"
			local FE_t_text = "No"
			local FE_p_text = "Yes"
		}
				
		* Set control variables depending on FE
		if "`fe'"=="t" {
			local spec1 = ""
			local spec2 = "iiln"
			local spec3 = "iiln rr"
		}

		if "`fe'"=="p" {
			local spec1 = ""
			local spec2 = ""
			local spec3 = "rr"
		}

		* Set specification
			
			* no controls (spec1) - initial_insured sample (sample1)
			if `v' == 1 {
				/* spec */ 		local j = 1 
				/* sample */ 	local s = 1
			}

			* initial_insured control (spec2) - initial_insured sample (sample1)
			else if `v' == 2 {
				/* spec */ 		local j = 2 
				/* sample */ 	local s = 1
			}

			* initial insured control (spec2) - rating sample  (sample2)
			else if `v' == 3 {
				/* spec */ 		local j = 2 
				/* sample */ 	local s = 2
			}

			* rating control (spec3) - rating sample (sample2)
			else if `v' == 4 {
				/* spec */ 		local j = 3 
				/* sample */ 	local s = 2
			}

			else  {
				di as error "Not an appropriate version"
				stop
			}


		* Run regression 
		reghdfe illn ao `spec`j'' `sample`s'', cluster(provider) absorb(`FE' year)

		* Latex output 
		* ........................................................................ *

		* Number of observations
		local N 	= trim("`: di %10.0fc e(N)'")
		local N_row = "`N_row' & `N'"

		* Number of insurers
		local N_ins = trim("`: di %10.0fc e(N_clust)'")
		local N_ins_row = "`N_ins_row' & `N_ins'"

		* Coefficients & standard-errors
		foreach X in ao iiln rr {

			* Is the coefficient available?
			cap di _b[`X']

			* No? 
			if _rc {
				local row_b_`X'		= "`row_b_`X'' & "
				local row_se_`X'	= "`row_se_`X'' & "
			}

			else {
				* Assign point estimate and SE
				local coef 	= trim("`: display %10.3fc _b[`X']'")
				local se	= trim("`: display %10.3fc _se[`X']'")

				* Format with stars
				local p 	= 2 * ttail(e(df_r), abs(_b[`X']/_se[`X']))
				local st	= cond(`p'<.001,"***",cond(`p'<.01,"**",cond(`p'<.05,"*","")))
				
				* Format 
				local coef 	= "`coef'`st'" 
				local se 	= "(`se')"

				* Add to latex row  
				local row_b_`X'		= "`row_b_`X'' & `coef'"
				local row_se_`X'	= "`row_se_`X'' & `se'"
			}
		}

		* Sample mean
		qui sum illn if e(sample)==1 
		local mean = trim("`: di %10.2fc `r(mean)''")
		local mean_row = "`mean_row' & `mean'"

		* Additional information
		local FE_row_t 	= "`FE_row_t' & `FE_t_text'"
		local FE_row_p 	= "`FE_row_p' & `FE_p_text'"
		local FE_y 		= "`FE_y' & Yes"

	} // close loop `v'
	} // close loop `fe'

	* Rename variables back 
	ren illn insured_lead_ln
	ren ao `end_rhs'
	ren rr rating_relative_ln
	ren iiln insured_initial_ln 
	ren Z `Z_var'

	* Drop sample identifiers
	drop sample*

	*  Export regression table
	* ..........................................................................

	if "`end_rhs'"=="addon"			local text_ao = "Add-on (pp.)"
	if "`end_rhs'"=="premium_ln"	local text_ao = "Premium (log)"

	capture file close myfile
	local date = "$date"
	file open myfile using "$tables/RegressionOutput/Aggregate/OLS15/`date'_Aggregate_reg_1518_baseline_`end_rhs'.tex", write replace

	# delimit ;
	file write myfile 		"\begin{tabular*}{1\hsize}{@{\hskip\tabcolsep\extracolsep\fill}l*{7}{c}}" _n
							"\toprule" _n 
							"& \multicolumn{4}{|c}{Provider Type Fixed Effects} & \multicolumn{3}{|c}{Provider Fixed Effects} \\" _n
							"{\footnotesize Outcome: Enrollment (log)} & \multicolumn{1}{|c}{(1)} & (2) & (3) & (4) & \multicolumn{1}{|c}{(5)} & (6) & (7) \\ \midrule" _n 
							"`text_ao' `row_b_ao' \\" _n 
							"				`row_se_ao' \\ [6pt]" _n 
							"Initial enrollment (log) 	`row_b_iiln' \\" _n 
							"							`row_se_iiln' \\ [6pt]" _n
							"Rating  	`row_b_rr' \\" _n 
							"			`row_se_rr' \\ [6pt] \midrule" _n  
							"`FE_row_t' \\" _n
							"`FE_row_p' \\" _n
							"`FE_y' \\ \midrule " _n
							"`mean_row' \\" _n 
							"`N_row' \\" 
							"`N_ins_row' \\ \bottomrule" _n 
							"\end{tabular*}"
	;
	# delimit cr
	file close myfile

} // close loop `end_rhs'

	
* 3.2) Table A.2: Alternative Dependent Variables 
* ---------------------------------------------------------------------------- *
foreach end_rhs in addon premium_ln {

	* Rename variables for eststo command									// alternatives: insured_change_perc_weighted, insured_change_abs
	ren insured_change_abs ica 
	ren insured_change_perc icp
	ren marketshare_change msc
	ren `end_rhs' ao
	ren rating_relative_ln rr
	ren insured_initial_ln iiln

	* Adjust scale of variables
	replace ica = ica/1000

	* Sample identifiers
		
		* Non-rating sample
		cap drop sample*
		reghdfe ica ao rr iiln if year>=2015 & year<=2018, absorb(year provider) cluster(provider)
		gen sample1 = e(sample)

	* Initiate latex rows

		* Additional information
		local FE_row_t	= "Provider-type FE"
		local FE_row_p	= "Provider FE"
		local FE_y 		= "Year FE"
		local mean_row 	= "Mean outcome"
		local N_row 	= "Observations" 
		local N_ins_row = "Number of insurers"

		* Locals for coefficients 
		foreach X in ao rr iiln {
			local row_b_`X' 	= ""
			local row_se_`X'	= ""
		}

	* Initiate regression loop
	foreach y in ica icp msc {
	forvalues v = 1/2 {

		* Set control variable 
		if `v'==1 	local controls = ""
		else  		local controls = "iiln"

		* Set fixed effect
		if `v'==1 	local FE = "provider"
		else 		local FE = "type"	

		* Run regression
		* ......................................................................
		reghdfe `y' ao rr `controls' if year>=2015 & year<=2018 & sample1==1, absorb(year `FE') cluster(provider)

		* Latex output 
		* ......................................................................

		* Number of observations
		local N 	= trim("`: di %10.0fc e(N)'")
		local N_row = "`N_row' & `N'"

		* Number of insurers
		local N_ins = trim("`: di %10.0fc e(N_clust)'")
		local N_ins_row = "`N_ins_row' & `N_ins'"

		* Coefficients & standard-errors
		foreach X in ao rr iiln {

			* Is the coefficient available?
			cap di _b[`X']

			* No? 
			if _rc {
				local row_b_`X'		= "`row_b_`X'' & "
				local row_se_`X'	= "`row_se_`X'' & "
			}

			else {
				* Assign point estimate and SE
				local coef 	= trim("`: display %10.3fc _b[`X']'")
				local se	= trim("`: display %10.3fc _se[`X']'")

				if abs(_b[`X']) > 9 	local coef = trim("`: di %10.1fc `coef''")
				if abs(_se[`X']) > 9 	local se = trim("`: di %10.1fc `se''")

				* Format with stars
				local p 	= 2 * ttail(e(df_r), abs(_b[`X']/_se[`X']))
				local st	= cond(`p'<.001,"***",cond(`p'<.01,"**",cond(`p'<.05,"*","")))
				
				* Format 
				local coef 	= "`coef'`st'" 
				local se 	= "(`se')"

				* Add to latex row  
				local row_b_`X'		= "`row_b_`X'' & `coef'"
				local row_se_`X'	= "`row_se_`X'' & `se'"
			}
		}

		* Sample mean
		qui sum `y' if e(sample)==1 
		local mean = trim("`: di %10.2fc `r(mean)''")
		local mean_row = "`mean_row' & `mean'"

		* Additional information
		if `v'==1 {
			local FE_row_p 	= "`FE_row_p' & Yes"
			local FE_row_t 	= "`FE_row_t' & No"
		}
		if `v'==2 {
			local FE_row_p 	= "`FE_row_p' & No"
			local FE_row_t 	= "`FE_row_t' & Yes"
		}

		local FE_y 		= "`FE_y' & Yes"

	} // close loop `y'
	} // close loop `v'

	* Re-adjust scale of variables 
	replace ica = ica*1000
	
	* Rename variables back
	ren ica insured_change_abs 
	ren icp insured_change_perc
	ren msc marketshare_change
	ren ao `end_rhs'   
	ren rr rating_relative_ln
	ren iiln insured_initial_ln

	* Drop sample identifiers
	drop sample*

	*  Export regression table
	* ..........................................................................

	if "`end_rhs'"=="addon"			local text_ao = "Add-on (pp.)"
	if "`end_rhs'"=="premium_ln"	local text_ao = "Premium (log)"

	capture file close myfile
	local date = "$date"
	file open myfile using "$tables/RegressionOutput/Aggregate/OLS15/`date'_Aggregate_reg_1518_addlhs_`end_rhs'.tex", write replace

	# delimit ;
	file write myfile 		"\begin{tabular}{l cc cc cc}" _n
							"\toprule" _n 
							"& \multicolumn{2}{|c}{Enrollment Change (abs.)} & \multicolumn{2}{|c}{Enrollment Change (\%)} & \multicolumn{2}{|c}{Market Share Change (\%)}  \\" _n
							"& \multicolumn{1}{|c}{(1)} & (2) & \multicolumn{1}{|c}{(3)} & (4) & \multicolumn{1}{|c}{(5)} & (6) \\ \midrule" _n 
							" `text_ao' 	`row_b_ao' \\" _n 
							"				`row_se_ao' \\ [6pt]" _n 
							"Rating  	`row_b_rr' \\" _n 
							"			`row_se_rr' \\ [6pt]" _n 
							"Initial enrollment (log)  	`row_b_iiln' \\" _n 
							"							`row_se_iiln' \\ [6pt] \midrule" _n 
							"`FE_row_p' \\" _n
							"`FE_row_t' \\" _n
							"`FE_y' \\ \midrule " _n
							"`mean_row' \\" _n 
							"`N_row' \\" _n 
							"`N_ins_row' \\ \bottomrule" _n 
							"\end{tabular}"
	;
	# delimit cr
	file close myfile

} // close loop `end_rhs'


* 3.3) Table C.1: Alternative Explanatory Variables
* ---------------------------------------------------------------------------- *

	* Rename variables for eststo command									// alternatives: insured_change_perc_weighted, insured_change_abs 
	ren insured_lead_ln illn 
	ren insured_change_perc icp
	ren marketshare_change msc
	ren addon_ln aoln
	ren addon_change aoc
	ren rating_relative_ln rr

	* Sample identifiers
		
		* Non-rating sample
		cap drop sample*
		reghdfe illn aoc rr if year>=2015 & year<=2018, absorb(year provider) cluster(provider)
		gen sample1 = e(sample)

	* Initiate latex rows

		* Additional information
		local FE_row_p	= "Provider FE"
		local FE_y 		= "Year FE"
		local mean_row 	= "Mean outcome"
		local N_row 	= "Observations" 
		local N_ins_row = "Number of insurers"

		* Locals for coefficients 
		foreach X in ao rr iiln {
			local row_b_`X' 	= ""
			local row_se_`X'	= ""
		}


* Initiate regression loop
foreach y in illn icp msc {
foreach z in aoln aoc  {

	* Run regression
	* ..........................................................................
	reghdfe `y' `z' rr if year>=2015 & year<=2018 & sample1==1, absorb(year provider) cluster(provider)

	* Latex output 
	* ........................................................................ *

	* Number of observations
	local N 	= trim("`: di %10.0fc e(N)'")
	local N_row = "`N_row' & `N'"

	* Number of insurers
	local N_ins = trim("`: di %10.0fc e(N_clust)'")
	local N_ins_row = "`N_ins_row' & `N_ins'"

	* Coefficients & standard-errors
	foreach X in aoln aoc rr {

		* Is the coefficient available?
		cap di _b[`X']

		* No? 
		if _rc {
			local row_b_`X'		= "`row_b_`X'' & "
			local row_se_`X'	= "`row_se_`X'' & "
		}

		else {
			* Assign point estimate and SE
			local coef 	= trim("`: display %10.3fc _b[`X']'")
			local se	= trim("`: display %10.3fc _se[`X']'")

			* Adjustment 
			if "`X'"=="aoc" & "`y'"=="illn" local coef = trim("`: di %10.3fc -abs(`coef')'") 

			* Format with stars
			local p 	= 2 * ttail(e(df_r), abs(_b[`X']/_se[`X']))
			local st	= cond(`p'<.001,"***",cond(`p'<.01,"**",cond(`p'<.05,"*","")))
			
			* Format 
			local coef 	= "`coef'`st'" 
			local se 	= "(`se')"

			* Add to latex row  
			local row_b_`X'		= "`row_b_`X'' & `coef'"
			local row_se_`X'	= "`row_se_`X'' & `se'"
		}
	}

	* Sample mean
	qui sum `y' if e(sample)==1 
	local mean = trim("`: di %10.2fc `r(mean)''")
	local mean_row = "`mean_row' & `mean'"

	* Additional information
	local FE_row_p 	= "`FE_row_p' & Yes"
	local FE_y 		= "`FE_y' & Yes"

} // close loop `y'
} // close loop `v'

	* Rename variables back 
	ren illn insured_lead_ln 
	ren icp insured_change_perc
	ren msc marketshare_change
	ren aoln addon_ln
	ren rr rating_relative_ln

	* Drop sample identifiers
	drop sample*

	*  Export regression table
	* ..........................................................................

	capture file close myfile
	local date = "$date"
	file open myfile using "$tables/RegressionOutput/Aggregate/OLS15/`date'_Aggregate_reg_1518_addrhs.tex", write replace

	# delimit ;
	file write myfile 		"\begin{tabular*}{1\hsize}{@{\hskip\tabcolsep\extracolsep\fill}l*{7}{c}}" _n
							"\toprule" _n 
							"& \multicolumn{2}{|c}{Enrollment (log)} & \multicolumn{2}{|c}{Enrollment Change (\%)} & \multicolumn{2}{|c}{Market Share Change (\%)}  \\" _n
							"& \multicolumn{1}{|c}{(1)} & (2) & \multicolumn{1}{|c}{(3)} & (4) & \multicolumn{1}{|c}{(5)} & (6) \\ \midrule" _n 
							"Add-on (log) 	`row_b_aoln' \\" _n 
							"				`row_se_aoln' \\ [6pt]" _n 
							"$\Delta$ Add-on (pp.) 	`row_b_aoc' \\" _n 
							"						`row_se_aoc' \\ [6pt]" _n 
							"Rating  	`row_b_rr' \\" _n 
							"			`row_se_rr' \\ [6pt] \midrule" _n 
							"`FE_row_p' \\" _n
							"`FE_y' \\ \midrule " _n
							"`mean_row' \\" _n 
							"`N_row' \\" _n 
							"`N_ins_row' \\ \bottomrule" _n 
							"\end{tabular*}"
	;
	# delimit cr
	file close myfile


* Close log file
cap log close _all
