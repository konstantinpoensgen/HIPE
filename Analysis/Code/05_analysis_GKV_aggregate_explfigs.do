********************************************************************************
******************* GKV AGGREGATE - EXPLORATIVE FIGURES ************************
********************************************************************************

/* 	OBJECTIVES
	

	OUTLINE
	0) Preliminaries 
	1) Data
	2) Figures

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
log using "$logs_analysis/`date'_analysis_gkv_aggregate_explfigs.log", text replace	


* 1) Data
* ---------------------------------------------------------------------------- *

* Load data
use "$data_final/GKV_aggregate", clear

* Set panel var
xtset id year


* 2) Figures 
* ---------------------------------------------------------------------------- *

* Add-on premium and absolute change in insured individuals
local date $date
foreach xvar in addon addon_change addon_diff_avg addon_diff_predicted {
	foreach yvar in insured_change_abs insured_change_perc {

	* no outlier treatment
	graph twoway (scatter `yvar' `xvar') ///
		(lfit `yvar' `xvar') if year>=2015 & year<=2018 ///
		, legend(off) title("`yvar' and `xvar'") ///
			subtitle("Pooled over 2015-2018") ytitle() ///
			ylab( ,labsize(2.5)) yline(0, lstyle(major_grid)) xline(0, lstyle(major_grid)) 
	graph export "$figures/Exploratory/GKV_aggregate_addon_relationships/`date'_`xvar'_`yvar'.png", replace
	
	* exclude top and bottom 1% tail
	sum `yvar', d
		preserve
			keep if `yvar'<=r(p99) & `yvar'>=r(p1)
			
			graph twoway (scatter `yvar' `xvar') ///
				(lfit `yvar' `xvar') if year>=2015 & year<=2018 ///
				, legend(off) title("`yvar' and `xvar'") ///
					subtitle("Pooled over 2015-2018") ytitle() ///
					ylab( ,labsize(2.5)) ///
					yline(0, lstyle(major_grid)) xline(0, lstyle(major_grid)) 
			graph export "$figures/Exploratory/GKV_aggregate_addon_relationships/`date'_`xvar'_`yvar'_nooutlier.png", replace
	
		restore
	}
}	

* Close log file
cap log close
