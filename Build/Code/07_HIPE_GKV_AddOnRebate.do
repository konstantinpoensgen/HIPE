********************************************************************************
********************* GKV Add-on premium rebate 2009-2012 **********************
********************************************************************************
	
/* 	DATA
	Input: $data_input/Premium/ZB_2009_2012_Pendzialek.xlsx
	Output: $data_input/Premium/ZB_2009_2012_Pendzialek.dta
	
	DO-FILE OUTLINE 
	1) Load data 
	2) Save data
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
log using "$logs_build/`date'_HIPE_GKV_AddOnRebate.log", text replace	


* 1) Load data  
* ---------------------------------------------------------------------------- *	
	
	* Load data
	import excel using "$data_input/Premium/ZB_2009_2012_Pendzialek.xlsx", clear firstrow
	
	* Label variables
	label var addon_abs "Absolute add-on premium 2009-2012 (Pendzialek et al 2015)"
	label var addon_pct "Percentag add-on premium 2009-2012 (Pendzialek et al 2015"
	label var addon_dummy "Dummy = 1 if provider charged add-on premium in year 2009-2012 (Pendzialek et al 2015)"
	label var rebate_abs "Absolute rebate 2009-2012 (Pendzialek et al 2015"
	label var rebate_abs_dummy "Dummy = 1 if rebate paid in year 2009-2012 (Pendzialek et al 2015)"


* 2) Save data  
* ---------------------------------------------------------------------------- *	
	
	* Save data
	save "$data_input/Premium/ZB_2009_2012_Pendzialek.dta", replace
	
	
