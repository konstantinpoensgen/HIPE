********************************************************************************
************************* GKV Rechnungslegung Data *****************************
********************************************************************************

/*	Data sets
	Input: $data_input/Rechnungslegung/GKV_Rechnungslegung.csv
	Output: $data_input/Rechnungslegung/GKV_Rechnungslegung.dta

	Do-file outline 
	1) Raw data
	2) Data cleaning 
	3) Generate additional variables
	4) Save data

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
log using "$logs_build/`date'_HIPE_GKV_Rechnungslegung.log", text replace		


* 1) Raw data
* ---------------------------------------------------------------------------- *
	
	* Load data
	import delimited "$data_input/Rechnungslegung/GKV_Rechnungslegung.csv", clear delim(";") encoding("UTF-8") varn(1)

	* Rename variables
	rename krankenkasse provider
	rename mitglieder members
	rename versicherte insured_avg
	rename vermögen_gesamt capital
	rename vermögen_rücklagen capital_reserves
	rename vermögen_verwaltung capital_admin
	rename einnahmen_gesamt revenue
	rename einnahmen_gesundheitsfonds revenue_fund
	rename einnahmen_zusatzbeitrag revenue_addon
	rename ausgaben_gesamt expenditure
	rename ausgaben_verwaltung expenditure_admin
	rename comment comment_rechnungslegung
	
	* Label variables
	label var type "Type of provider in German HI system pillar"
	label var provider "Name of health insurance provider"
	label var year "Year"
	label var members "Members in respective year (Bundesanzeiger Rechnungslegung)"
	label var insured_avg "Insured individuals in respective year (Bundesanzeiger Rechnungslegung)"
	label var capital "Vermögen (Bundesanzeiger Rechnungslegung)"
	label var capital_reserves "Rücklagen subcategory of Vermögen (Bundesanzeiger Rechnungslegung)"
	label var capital_admin "Verwaltungsvermögen subcategory of Vermögen (Bundesanzeiger Rechnungslegung)"
	label var revenue "Gesamteinnahmen (Bundesanzeiger Rechnungslegung)"
	label var revenue_fund "Zuweisungen aus dem Gesundheitsfonds subcat of revenue (Bundesanzeiger Rechnungslegung)"
	label var revenue_addon "Mittel aus Zusatzbeitrag (Bundesanzeiger Rechnungslegung)"
	label var expenditure "Gesamtausgaben (Bundesanzeiger Rechnungslegung)"
	label var expenditure_admin "Verwaltungsausgaben subcat of expenditure (Bundesanzeiger Rechnungslegung)"
	label var comment_rechnungslegung "Comment for data from Bundesanzeiger Rechnungslegung"
	
	* Drop not necessary data
	drop source publishingdate
	

* 2) Data cleaning 
* ---------------------------------------------------------------------------- *
		
	* Destring variables
	local variables members insured_avg capital capital_reserves capital_admin ///
		revenue revenue_fund revenue_addon expenditure expenditure_admin
	
	foreach var in `variables' {
		destring `var' , replace ignore("NA")
		}
		
	* Check consistency of entries
	* ..........................................................................

	local consistency 0 // turn consistency checks on off
	
		cap drop id
		encode provider, gen(id)
			tab id, nolab
		
		* expenditure_admin
		if `consistency'==1 {
			forvalues j=1/120 {
			
				// admin exp
				graph twoway (scatter expenditure_admin year if id==`j') ///
					(line expenditure_admin year if id==`j') ///
					, title("Evolution of admin expenditures (`j')") ///
					legend(off) ylab(,labsize(2))
		
				graph export "$figures/Exploratory/GKV_Rechnungslegung/GGKV_Rechnungslegung_check_expadmin_`j'", ///
					as(png) replace
				
				// insured
				graph twoway (scatter insured_avg year if id==`j') ///
					(line insured_avg year if id==`j') ///
					, title("Evolution of insured individuals (`j')") ///
					legend(off) ylab(,labsize(2))
		
				graph export "$figures/Exploratory/GKV_Rechnungslegung/GKV_Rechnungslegung_check_insuredavg_`j'", ///
					as(png) replace
					
				// revenue fund	
				graph twoway (scatter revenue_fund year if id==`j') ///
					(line revenue_fund year if id==`j') ///
					, title("Evolution of fund revenue (`j')") ///
					legend(off) ylab(,labsize(2))
		
				graph export "$figures/Exploratory/GKV_Rechnungslegung/GKV_Rechnungslegung_check_revfund_`j'", ///
					as(png) replace
					
				// revenue addon	
				graph twoway (scatter revenue_addon year if id==`j') ///
					(line revenue_addon year if id==`j') ///
					, title("Evolution of add-on revenue (`j')") ///
					legend(off) ylab(,labsize(2))
		
				graph export "$figures/Exploratory/GKV_Rechnungslegung/GKV_Rechnungslegung_check_revaddon_`j'", ///
					as(png) replace
					
				}
			}
		else {
			disp "No consistency checks run"
			}
	
		drop id type
		

* 3) Generate additional variables
* ---------------------------------------------------------------------------- *	

	* Per capita values
	local variables capital capital_reserves capital_admin revenue revenue_fund revenue_addon expenditure expenditure_admin

	foreach var in `variables' {
		cap drop `var'_pc
		gen `var'_pc = `var'/insured_avg
		}
		
		// Label new variables
		label var capital_pc "Vermögen (Bundesanzeiger Rechnungslegung)"
		label var capital_reserves_pc "Rücklagen subcategory of Vermögen (Bundesanzeiger Rechnungslegung)"
		label var capital_admin_pc "Verwaltungsvermögen subcategory of Vermögen (Bundesanzeiger Rechnungslegung)"
		label var revenue_pc "Gesamteinnahmen (Bundesanzeiger Rechnungslegung)"
		label var revenue_fund_pc "Zuweisungen aus dem Gesundheitsfonds subcat of revenue (Bundesanzeiger Rechnungslegung)"
		label var revenue_addon_pc "Mittel aus Zusatzbeitrag (Bundesanzeiger Rechnungslegung)"
		label var expenditure_pc "Gesamtausgaben (Bundesanzeiger Rechnungslegung)"
		label var expenditure_admin_pc "Verwaltungsausgaben subcat of expenditure (Bundesanzeiger Rechnungslegung)"	


	* Change in admin costs
	
		encode provider, gen(id)
		xtset id year 
		gen admin_pc_change = expenditure_admin_pc - L.expenditure_admin_pc
		drop id

* 4) Save data 
* ---------------------------------------------------------------------------- *
		
	* Manual changes for later merge

		* BARMER vs BARMER GEK
		drop if provider=="BARMER" & year==2016
		replace provider="BARMER" if provider=="BARMER GEK" & year==2016 
		// this NEGLECTS the role of Deutsche BKK in the counterfactual joint entry	

	* Order variables
	order provider year members insured_avg capital capital_pc capital_reserves ///
		capital_reserves_pc capital_admin capital_admin_pc revenue revenue_pc ///
		revenue_fund revenue_fund_pc revenue_addon revenue_addon_pc expenditure ///
		expenditure_pc expenditure_admin expenditure_admin_pc comment_rechnungslegung
		
	* Save data 
	save "$data_input/Rechnungslegung/GKV_Rechnungslegung.dta" , replace
	
cap log close 	
