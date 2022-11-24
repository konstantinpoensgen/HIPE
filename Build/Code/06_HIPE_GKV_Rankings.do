********************************************************************************
************************* GKV FOCUS MONEY GKV Ranking  *************************
********************************************************************************
	
/*	DATA
	Input: $data_input/Ratings/FOCUS_Money_GKVtest.xlsx
	Output: $data_input/Ratings/FOCUS_Money_GKVtest
	
	DO-FILE OUTLINE 
	1) Load data
	2) Impute gaps
	3) Other data cleaning
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
log using "$logs_build/`date'_HIPE_GKV_Rankings.log", text replace	

* Set subcomponent variables 
global subcomponents "service wahltarife bonusprogramme altmedicine healthsupport zusatz"
global subcomponents_relative "service_relative wahltarife_relative bonusprogramme_relative altmedicine_relative healthsupport_relative zusatz_relative"


*==============================================================================*
*								SECTION 1 									   *
*							  Overall Rating 								   *
*==============================================================================*


* 1.1) Load data
* ---------------------------------------------------------------------------- *

	* Import data
	import excel "$data_input/Ratings/FOCUS_Money_GKVtest.xlsx", clear firstrow sheet("Gesamtpunktzahl")
	
	* Reshape long
	drop if provider==""
	reshape long rating, i(provider) j(year)
	
	* Replace "0" entries with missing
	replace rating=. if rating==0
	

* 1.2) Impute gaps
* ---------------------------------------------------------------------------- *

	* Set panel structure
	encode provider, gen(id)
	xtset id year
	
	* Create lagged and lead value
		cap drop rating_l
		gen rating_l = l.rating
	
		cap drop rating_f
		gen rating_f = f.rating
	
	* Calculate mean based on mean and lag
	cap drop rating_imp
	egen rating_imp = rowmean(rating_l rating_f)
	
	* Fill gaps when possible
	replace rating = rating_imp if rating==. & rating_imp!=.
	replace rating = round(rating,0.1)
	

* 1.3) Other data cleaning
* ---------------------------------------------------------------------------- *

	* Generate "standardized" relative rating

		* Max rating by year
		cap drop rating_max
		egen rating_max = max(rating), by(year)
		
		* Relative rating
		cap drop rating_relative
		gen rating_relative = round(100 * rating/rating_max,0.1)
			
			// check proper results
			sum rating_relative, d	

	* Drop entries with missing data
	drop if rating==.
	table year, c(count rating)
	
	* Rename entries for merge
			
		* BARMER vs BARMER GEK
		replace provider="BARMER" if provider=="BARMER GEK" & year>=2016
		
	* Keep relevant variables only
	keep provider year rating rating_relative 
	keep if year>=2009
	
	* Label variables
	label var rating "Total rating by FOCUS MONEY GKV test"
	label var rating_relative "Rating by FOCUS Money GKV test relative to max. rating in year"
	

* 1.4) Save data
* ---------------------------------------------------------------------------- *

	* Save data
	save "$data_temp/temp_focus_ratings.dta", replace
	

*==============================================================================*
*								SECTION 2 									   *
*							   Subcomponents	 								   *
*==============================================================================*

* 2.1) Extract relevant data
* ---------------------------------------------------------------------------- *
forvalues y = 2009/2021 {

	di "======================================================================="
	di "Now running year: `year'"

	* Skip years with no data available
	if `y'==2013 | `y'==2015 continue

	* Load data
	import excel "$data_input/Ratings/FOCUS_Money_GKVtest.xlsx", clear firstrow sheet("`y'")
	
	* Rename variables
	ren Krankenkasse provider 

	* Generate year variable 
	gen year = `y'

	* Service
	* ........................................................................ *

	* 2009 
	if year==2009 {
		assert Punkte_Service_Geschäftsstellen!=. & Punkte_Service_Telefon!=.
		egen service = rowtotal(Punkte_Service_Geschäftsstellen Punkte_Service_Telefon)
	}

	* 2010-2012
	if year>=2010 & year<=2012 {
		assert Punkte_Service!=.
		gen service = Punkte_Service
	}

	* 2013-2018
	if year>=2013 & year<=2021 {
		assert Service!=.
		gen service = Service
	}


	* Wahltarife 
	* ........................................................................ *

	* 2009-2012
	if year>=2009 & year<=2012 {
		gen wahltarife = Punkte_Wahltarife
	}

	* 2014-2021
	if year>=2014 & year<=2021 {
		gen wahltarife = Wahltarife 
	}


	* Bonusprogramme
	* ........................................................................ *

	* 2009-2012
	if year>=2009 & year<=2012 {
		gen bonusprogramme = Punkte_Bonusprogramme
	} 

	* 2014-2021
	if year>=2014 & year<=2021 {
		gen bonusprogramme = Bonusprogramme
	} 


	* Alternative Medicine
	* ........................................................................ *

	* 2009, 2010 and 2012
	if (year>=2009 & year<=2010) | year==2012 {
		gen altmedicine = Punkte_Naturheilverfahren
	} 

	* 2011
	if year==2011 	gen altmedicine = Punkte_AlternativeMedizin

	* 2014-2021
	if year>=2014 & year<=2021 {
		gen altmedicine = AlternativeMedizin
	} 

	
	* Gesundheitsförderung
	* ........................................................................ *

	* 2009, 2010 and 2012
	if year>=2009 & year<=2012 {
		gen healthsupport = Punkte_Gesundheitsförderung
	} 

	* 2014-2021
	if year>=2014 & year<=2021 {
		gen healthsupport = Gesundheitsförderung
	} 

	* Zusatzleistungen
	* ........................................................................ *

	* 2009, 2010 and 2012
	if year>=2009 & year<=2012 {
		gen zusatz = Punkte_Zusatzleistungen
	} 

	* 2014-2021
	if year>=2014 & year<=2021 {
		gen zusatz = Zusatzleistungen
	} 


	* Cleaning 
	* ........................................................................ *

	* Keep relevant variables only
	keep provider year $subcomponents 

	* Rename providers for match
	replace provider = "Techniker Krankenkasse (TK)" if provider=="Techniker Krankenkasse"
	replace provider = "AOK Baden-Wuerttemberg" if provider=="AOK Baden-Württemberg"
	replace provider = "AOK PLUS" if provider=="AOK Plus"
	replace provider = "BKK MOBIL OIL" if provider=="BKK Mobil Oil"
	replace provider = "BKK MOBIL OIL" if provider=="Betriebskrankenkasse Mobil Oil"
	replace provider = "BKK VBU" if provider=="BKK Verkehrsbau Union"
	replace provider = "BAHN-BKK" if provider=="Bahn-BKK"
	replace provider = "Barmer Ersatzkasse (BEK)" if provider=="Barmer"
	replace provider = "Gmuender ErsatzKasse GEK" if provider=="GEK Gmünder ErsatzKasse"
	replace provider = "IKK Thueringen" if provider=="IKK Thüringen"
	replace provider = "R+V Betriebskrankenkasse" if provider=="R+V BKK"
	replace provider = "SECURVITA BKK" if provider=="Securvita Krankenkasse"
	replace provider = "mhplus BKK" if provider=="mhplus Betriebskrankenkasse"
	replace provider = "neü BKK" if provider=="neue BKK"
	replace provider = "AOK NordWest" if provider=="AOK NORDWEST"
	replace provider = "BKK_DuerkoppAdler" if provider=="BKK Dürkopp Adler"
	replace provider = "BARMER GEK" if provider=="Barmer GEK"
	replace provider = "BARMER" if provider=="BARMER GEK" & year>=2016
	replace provider = "DIE BERGISCHE KRANKENKASSE" if provider=="Bergische Krankenkasse"
	replace provider = "IKK Suedwest" if provider=="IKK Südwest"
	replace provider = "pronova BKK" if provider=="Pronova BKK"
	replace provider = "hkk Handelskrankenkasse" if provider=="hkk Krankenkasse"
	replace provider = "Hanseatische Krankenkasse (HEK)" if provider=="HEK Hanseatische Krankenkasse"
	replace provider = "IKK classic" if provider=="KK classic"
	replace provider = "KKH Kaufmaennische Krankenkasse" if provider=="KKH-Allianz"
	replace provider = "KKH Kaufmaennische Krankenkasse" if provider=="KKH Kaufmännische Krankenkasse"
	replace provider = "actimonda krankenkasse" if provider=="Actimonda Krankenkasse"
	replace provider = "actimonda krankenkasse" if provider=="Actimonda krankenkasse"
	replace provider = "atlas BKK ahlmann" if provider=="Atlas BKK Ahlmann"
	replace provider = "BKK advita" if provider=="BKK Advita"
	replace provider = "VIACTIV Krankenkasse" if provider=="Viactiv Krankenkasse"
	replace provider = "WMF BKK" if provider=="Betriebskrankenkasse WMF"

	* Save as temporary dataset
	isid provider 
	save "$data_temp/temp_`y'.dta", replace 

} // close loop `y'


* 2.2) Merge information to FOCUS Money data 
* ---------------------------------------------------------------------------- *

	* Append temp data with subcomponents 
	* ........................................................................ *

	* Load base data
	use "$data_temp/temp_2009.dta", clear 

	* Append other years
	forvalues y= 2010/2021 {
		if `y'==2013 | `y'==2015 continue
		append using "$data_temp/temp_`y'"
	}

	* Store appended data 
	save "$data_temp/temp_ratings_sub.dta", replace


	* Merge main rating with subcomponents 
	* ........................................................................ *

	* Load main rating as master data 
	use "$data_temp/temp_focus_ratings.dta", clear

	* Merge subcomponents 
	merge 1:1 provider year using "$data_temp/temp_ratings_sub.dta", gen(merge_subcomponents)
		
		* Non-matched providers
		tab provider if merge_subcomponents == 2
		//drop if merge_subcomponents == 2


* 2.3) Fill gaps in panel
* ---------------------------------------------------------------------------- *

	* Set ID-year structure
	encode provider, gen(id)
	xtset id year
	
	* Loop over variables
	foreach var in $subcomponents {

		* Create lagged and lead value
		gen `var'_l = l.`var'
		gen `var'_f = f.`var'

		* Calculate mean based on mean and lag
		egen `var'_imp = rowmean(`var'_l `var'_f)
		
		* Fill gaps when possible
		replace `var' = `var'_imp if `var'==. & `var'_imp!=.

		* Drop imputation variable 
		drop `var'_imp

	} // close loop `var'

	* Drop ID var again
	drop id 
	

* 2.4) Additional data generation and cleaning
* ---------------------------------------------------------------------------- *	

	* Generate "standardized" relative rating
	foreach var in $subcomponents {

		* Max var by year
		egen `var'_max = max(`var'), by(year)
		
		* Relative rating
		gen `var'_relative = round(100 * `var'/`var'_max,0.1)

		* Drop max variable
		drop `var'_max

	} // close loop `service'


*==============================================================================*
*								SECTION 3									   *
*							 Save Final Data	 							   *
*==============================================================================*

* Keep relevant variables only 
keep provider year rating rating_relative $subcomponents $subcomponents_relative

* Save data
save "$data_input/Ratings/FOCUS_Money_GKVtest", replace

cap log close
