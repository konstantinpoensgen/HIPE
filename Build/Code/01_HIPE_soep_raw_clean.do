********************************************************************************
************************ SOEP RAW DATA CLEANING ********************************
********************************************************************************

/*	Objectives:
	- Applies first cleaning to different raw data from SOEP v35
	- Stores cleaned versions as dta files in the temp folder

	Do-file outline:
	0) Preliminaries
	1) SOEP ppathl (individual identifier)
	2) SOEP hbrutto (household level)
	3) SOEP pbrutto (individual level)
	4) SOEP pgen (individual level) 
	5) SOEP health (individual level)
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
log using "$logs_build/`date'_HIPE_soep_raw_clean.log", text replace	
 	 

* 1) SOEP ppathl (individual identifier) 
* ---------------------------------------------------------------------------- *

	/* 	Objective: 
		Create a "base" personal id (pid) data set that will be used for 
		later merges
	*/	
	
*	Load raw individual identifiers (ppathl)
	use "$data_soep_v35/ppathl.dta", clear
	
*	General data checks	
	isid pid syear																// assert that data is unique on the individual-year level
	assert pid!=. & cid!=. & hid!=. & syear!=.

*	Keep relevant variables only
	keep 	cid hid pid syear sex gebjahr erstbefr austritt letztbef netto 		///
			todjahr todinfo immiyear germborn corigin gebmonat migback sexor 	///
			arefback parid partner piyear
	
* 	Keep relevant years only
	keep if syear>=2008
	
*	Consistency checks

	* Year of birth
	count if gebjahr>syear & !missing(gebjahr)									// it should not be possible to have data entries before being born
	assert r(N)==2 																
	drop if gebjahr>syear 
	
	* Austritt
	count if austritt < syear													// there should be no entries after one left the survey 
	assert r(N)==0
	
*	Data cleaning 

	* First time interviewed
	replace erstbefr=. if erstbefr==-2 											// "-2" is "does not apply" 

*	Export cleaned ppathl
	save "$data_temp/soep_ppathl_c.dta", replace

 	
* 2) SOEP hbrutto (household level)
* ---------------------------------------------------------------------------- *

*	Load raw hbrutto
	use "$data_soep_v35/hbrutto.dta", clear

*	Check data level
	isid hid syear 																// unique on household-year level

*	Keep relevant variables only
	keep hid syear htyp bula
	
*	Keep relevant years only
	keep if syear>=2008
	
*	Export "cleaned" (reduced) hbrutto
	save "$data_temp/soep_hbrutto_c.dta", replace
	
	
* 3) SOEP pbrutto (individual level)
* ---------------------------------------------------------------------------- *
	
*	Load SOEP individual pbrutto 
	use "$data_soep_v35/pbrutto.dta", clear
	
*	General checks
	isid pid syear 																// unique on person-year level
	assert pid!=. & cid!=. & hid!=. & syear!=.									// will be used in later merges

*	Keep relevant year span only
	keep if syear>=2008
	
*	Keep relevant variables only
	keep 	abwesj_h auszugj_h	befstat	cid	dj einzugj_h geburt_v2				/// 
			hhnrold	hid	hk inputdataset	kogzahl	lint_h monin panker				///
			pherkft	pid	pnat_h pnat2 pnrneu	pzug sex stell_h stistat 			///
			syear tagin varpnat1 varpnat2 varsex zupan_h

*	Cleaning
	
	* Age of birth
	drop if geburt_v2>syear

*	Export cleaned pbrutto
	save "$data_temp/soep_pbrutto_c.dta", replace
	
	
* 4) SOEP pgen (individual level) 
* ---------------------------------------------------------------------------- *

*	Load SOEP individual pgen
	use "$data_soep_v35/pgen.dta", clear
	label language EN

*	General checks
	isid pid syear 																// unique on person-year level
	assert pid!=. & syear!=.

*	Relevant year range
	keep if syear>=2008

*	Export cleaned pgen
	save "$data_temp/soep_pgen_c.dta", replace
 

*  5) SOEP health (individual level)
* ---------------------------------------------------------------------------- *

*	Load data
	use $data_soep_v35/health.dta, clear
	
*	Consistency checks
	isid pid syear 
	isid pid cid syear
	assert pid!=. & cid!=. & syear!=.

	// no further checks required at this step

		
* SCRIPT END 
* ---------------------------------------------------------------------------- *

* Close log file 
log close
