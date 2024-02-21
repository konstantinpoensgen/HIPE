* HIPE Folder Declare
* Created on August 29, 2021

* ============================================================================ *

* Set version
version 15

* CLEAR WORKSPACE
cap log close _all																
clear all																																		
macro drop _all																	
cls

* SET VALUES FOR IMPORTANT STATA OPTIONS 																			
set more off, permanently 														
set varabbrev off, permanently													
set mem 500m																	
set matsize 1000		
set maxvar 32767	

* DATE
local  date : di %tdYYNNDD date(c(current_date),"DMY")
global date = "`date'"

* Set user
local username = c(username)
di 	"`username'"
if "`username'" == "kpoens"  					local user "C:/Users/`username'"
else if "`username'" == "konstantinpoensgen" 	local user "/Users/konstantinpoensgen/Library/CloudStorage"
else local user "`username'"

* Project directory
global hipe					"`user'/Dropbox/Research/HIPE"

* Building files
global build 				"$hipe/Build"
global logs_build 			"$build/Logs"
global build_code			"$build/Code"
global data 				"$build/Data"
global data_input			"$data/Input"
global data_intermediate	"$data/Intermediate"
global data_final			"$data/Final"
global data_temp			"$data/Temp"
global data_soep			"$data_input/SOEP"
global data_soep_v35		"$data_soep/soep.v35.international.stata_dta"

* Analysis files
global analysis 			"$hipe/Analysis"
global logs_analysis		"$analysis/Logs"
global analysis_code 		"$analysis/Code" 	
global figures 				"$analysis/Figures"
global tables 				"$analysis/Tables"
global intext 				"$analysis/Intext"
	
	
* Global graphing settings
set scheme s1color	

