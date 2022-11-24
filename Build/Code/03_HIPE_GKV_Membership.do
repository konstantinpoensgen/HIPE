********************************************************************************
*************************** GKV Membership Data ********************************
********************************************************************************

/*	Objectives:
	- Creates $data_intermediate/GKV_aggregate_members
	- Corrects for M&A of insurers

	Do-file outline: 
	0) Preliminaries 
	1) dfg GKV Ranking: Aggregate number of insured individuals
	2) Adjust entries for M&As
	3) Adjust individual because of M&As
	4) Clean and generate data 
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
log using "$logs_build/`date'_HIPE_GKV_Membership.log", text replace	



* 1) dfg GKV Ranking: Aggregate number of insured individuals
* ---------------------------------------------------------------------------- *

* 	Load aggregate membership data (GKV-Ranking)
	import 	delimited "$data_input/Membership/DFG_GKV_Ranking_2021_Jan_Data_Compiled.csv", ///
			clear delim(";") varn(1) encoding("UTF-8")
 		
* 	Generate an empty 2009 variable
	cap drop insured_2009
	gen insured_2009=""
		
* 	Create provider ID	
	isid name 																	// data is in wide format
	encode name, gen(id)
	
* 	Reshape wide to long
	reshape long rank_ insured_, i(name id type) j(year)
	
* 	Rename variables
	rename name provider
	rename rank_ rank
	rename insured_ insured
	rename comment comment_dfg
	
* 	Label variables
	label var provider 		"Name of health insurance provider"
	label var rank			"Rank based on number of insured individuals"
	label var insured 		"Number of insured individuals on 01.01. of year (not paying members)"
	label var type 			"Type of provider in German HI system pillar"
	label var year 			"Year"
	label var comment_dfg 	"Comment from importing dfg GKV-Ranking"
	label var id 			"HIP ID"
	
* 	Change variables to numerics
	destring rank, replace ignore("F" "NA")
	destring insured, replace ignore("F" "NA")
	
* 	Check consistency of entries
	local consistency 1 														// turn consistency checks on/off

	* Visual exploration
	if `consistency'==0 {
		
		qui distinct id
		forvalues j=1/`r(ndistinct)' {
			graph twoway (scatter insured year if id==`j') (line insured year if id==`j') ///
				, title("Evolution of insured individuals (`j')") ///
				legend(off) ylab(,labsize(2))
		
			graph export "$figures/Exploratory/GKV_insured_check/`date'_GKV_insured_numbers_check_`j'.png", ///
				as(png) replace
			}
		}
	else {
		disp "Did not run new figures for Exploratory/GKV_insured_check"
		}
		
* 	Drop entries with missing information
	drop if insured==. & year!=2009
	table year, c(count insured)
		
* 	Change in membership year-to-year

	* Set time variable
	xtset id year
	sort id year 

	* "Lead" membership
	cap drop insured_lead
	gen insured_lead = f.insured
	label var insured_lead "Number of insured invididuals on 01.01. in t+1 (lead)"
	
	* Absolute change in membership
	cap drop insured_change_abs 
	gen insured_change_abs = insured_lead - insured
	
	label var insured_change_abs "Change (absolute) insured individuals = 01.01.t+1 minus 01.01.t"
	//label var year "Year"
		
* 	Save temporary version
	save "$data_temp/temp_GKV", replace

 	
* 2) Adjust entries for M&As 
* ---------------------------------------------------------------------------- *

* 2.1) Tempfile for M&A info
	
	* Import list with M&A info
	import delimited "$data_input/Membership/GKV_mergers", clear delim(";") encoding("UTF-8") varn(1)

	* Adjust varnames and varlables
	rename relevantyear year
	rename merger_dummy merger
	label var merger "Dummy variable if M&A in relevant year (t+1 wrt t)"
	label var provider "Name of health insurance provider"
	label var year "Year (Entries for 01.01. in respective year)"
	
	duplicates report merged_provider_1 year
	
	* Save temp version
	duplicates report merged_provider_1 year 
	assert `r(N)'==`r(unique_value)'
	tempfile temp_MA
	save `temp_MA', replace 
	 

* 2.2) Join M&A data with merged_providers_1
	
	* Load GKV member data
	use "$data_temp/temp_GKV", clear

	* Keep relevant variables only and rename for merge with temp_MA
	keep provider year insured
	rename provider merged_provider_1
	rename insured insured_merged_provider_1
		
	* Join with MA info
	isid merged_provider_1 year 
	merge 1:1 merged_provider_1 year using `temp_MA' 

	* Drop unmatched master
	drop if _merge==1
 
	* Keep relevant variables
	keep	provider year merged_provider_1 merged_provider_2 merged_provider_3 ///
			merged_provider_4 insured_merged_provider_1 merger canadjust flag
	
	* Save temporary version
	tempfile temp_MA
	save `temp_MA', replace 

	
* 2.3) Join MA data with merged_providers_2
	
	* Load GKV member data
		use "$data_temp/temp_GKV", clear

		* Keep relevant variables only and rename for merge with temp_MA
		keep provider year insured
		
		rename provider merged_provider_2
		rename insured insured_merged_provider_2
		
	* Join with MA info
		merge 1:1 merged_provider_2 year using `temp_MA'
	
		* Drop non-MAs
		drop if _merge==1
	
		* Keep relevant variables
		keep provider year merged_provider_1 merged_provider_2 merged_provider_3 ///
			merged_provider_4 insured_merged_provider_1 insured_merged_provider_2 ///
			merger canadjust flag
	
		* Duplicates report 
		duplicates report merged_provider_3 year
	
	* Save temporary version
	tempfile temp_MA
	save `temp_MA', replace 
		
		
* 2.4) Join M&A data with merged_providers_3
	
	*	Load GKV member data
		use "$data_temp/temp_GKV", clear

		* Keep relevant variables only and rename for merge with temp_MA
		keep provider year insured
		
		rename provider merged_provider_3
		rename insured insured_merged_provider_3
		
	*	Join with MA info
		merge 1:m merged_provider_3 year using `temp_MA'
	
		* Drop non-MAs
		drop if _merge==1
	
		* Keep relevant variables
		keep provider year merged_provider_1 merged_provider_2 merged_provider_3 ///
			merged_provider_4 insured_merged_provider_1 insured_merged_provider_2 ///
			insured_merged_provider_3 merger canadjust flag
			
		order provider year merged_provider_1 merged_provider_2 merged_provider_3 ///
			merged_provider_4 insured_merged_provider_1 insured_merged_provider_2 ///
			insured_merged_provider_3 merger canadjust flag
	
	* Save temporary version
	tempfile temp_MA
	save `temp_MA', replace 
	
	
* 2.5) Join MA data with merged_providers_4
	
	*	Load GKV member data
		use "$data_temp/temp_GKV", clear

		* Keep relevant variables only and rename for merge with temp_MA
		keep provider year insured
		
		rename provider merged_provider_4
		rename insured insured_merged_provider_4
		
	*	Join with MA info
		merge 1:m merged_provider_4 year using `temp_MA'
	
		* Drop non-MAs
		drop if _merge==1
	
		* Keep relevant variables
		keep provider year merged_provider_1 merged_provider_2 merged_provider_3 ///
			merged_provider_4 insured_merged_provider_1 insured_merged_provider_2 ///
			insured_merged_provider_3 insured_merged_provider_4 merger canadjust flag
			
		order provider year merged_provider_1 merged_provider_2 merged_provider_3 ///
			merged_provider_4 insured_merged_provider_1 insured_merged_provider_2 ///
			insured_merged_provider_3 insured_merged_provider_4 merger canadjust flag
	
	* Save temporary version
	tempfile temp_MA
	save `temp_MA', replace 
	
 
* 2.6) Join MA data with general GKV membership data

	* Load GKV membership data
	use "$data_temp/temp_GKV", clear
	
	* Merge with M&A data
	merge 1:1 provider year using `temp_MA'
	drop _merge

	* Readjust ID variable 
	cap drop id
	encode provider, gen(id)
	isid id year
	
* 3) Adjust individual because of M&As
* ---------------------------------------------------------------------------- *

	* Audi BKK 2010
		// br if provider=="Audi BKK" & year==2010
		// no information on merging parties but large jump
		// graph twoway line insured year if provider=="Audi BKK"
		// graph twoway line insured_change_abs year if provider=="Audi BKK"
		replace insured_change_abs=. if provider=="Audi BKK" & year==2010
	
	* AOK Niedersachsen 2010
		// br if provider=="AOK Niedersachsen"
		replace insured_change_abs = insured_change_abs - 285000 ///
			if provider=="AOK Niedersachsen" & year==2010
		// IKK Niedersachsen: 285000 https://www.deutsche-apotheker-zeitung.de/daz-az/2010/az-6-2010/niedersachsen-aok-und-ikk-fusion
		
	* Novitas BKK 2010
		// br if provider=="Novitas BKK"
		replace insured_change_abs=. if provider=="Novitas BKK" & year==2010
		// Cannot control for merged party but only year with increase
	
	* pronova BKK 2010
		// br if provider=="pronova BKK"
		replace insured_change_abs=. if provider=="pronova BKK" & year==2010
		// Cannot control for merged party but only year with increase
	
	* Vereinigte IKK 2010
		// br if provider=="Vereinigte IKK" 
		// doesn't matter because no data over time available
		
	* Vereinigte BKK 2010
		// br if provider=="Vereinigte BKK"
		// doesn't matter because no data for 2010
		
	* VIACTIV Krankenkasse 2010
		// br if provider=="VIACTIV Krankenkasse"
		replace insured_change_abs=. if provider=="VIACTIV Krankenkasse" & year==2010
		// Acquisition without able to control for it
	
	* AOK NordWest 2010
		// br if provider=="AOK NordWest" 
		// doesn't matter because no data for 2010 anyway
		
	* AOK Nordost 2010
		// br if provider=="AOK Nordost"
		// doesn't matter because no data for 2010 for AOK Nordost

	* mhplus BKK 2010
		// br if provider=="mhplus BKK"
		replace insured_change_abs=. if provider=="mhplus BKK" & year==2010
		// very different change in numbers but cannot subtract from merging party
	
	* DAK-Gesundheit ("counterfactual") 2011
		//br if provider=="DAK-Gesundheit"
		replace insured = insured_merged_provider_1 + 1000000 + 12000 ///
			if provider=="DAK-Gesundheit" & year==2011
		replace insured_change_abs = insured_lead - insured ///
			if provider=="DAK-Gesundheit" & year==2011
		replace comment_dfg="Counterfactual (total loss) DAK, BKK Gesundheit and Axel Springer" ///
			if provider=="DAK-Gesundheit" & year==2011
	
	* VIACTIV Krankenkasse 2011
		// br if provider=="VIACTIV Krankenkasse"
		replace insured_change_abs=. if provider=="VIACTIV Krankenkasse" & year==2011
		// very large increase likely due to merger while cannot control for numbers
	
	* IKK classic 2011
		// br if provider=="IKK classic"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2  ///
			if provider=="IKK classic" & year==2011
		// large difference but cannot control for it (subtract Vereinigte IKK)
	
	* BBK VBU 2011
		// br if provider=="BKK VBU"
		replace insured_change_abs=. if provider=="BKK VBU" & year==2011
		// big difference but cannot control for it
	
	* actimonda krankenkasse 2011
		//br if provider=="actimonda krankenkasse"
		replace insured_change_abs=insured_change_abs - 3600 ///
			if provider=="actimonda krankenkasse" & year==2011
		// BKK Pfeifer & Langen -> online research: about 3600 members https://www.lifepr.de/pressemitteilung/actimonda-krankenkasse/Gemeinsam-unter-einem-Dach/boxid/221218
		
	* Audi BKK 2011
		// br if provider=="Audi BKK"
		replace insured_change_abs=. if provider=="Audi BKK" & year==2011
		// Merging party BKK MTU missings
		
	* DAK-Gesundheit 2011
		// br if provider=="DAK-Gesundheit"
		// doesn't  matter since DAK-Gesundheit starting 2012 only
	
	* AOK Rheinland-Pfalz/Saarland 2012
		// br if provider=="AOK Rheinland-Pfalz/Saarland"
		replace insured = insured_merged_provider_1 + insured_merged_provider_2 ///
			if provider=="AOK Rheinland-Pfalz/Saarland" & year==2012
		
		replace insured_change_abs = insured_lead - insured ///
			if provider=="AOK Rheinland-Pfalz/Saarland" & year==2012
	
	* VIACTIV Krankenkasse 2012
		// br if provider=="VIACTIV Krankenkasse"
		replace insured_change_abs = . if provider=="VIACTIV Krankenkasse" & year==2012
		// large gains that cannot be controled for with merging party

	* DAK-Gesundheit 2012
		// br if provider=="DAK-Gesundheit" 
		replace insured_change_abs = insured_change_abs - 22000 ///
			if provider=="DAK-Gesundheit" & year==2012
		// Saint-Gobain BKK 22.000 members https://www.krankenkasseninfo.de/krankenkassen/saint-gobain-bkk/
		
	* actimonda krankenkasse 2013
		// br if provider=="actimonda krankenkasse"
		replace insured_change_abs = insured_change_abs - 1350 /// 
			if provider=="actimonda krankenkasse" & year==2013
		// BKK Heimbach: 1350 Versicherte https://www.aerztezeitung.de/Politik/BKK-Heimbach-bald-Geschichte-288994.html
		
	* BKK MOBIL OIL 2013
		// br if provider=="BKK MOBIL OIL"
		replace insured_change_abs = insured_change_abs - 38000 ///
			if provider=="BKK MOBIL OIL" & year==2013
		// Members Hypovereinsbank 38000 Versicherte
		
	* Novitas BKK 2014
		// br if provider=="Novitas BKK"
		replace insured_change_abs = insured_change_abs - 11000 - 23000 ///
			if provider=="Novitas BKK" & year==2014
		// BKK PHOENIX: 11.000 Versicherte https://www.aerztezeitung.de/Politik/Neue-Fusion-in-BKK-Familie-244074.html
		// ESSO BKK: 23.000 Versicherte https://www.lifepr.de/pressemitteilung/novitas-bkk-duisburg/Novitas-BKK-fusioniert-mit-ESSO-BKK/boxid/514386
	
	* Deutsche BKK 2014
		// br if provider=="Deutsche BKK"
		replace insured_change_abs = insured_change_abs - 410000 ///
			if provider=="Deutsche BKK" & year==2014
		// BKK Essanelle: 410.000 Versicherte https://de.wikipedia.org/wiki/Deutsche_BKK
		
	* DAK-Gesundheit 2014
		// br if provider=="DAK-Gesundheit"
		replace insured_change_abs = insured_change_abs - 12000 ///
			if provider=="DAK-Gesundheit" & year==2014
		// Shell BKK / LIFE: 12.000 Versicherte https://www.healthcaremarketing.eu/unternehmen/detail.php?rubric=Unternehmen&nr=31016
	
	* BKK VBU 2014
		// br if provider=="BKK VBU"
		replace insured_change_abs = insured_change_abs - 11000 ///
			if provider=="BKK VBU" & year==2014
		// BKK Medicus: 11.000 https://www.deutsche-apotheker-zeitung.de/news/artikel/2014/09/26/bkk-vbu-und-bkk-medicus-fusionieren
	
	* BIG direkt gesund 2014
		// br if provider=="BIG direkt gesund"
		replace insured_change_abs = insured_change_abs - 21000 ///
			if provider=="BIG direkt gesund" & year==2014
		// BKK VICTORIA-D.A.S.: 21000 https://www.aerztezeitung.de/Politik/BKK-Victoria-DAS-und-BIG-direkt-wollen-fusionieren-244773.html 
		
	* BKK VerbundPlus 2014
		// br if provider=="BKK VerbundPlus"
		replace insured_change_abs = insured_change_abs - 11000 ///
			if provider=="BKK VerbundPlus" & year==2014
		// BKK Kassana: 11.000 https://de.wikipedia.org/wiki/BKK_Kassana
		
	* BKK Gildemeister Seidensticker 2014
		// br if provider=="BKK Gildemeister Seidensticker"
		replace insured_change_abs = insured_change_abs - 1700 ///
			if provider=="BKK Gildemeister Seidensticker" & year==2014
		// BKK BJB: 1700 https://de.wikipedia.org/wiki/BKK_BJB_GmbH_%26_Co._KG; https://www.wp.de/staedte/neheim-huesten/eigenstaendige-betriebskrankenkasse-bjb-wird-aufgegeben-id10011246.html
	
	* pronova BKK 2015
		// br if provider=="pronova BKK"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="pronova BKK" & year==2015
		
	* BKK VBU 2015 
		// br if provider=="BKK VBU"
		replace insured_change_abs = insured_change_abs - 33000 - 6500 - 8000 ///
			if provider=="BKK VBU" & year==2015		
		// BKK Demag Krauss-Maffei: 33.000 https://www.bdc.de/page/157/?p=8065
		// BKK S-H: 6.500 https://www.bdc.de/page/157/?p=8065 
		// BKK Basell: 8.000 https://www.bdc.de/page/157/?p=8065
		
	* BKK ProVita 2015
		// br if provider=="BKK ProVitaa
		replace insured_change_abs = insured_change_abs - 15000 ///
			if provider=="BKK ProVita" & year==2015		
		// BKK family: 15.000 https://www.bdc.de/page/157/?p=8065
	
	* BKK Linde 2015
		// br if provider=="BKK Linde"
		replace insured_change_abs = insured_change_abs - 6500 ///
			if provider=="BKK Linde" & year==2015
		// HEAG BKK: 6.500 https://www.bdc.de/page/157/?p=8065
	
	* DAK-Gesundheit 2016
		// br if provider=="DAK-Gesundheit"
		replace insured_change_abs = insured_change_abs - 10400 ///
			if provider=="DAK-Gesundheit" & year==2016
		// BKK Beiersdorf AG: 10.400 https://www.aerzteblatt.de/archiv/175715/Krankenkassen-DAK-Gesundheit-plant-Fusion-mit-BKK-Beiersdorf
	
	* BARMER 2016
		// br if provider=="BARMER"
		replace insured = insured_merged_provider_1 + insured_merged_provider_2 ///
			if provider=="BARMER" & year==2016
		replace insured_lead = 9428559 if provider=="BARMER" & year==2016
		replace insured_change_abs = insured_lead - insured ///
			if provider=="BARMER" & year==2016
		replace comment_dfg="Joint loss of BARMER GEK and Deutsche BKK" ///
			if provider=="BARMER" & year==2016
	
	* BKK VBU 2016
		// br if provider=="BKK VBU"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="BKK VBU" & year==2016
	
	* energie-BKK 2016
		// br if provider=="energie-BKK"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="energie-BKK" & year==2016
	
	* pronova BKK 2016
		// br if provider=="pronova BKK"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="pronova BKK" & year==2016
	
	* BKK24 2017
		// br if provider=="BKK24"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="BKK24" & year==2017
	
	* BKK Psfalz 2017 
		// br if provider=="BKK Pfalz"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="BKK Pfalz" & year==2017
	
	* Metzinger BKK 2017
		// br if provider=="Metzinger BKK" 
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="Metzinger BKK" & year==2017
		
	* mhplus BKK 2018
		// br if provider=="mhplus BKK"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="mhplus BKK" & year==2018
			
	* BKK B Braun Aesculap 2019
		// br if provider=="BKK B Braun Aesculap"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_1 ///
				if provider=="BKK B Braun Aesculap" & year==2019
		// Note: subtract merger party 2
		// BKK B Braun Melsungen: 17.000 https://de.wikipedia.org/wiki/Betriebskrankenkasse_B._Braun_Melsungen_AG
		
	* BKK VBU 2019
		// br if provider=="BKK VBU"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="BKK VBU" & year==2019
	
	* Continentale Betriebskrankenkasse 2019
		//br if provider=="Continentale Betriebskrankenkasse"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="Continentale Betriebskrankenkasse" & year==2019
	
	* BIG direkt gesund 2020
		// br if provider=="BIG direkt gesund"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="BIG direkt gesund" & year==2020
		
	* vivida BKK 2020
		// br if provider=="vivida BKK"
		// no data over time
		
	* VIACTIV Krankenkasse 2020
		// br if provider=="VIACTIV Krankenkasse"
		replace insured_change_abs = insured_change_abs - insured_merged_provider_2 ///
			if provider=="VIACTIV Krankenkasse" & year==2020



* 4) Clean and generate data 
* ---------------------------------------------------------------------------- *

* Keep relevant variables only
	keep provider id type year rank insured comment_dfg insured_lead insured_change_abs merger

* Additional variables	
	
	* Change in number of insured individuals as % of insured individuals
	cap drop insured_change_perc 
	gen insured_change_perc = insured_change_abs/insured
	label var insured_change_perc "Change (%) insured individuals t+1 minus t"
	
	* Market share
	
		// Total insurees by year
		cap drop insured_total
		bysort year: egen insured_total = sum(insured)
	
		// Market share by provider-year
		cap drop marketshare 
		gen marketshare = insured/insured_total
			label var marketshare "Marketshare at January 01 in year t"
			sum marketshare if provider=="DAK-Gesundheit" 
		
		// Change in market share
		
			// Lead market share
			xtset id year
			cap drop marketshare_lead
			gen marketshare_lead = f.marketshare
				label var marketshare_lead "Marketshare at January 01 in year t+1"
	
			// %-change in market share 
			cap drop marketshare_change
			gen marketshare_change = (marketshare_lead - marketshare)/marketshare
				label var marketshare_change "%-change in marketshare from 01.01.t to 01.01.t+1"
				sum marketshare_change
				sum marketshare_change if provider=="Techniker Krankenkasse (TK)"
			
	* Weighted %-change in net-enrollment
	cap drop insured_change_perc_weighted
	gen insured_change_perc_weighted = insured_change_perc * marketshare
		label var insured_change_perc_weighted "%-change in enrollment during t weighted by marketshare at 01.01.t"
					
	* Initial size (=  number insured 2010)
	cap drop temp
	gen temp = insured if year==2010
		replace temp = insured if year==2011 & temp==.
		replace temp = insured if year==2012 & temp==.
		replace temp = insured if year==2013 & temp==.
		replace temp = insured if year==2014 & temp==.
		replace temp = insured if year==2015 & temp==.
		
	cap drop insured_initial
	bysort provider: egen insured_initial = max(temp)
	drop temp
		label var insured_initial "Enrolled individuals at January 01 2010"
		sum insured_initial // if provider=="Metzinger BKK"
	
* Summary statistics for plausibility
	sum insured_change_abs insured_change_perc

* Graph changes individually for consistency check

	*	Check consistency of entries
	local consistency 0 														// turn consistency checks on off

	* Visual exploration
	if `consistency'==1 {

		qui distinct id
		forvalues j=1/`r(ndistinct)' {
			graph twoway (scatter insured_change_abs year if id==`j') ///
				(line insured_change_abs year if id==`j') ///
				, title("Evolution of insured individuals (`j')") ///
				legend(off) ylab(,labsize(2))
		
			graph export "$figures/Exploratory/GKV_insured_check/`date'_GKV_insured_change_abs_check_`j'", ///
				as(png) replace
				
			graph twoway (scatter insured_change_perc year if id==`j') ///
				(line insured_change_perc year if id==`j') ///
				, title("Evolution of insured individuals (`j')") ///
				legend(off) ylab(,labsize(2))
		
			graph export "$figures/Exploratory/GKV_insured_check/`date'_GKV_insured_change_perc_check_`j'", ///
				as(png) replace
			}
		}
	else {
		disp "No consistency checks run"
		}

* Clean merger variable
	replace merger=0 if merger==.
		
* Save data
	
	* Structure variables
	order provider id type year rank insured insured_lead insured_change_abs ///
		insured_change_perc merger comment_dfg
		
	drop id	
	
	* Save	
	save "$data_intermediate/GKV_aggregate_members", replace


* Close log file 
cap log close 
