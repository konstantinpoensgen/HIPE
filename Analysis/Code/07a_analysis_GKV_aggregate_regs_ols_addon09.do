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
	2) OLS Regression analysis 2009-2014
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
log using "$logs_analysis/`date'_analysis_gkv_aggregate_regs_ols_addon09.log", text replace	


* ============================================================================ *
* 1) Data
* ============================================================================ *

* Load data
use "$data_final/GKV_aggregate", clear

* Set panel var
xtset id year


* ============================================================================ *
* 2) OLS Regression analysis 2009-2014 
* ============================================================================ *

* 2.1) Who charged add-on premiums or paid rebates?
* ---------------------------------------------------------------------------- *

	* How many entries with add-on or rebate between 2010 and 2014?
	tab addon09_dummy rebate09_dummy if year>=2009 & year<2015 & insured_lead_ln!=.
	
	* Which providers charged an absolute add-on premium AND we have enrollment information
	tab provider if addon09_dummy==1 & insured_lead_ln!=.
 

* 2.2) Table 3: Main results
* ---------------------------------------------------------------------------- *

* Sample specifications 
local sample1 = "if sample1==1"
local sample2 = "if sample2==1"

* Rename variables for easier regression loop
ren insured_lead_ln 	lnins 
ren insured_initial_ln 	iiln
ren rating_relative 	rr
ren addon09_dummy		ao 
ren rebate09_dummy 		re

* Generate sample tags
	
	* Sample 1 (Initial enrollment defined; clustered at provider level with provider Fe)
	qui reghdfe lnins ao re iiln  if year>=2009 & year<=2014, cluster(provider) absorb(provider year)
	gen sample1 = e(sample)

	* Sample 2 (Rating sample)
	qui reghdfe lnins ao re iiln rr if year>=2009 & year<=2014, cluster(provider) absorb(provider year)
	gen sample2 = e(sample)

* Initiate latex table rows
	
	* Additional information
	local FE_row_t	= "Provider-type FE"
	local FE_row_p	= "Provider FE"
	local FE_y 		= "Year FE"
	local mean_row 	= "Mean outcome"
	local N_row 	= "Observations" 
	local N_row_ins = "Number of insurers"

	* Locals for coefficients 
	foreach X in ao re rr illn {
		local row_b_`X' 	= ""
		local row_se_`x'	= ""
	}

