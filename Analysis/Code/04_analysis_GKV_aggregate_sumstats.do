********************************************************************************
************************ GKV AGGREGATE - SUM STATS *****************************
********************************************************************************

/* 	OBJECTIVES
	- Create summary stats on GKV on aggregate level

	OUTLINE
	0) Preliminaries 
	1) Data
	2) Summary statistics and output

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
log using "$logs_analysis/`date'_analysis_gkv_aggregate_sumstats.log", text replace	


* 1) Data
* ---------------------------------------------------------------------------- *

* Load data
use "$data_final/GKV_aggregate", clear

* Set panel var
xtset id year


* 2) Summary statistics and output
* ---------------------------------------------------------------------------- *

* Set locals with variables
local insured 	= "insured insured_change_abs insured_change_perc"
local rechnung 	= "members revenue_pc revenue_fund_pc revenue_addon_pc expenditure_pc expenditure_admin_pc capital_reserves_pc"
local addon 	= "addon09_dummy addon09_abs rebate09_dummy rebate09_abs addon addon_change"
local rating 	= "rating_relative service_relative"

* Adjust variables for scale 
replace insured = insured/1000 
replace insured_change_abs = insured_change_abs/1000
replace members = members/1000

* Replace variables with missing for non-relevant years
foreach var in addon09_abs addon09_dummy rebate09_dummy rebate09_abs {
	replace `var' = . if year>2014
}

* Summarize & add to latex row
foreach var in `insured' `rechnung' `addon' `rating' {

	* Summary
	sum `var' if year>=2015 & year<=2018, d

	* Format stat
	foreach stat in mean p50 sd min max N {

		if abs(r(`stat')) < 1 								local `stat' = trim("`: di %10.2fc `r(`stat')''")
		else if abs(r(`stat')) < 100 & abs(r(`stat')) >= 1	local `stat' = trim("`: di %10.1fc `r(`stat')''")
		else												local `stat' = trim("`: di %10.0fc `r(`stat')''")
	}

	* Write tex_row
	local r_`var' = "`mean' & `p50' & `sd' & `min' & `max' & `r(N)'"
	di "`r_`var''"
}


* Write Latex table
capture file close myfile
local date = "$date"
file open myfile using "$tables/SummaryStats/Aggregate/`date'_sum_GKV_aggregate_joint.tex", write replace

# delimit ;
file write myfile 		"\begin{tabular*}{1\hsize}{@{\hskip\tabcolsep\extracolsep\fill}l*{6}{c}}" _n
						"\toprule" _n 
						"& Mean & Median & SD & Min & Max & N \\ \midrule" _n 
						"\multicolumn{7}{l}{\textbf{\textit{Panel (a): Membership}}} \\"
						"Enrollment (thousands) 			& `r_insured' \\ [3pt]" _n
						"$\Delta$ Enrollment (thousands) 	& `r_insured_change_abs' \\ [3pt]" _n 
						"$\Delta$ Enrollment (\%)			& `r_insured_change_perc' \\ [3pt]" _n 
						"Paying Members	(thousands)			& `r_members' \\ [6pt]" _n 
						"\multicolumn{7}{l}{\textbf{\textit{Panel (b): Financial Information}}} \\ [3pt]" _n 
						"Revenue from health fund (pc) 		& `r_revenue_fund_pc' \\ [3pt]" _n
						"Expenditure (pc) 					& `r_expenditure_pc' \\ [3pt]" _n 
						"Administrative costs (pc)			& `r_expenditure_admin_pc' \\ [6pt]" _n 
						"\multicolumn{7}{l}{\textbf{\textit{Panel (c): Premiums}}} \\" _n 
						"Percentage Add-On (pp.)			& `r_addon' \\ [3pt]" _n 
						"$\Delta$ Percentage Add-On (pp.)	& `r_addon_change' \\ [6pt] " _n 
						"\multicolumn{7}{l}{\textbf{\textit{Panel (d): Ratings}}} \\ [3pt]" _n 
						"Rating 						& `r_rating_relative' \\ [3pt] \bottomrule" _n 
						"\end{tabular*}"				
;
# delimit cr
file close myfile



* Close log file
cap log close
