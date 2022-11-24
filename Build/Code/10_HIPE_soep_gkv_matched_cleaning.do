********************************************************************************
*************************** SOEP & GKV MATCHED CLEANING ************************
********************************************************************************

/* 	OBJECTIVES
	- Saves a cleaned version of the SOEP-GKV matched data
	- Cleaning = applies sample conditions
	
	OUTLINE
	0) Preliminaries
	1) Data
	2) Sample selection
	3) Save cleaned data

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
log using "$logs_build/`date'_soep_gkv_matched_cleaning.log", text replace	


* 1) Data
* ---------------------------------------------------------------------------- *

* Load data
use "$data_final/soep_gkv_match.dta", clear

* 2) Sample selection -------------------------------------------------------- *

* Sample selection

	* Employment
	
		* Self-employment
		// Remove self-employment as much as possible with information from different surveys
		tab self_employment
			tab hi_switch if self_employment>0 									// XX KP: What to do with [-8] Question does not apply
			assert self_employment!=.			
			drop if self_employment>0
			
		tab occupation_position
			tab hi_switch if occupation_position>400 & occupation_position<500
			drop if occupation_position>400 & occupation_position<500	
			
		tab companysize
			drop if companysize==5
			
		* Employment status
		tab employment_status 													// all full-time employment
		assert employment_status==1

		// XX KP: Conduct separate analysis for students? 

		* sector/occupation
		tab nace 																// has better coverage than isco08
		tab isco08
		
	* Health insurance
	
		* Health insurance type
		tab hi_type
			tab hi_switch if hi_type==2 										// If PKV, then switched from GKV to PKC or switch missing
			// XX KP: There seem to be 19 PK with hi_switch==.
			//br pid year provider provider_l hi_switch hi_switch_lead if hi_type==2
			//br pid year provider provider_l hi_switch hi_switch_lead if pid==186404
	
		* Health insurance status
		tab hi_status 															// Compulsory member other few PKV 
		
		* Family co-insured PKV
		tab hi_pstatus
		drop if hi_pstatus==1 													// Drop co-insured family PKV member
		
	* Education
	
		* degree
		tab degree
			tab age if degree==1
	
		* Bafoeg
		tab age if plc0168_h>0 & plc0168_h!=.
		tab hi_switch if plc0168_h>0 & plc0168_h!=.
		assert plc0168_h!=.
		drop if plc0168_h>0 													// Drop if receives Bafoeg
		
		* currently receiving training
		tab plg0012
			tab age if plg0012==1 												// not clear that this is "in school"
			tab hi_switch if plg0012==1
			
	* Marital status
	tab married
	
	* Drop individuals with income below 800€ (see Schmitz and Ziebarth, 2017)
	drop if income_gross<800

* 3) Save cleaned data --------------------------------------------------------*

save "$data_final/soep_gkv_match_cleaned.dta", replace 

cap log close 