* Initiate loop over regression specifications 
foreach y in lnins { 															// outcome variables
foreach fe in p t {																// fixed effects
forvalues v = 1/4 {																// version (= column)

	* Skip a specification? 
	if `v'==2 & "`fe'"=="p" continue 												// same as v==1 & fe==p

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

	* Set control variables depending on FE
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
	reghdfe lnins ao re `spec`j'' `sample`s'', cluster(provider) absorb(`FE' year)

	* Latex output 
	* ........................................................................ *

	* Number of observations
	local N 	= trim("`: di %10.0fc e(N)'")
	local N_row = "`N_row' & `N'"

	* Number of insurers
	local N_ins = trim("`: di %10.0fc e(N_clust)'")
	local N_row_ins = "`N_row_ins' & `N_ins'"

	* Coefficients & standard-errors
	foreach X in ao re iiln rr {

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
	qui sum `y' if e(sample)==1 
	local mean = trim("`: di %10.2fc `r(mean)''")
	local mean_row = "`mean_row' & `mean'"

	* Additional information
	local FE_row_t 	= "`FE_row_t' & `FE_t_text'"
	local FE_row_p 	= "`FE_row_p' & `FE_p_text'"
	local FE_y 		= "`FE_y' & Yes"

} // close loop `v'
} // close loop `fe'
} // close loop `y'


* Rename variables back
ren lnins insured_lead_ln 
ren iiln insured_initial_ln
ren rr rating_relative
ren ao addon09_dummy 
ren re rebate09_dummy

* Drop sample variables
drop sample1 sample2

*  Export regression table
capture file close myfile
local date = "$date"
file open myfile using "$tables/RegressionOutput/Aggregate/OLS09/`date'_Aggregate_reg_0914_baseline.tex", write replace

# delimit ;
file write myfile 		"\begin{tabular*}{1\hsize}{@{\hskip\tabcolsep\extracolsep\fill}l*{7}{c}}" _n
						"\toprule" _n 
						"& \multicolumn{3}{|c}{Provider Fixed Effects} & \multicolumn{4}{|c}{Provider Type Effects} \\" _n
						"{\footnotesize Outcome: Enrollment (log)} & \multicolumn{1}{|c}{(1)} & (2) & (3) & \multicolumn{1}{|c}{(4)} & (5) & (6) & (7) \\ \midrule" _n 
						"Add-on (dummy) `row_b_ao' \\" _n 
						"				`row_se_ao' \\ [6pt]" _n 
						"Rebate (dummy) `row_b_re' \\" _n 
						"				`row_se_re' \\ [6pt]" _n 
						"Rating  	`row_b_rr' \\" _n 
						"			`row_se_rr' \\ [6pt]" _n
						"Initial Enrollment (log) 	`row_b_iiln' \\" _n 
						"							`row_se_iiln' \\ [6pt] \midrule" _n 	
						"`FE_row_t' \\"  _n
						"`FE_row_p' \\" _n
						"`FE_y' \\ \midrule " _n
						"`mean_row' \\" _n 
						"`N_row' \\" _n
						"`N_row_ins' \\ \bottomrule" _n
						"\end{tabular*}"
 ;
# delimit cr
file close myfile


		
* 2.3) Table A.1: Additional specifiations 
* ---------------------------------------------------------------------------- *
 
	* Rename variables for eststo command									// alternatives: insured_change_perc_weighted, insured_change_abs
	ren insured_change_perc icp
	ren marketshare_change msc
	ren rating_relative rr
	ren addon09_dummy ao
	ren rebate09_dummy re

	* Sample identifiers
		
		* Non-rating sample
		reghdfe icp ao re if year>=2009 & year<2015, absorb(year provider) cluster(provider)
		gen sample1 = e(sample)

		* Rating sample
		reghdfe icp ao re rr if year>=2009 & year<2015, absorb(year provider) cluster(provider)
		gen sample2 = e(sample)
		gen sample3 = sample2 

	* Initiate latex rows

		* Additional information
		local FE_row_p	= "Provider FE"
		local FE_y 		= "Year FE"
		local mean_row 	= "Mean outcome"
		local N_row 	= "Observations" 
		local N_row_ins = "Number of insurers"

		* Locals for coefficients 
		foreach X in ao re rr {
			local row_b_`X' 	= ""
			local row_se_`X'	= ""
		}


* Initiate regression loop
foreach y in icp msc {
forvalues v = 1/3 {

	* Set control variable 
	if `v'==3 	local controls = "rr"
	else  		local controls = ""

	* Run regression
	* ..........................................................................
	reghdfe `y' ao re `controls' if year>=2009 & year<2015 & sample`v'==1 , absorb(year provider) cluster(provider)


	* Latex output 
	* ........................................................................ *

	* Number of observations
	local N 	= trim("`: di %10.0fc e(N)'")
	local N_row = "`N_row' & `N'"

	* Number of insurers
	local N_ins = trim("`: di %10.0fc e(N_clust)'")
	local N_row_ins = "`N_row_ins' & `N_ins'"

	* Coefficients & standard-errors
	foreach X in ao re rr {

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
	qui sum `y' if e(sample)==1 
	local mean = trim("`: di %10.2fc `r(mean)''")
	local mean_row = "`mean_row' & `mean'"

	* Additional information
	local FE_row_p 	= "`FE_row_p' & Yes"
	local FE_y 		= "`FE_y' & Yes"


} // close loop `y'
} // close loop `v'


	* Rename variables back 
	ren  icp insured_change_perc
	ren  msc marketshare_change
	ren  rr rating_relative
	ren  ao addon09_dummy
	ren  re rebate09_dummy

	* Drop sample identifiers
	drop sample1 sample2 sample3 

	*  Export regression table
	* ..........................................................................

	capture file close myfile
	local date = "$date"
	file open myfile using "$tables/RegressionOutput/Aggregate/OLS09/`date'_Aggregate_reg_0914_addlhs.tex", write replace

	# delimit ;
	file write myfile 		"\begin{tabular*}{1\hsize}{@{\hskip\tabcolsep\extracolsep\fill}l*{6}{c}}" _n
							"\toprule" _n 
							"& \multicolumn{3}{|c}{Enrollment Change (\%)} & \multicolumn{3}{|c}{Market Share Change (\%)} \\" _n
							"& \multicolumn{1}{|c}{(1)} & (2) & (3) & \multicolumn{1}{|c}{(4)} & (5) & (6) \\ \midrule" _n 
							"Add-on (dummy) `row_b_ao' \\" _n 
							"				`row_se_ao' \\ [6pt]" _n 
							"Rebate (dummy) `row_b_re' \\" _n 
							"				`row_se_re' \\ [6pt]" _n 
							"Rating  	`row_b_rr' \\" _n 
							"			`row_se_rr' \\ [6pt] \midrule" _n 
							"`FE_row_p' \\" _n
							"`FE_y' \\ \midrule " _n
							"`mean_row' \\" _n 
							"`N_row' \\" _n 
							"`N_row_ins' \\ \bottomrule" _n
							"\end{tabular*}"
	 ;
	# delimit cr
	file close myfile


* Close log file
cap log close _all
