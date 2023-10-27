********************************************************************************
************************* GKV Add-On Premium 2015-2021 *************************
********************************************************************************

/*	Data
	Input: $data_input/Premium/GKV_Spitzenverband_ZB.xlsx
	Output: $data_input/Premium/GKV_Spitzenverband_ZB.dta

	Do-file outline
	1) Load data
	2) Data cleaning
	3) Save data
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
log using "$logs_build/`date'_HIPE_GKV_AddOnPremium.log", text replace		


* 1) Load data
* ---------------------------------------------------------------------------- *
	
	* Load data
	import excel "$data_input/Premium/GKV_Spitzenverband_ZB.xlsx", clear firstrow

	* Reshape wide to long
	drop if provider==""
	duplicates report provider
	reshape long addon, i(provider merge_date type) j(yearmonth)
	

* 2) Data cleaning
* ---------------------------------------------------------------------------- *	

	* Rename type 
	rename type gkv_type
	
	* Generate provider id
	cap drop id
	encode provider, gen(id)
	
	* Date variables
		
		* Create additional year variable
		tostring yearmonth, replace format(%20.0f)
		gen year = substr(yearmonth,1,4)
		destring year, replace
			
		* Change yearmonth to date format
			cap drop date
			gen date = "01" + yearmonth
		
				cap drop date2
				gen date2 = date(date, "DYM")
				format date2 %td
				
				cap drop date yearmonth
				rename date2 date
			
	* Calculate average add-on premium per year and provider
	rename addon addon_month
	drop if addon_month==.
	egen addon = mean(addon_month), by(provider year)
	
	* Keep one entry for each provider only
		
		* Generate count variable
		cap drop count
		bysort provider year: gen count = _n
		
		* Keep one entry only
		keep if count==1
		drop count
		
		* Drop entries without information
		drop if addon==.
	
	* Generate additional variables
		
		* Set panel structure
		xtset id year

		* Add-on change to prior year
			
			// Lagged add-on
			cap drop addon_l
			gen addon_l = l.addon
			replace addon_l = 0.9 if year==2015 // Note: Treat 2014 as if had 2014 add-on premium
			
			// Change to prior year
			cap drop addon_change
			gen addon_change = addon - addon_l
			
		* Difference to average add-on (realized)
		
			// Calculate average over all providers
			cap drop addon_avg 
			egen addon_avg = mean(addon), by(year)
			egen addon_med = median(addon), by(year)
			table year, c(mean addon)
			
			// Add-on difference to market average
			cap drop addon_diff_avg
			gen addon_diff_avg = addon - addon_avg

			// Add-on difference to market median
			cap drop addon_diff_med
			gen addon_diff_med = addon - addon_med 
			
		* Predicted add-on premium by BMG
			
			// BMG addon predictions
			cap drop addon_predicted
			gen addon_predicted = .
				replace addon_predicted = 0.9 if year==2015
				replace addon_predicted = 1.1 if year==2016
				replace addon_predicted = 1.1 if year==2017
				replace addon_predicted = 1.0 if year==2018
				replace addon_predicted = 0.9 if year==2019
				replace addon_predicted = 1.1 if year==2020
				replace addon_predicted = 1.3 if year==2021
			
			// Add-on difference to BMG prediction
			cap drop addon_diff_predicted
			gen addon_diff_predicted = addon - addon_predicted 

		* Total premium 

			* General contribution rate
			gen contribution = . 
			replace contribution = 14.9 if year==2009 | year==2010 
			replace contribution = 15.5 if year>=2011 & year<=2014
			replace contribution = 14.6 if year>=2015 & year<=2018

			* Full premium
			gen premium = contribution + addon if addon!=.
			
		* Group in below/at/above average
		
			// Distribution of addon difference to market average
			*histogram addon_diff_avg, width(0.1) normal
			sum addon_diff_avg, d 												// standard deviation of 0.3
			local diff_sd = `r(sd)'
		
			// Generate plain group variable by year
			cap drop addon_group_year 
			gen addon_group_year = 2 // default is "average"
				
				replace addon_group_year = 1 if addon_diff_avg < -0.3
				replace addon_group_year = 3 if addon_diff_avg > 0.3 
				replace addon_group_year = . if year>2018 						// since only analyze until 2018
			
			// Label values
			label define addon_group_label 1 "Below average" 2 "Average" 3 "Above average", replace
			label values addon_group_year addon_group_label
			
			// How consistent can providers be allocated?
			cap drop addon_group_fixed
			egen addon_group_fixed = mean(addon_group_year), by(provider)
			
			// Assign to fixed groups (2015--2018) 
			replace addon_group_fixed = 1 if addon_group_fixed <= 1.25
			replace addon_group_fixed = 2 if addon_group_fixed >= 1.75 & addon_group_fixed <= 2.25
			replace addon_group_fixed = 3 if addon_group_fixed >= 2.75
			replace addon_group_fixed = . if addon_group_fixed!=1 & addon_group_fixed!=2 & addon_group_fixed!=3
			
			// What's the respective group size?
			tab addon_group_fixed
			
			label values addon_group_fixed addon_group_label

		* Group in below/at/above median

			* Distribution of addon difference to median
			sum addon_diff_med, d
			local diff_med_p25 = `r(p25)'
			local diff_med_p75 = `r(p75)'

			* Generate group-year variable
			cap drop addon_med_group_year
			gen addon_med_group_year = 2 if year>=2015 & year<=2018				// default is "median"

				replace addon_med_group_year = 1 if addon_diff_med <= `diff_med_p25'
				replace addon_med_group_year = 3 if addon_diff_med >= `diff_med_p75'

			* Consistent within provider across years
			egen addon_med_group_fixed = mean(addon_med_group_year), by(provider)

				tab addon_med_group_fixed

				replace addon_med_group_fixed = 1 if addon_med_group_fixed <= 1.5
				replace addon_med_group_fixed = 2 if addon_med_group_fixed>= 1.75 & addon_med_group_fixed < 2.25
				replace addon_med_group_fixed = 3 if addon_med_group_fixed>=2.5
				replace addon_med_group_fixed = . if addon_med_group_fixed!=1 & addon_med_group_fixed!=2 & addon_med_group_fixed!=3
				tab addon_med_group_fixed		

	* Keep relevant variables only
	keep provider gkv_type year premium addon merge_date addon_change addon_diff_avg 	///
		addon_diff_predicted addon_avg addon_predicted addon_group_fixed 		///
		addon_med_group_fixed addon_group_year
	order provider gkv_type year premium addon addon_change addon_diff_avg ///
		addon_diff_predicted addon_group_fixed addon_group_year ///
		addon_avg addon_predicted merge_date
		
		
	* Label variables
	label var provider "Name of health insurance provider"
	label var year "Year"
	label var addon "Add-on premium by provider in year"
	label var addon_change "Change in add-on premium to prior year"
	label var addon_diff_avg "Add-on premium difference to average premium in year"
	label var addon_diff_predicted "Add-on premium difference to BMG addon prediction in year"
	label var addon_avg "Average add-on premium in year"
	label var addon_predicted "Predicted add-on premium by BMG for year"
	label var merge_date "Date when (if) provider merged"
	label var addon_group_fixed "Assignment of addon >/=/< average for DiD"
		
	* Rename providers for merge with dfg GKV-ranking
	replace provider="BARMER GEK" if provider=="BARMER" & year==2015	
	replace provider="Die Schwenninger Krankenkasse" if provider=="vivida BKK" & year<2021
	
* 3) Save data
* ---------------------------------------------------------------------------- *

	* Save file
	save "$data_input/Premium/GKV_Spitzenverband_ZB.dta", replace
	
cap log close 
