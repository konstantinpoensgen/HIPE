version 15
capture log close
set more off
clear

********************************************************************************
*************************** GKV Aggregate Data *********************************
********************************************************************************

* --------- dfg GKV Ranking: Aggregate number of insured individuas ---------- *

* Set directory
	cd "$data/Input/Membership"

* Load aggregate membership data (GKV-Ranking)
	import delimited "DFG_GKV_Ranking_2021_Jan_Data_Compiled.csv", clear delim(";") ///
		varn(1) encoding("UTF-8")
		
* Generate an empty 2009 variable
	cap drop insured_2009
	gen insured_2009=""
		
* Create provider ID	
	duplicates report name // unique
	encode name, gen(id)
	
* Reshape wide to long
	reshape long rank_ insured_, i(name id type) j(year)
	
* Rename variables
	rename name provider
	rename rank_ rank
	rename insured_ insured
	rename comment comment_dfg
	
* Label variables
	label var provider "Name of health insurance provider"
	label var rank	"Rank based on number of insured individuals"
	label var insured "Number of insured individuals on 01.01. of year (not paying members)"
	label var type "Type of provider in German HI system pillar"
	label var year "Year"
	label var comment_dfg "Comment from importing dfg GKV-Ranking"
	label var id "HIP ID"
	
* Change variables to numerics
	destring rank, replace ignore("F" "NA")
	destring insured, replace ignore("F" "NA")
	
* Check consistency of entries
	local consistency 0 // turn consistency checks on off

	* Visual exploration
	if `consistency'==1 {
		forvalues j=1/138 {
			graph twoway (scatter insured year if id==`j') (line insured year if id==`j') ///
				, title("Evolution of insured individuals (`j')") ///
				legend(off) ylab(,labsize(2))
		
			graph export "$figures/Exploratory/GKV_insured_check/GKV_insured_numbers_check_`j'", ///
				as(png) replace
			}
		}
	else {
		disp "No consistency checks run"
		}
		
* Drop entries with missing information
	drop if insured==. & year!=2009
	table year, c(count insured)
		
* Change in membership year-to-year

	* Set time variable
	xtset id year

	* "Lead" membership
	cap drop insured_lead
	gen insured_lead = f.insured
	label var insured_lead "Number of insured invididuals on 01.01. in t+1 (lead)"
	
	* Absolute change in membership
	cap drop insured_change_abs 
	gen insured_change_abs = insured_lead - insured
	
	label var insured_change_abs "Change (absolute) insured individuals = 01.01.t+1 minus 01.01.t"
	label var year "Year"
		
* Save temporary version
	save "$temp/temp_GKV", replace

	
* ------------------------- Adjust entries for M&As -------------------------- *

* Import list with M&A info
	import delimited "$data/Input/Membership/GKV_mergers", clear delim(";") encoding("UTF-8") varn(1)

* Adjust varnames and varlables
	rename relevantyear year
	rename merger_dummy merger
	label var merger "Dummy variable if M&A in relevant year (t+1 wrt t)"
	label var provider "Name of health insurance provider"
	label var year "Year (Entries for 01.01. in respective year)"
	
	duplicates report merged_provider_1 year
	
* Save temp version
	save "$temp/temp_MAs", replace
	
	
*	Join MA data with merged_providers_1
	
	* Load GKV member data
		use "$temp/temp_GKV", clear

		* Keep relevant variables only and rename for merge with temp_MA
		keep provider year insured
		
		rename provider merged_provider_1
		rename insured insured_merged_provider_1
		
	* Join with MA info
		merge 1:1 merged_provider_1 year using "$temp/temp_MAs" 
	
		* Drop non-MAs
		drop if _merge==1
	
		* Keep relevant variables
		keep provider year merged_provider_1 merged_provider_2 merged_provider_3 ///
			merged_provider_4 insured_merged_provider_1 merger canadjust flag
	
	* Save temporary version
	save "$temp/temp_MAs", replace

	
*	Join MA data with merged_providers_2
	
	* Load GKV member data
		use "$temp/temp_GKV", clear

		* Keep relevant variables only and rename for merge with temp_MA
		keep provider year insured
		
		rename provider merged_provider_2
		rename insured insured_merged_provider_2
		
	* Join with MA info
		merge 1:1 merged_provider_2 year using "$temp/temp_MAs" 
	
		* Drop non-MAs
		drop if _merge==1
	
		* Keep relevant variables
		keep provider year merged_provider_1 merged_provider_2 merged_provider_3 ///
			merged_provider_4 insured_merged_provider_1 insured_merged_provider_2 ///
			merger canadjust flag
	
		* Duplicates report 
		duplicates report merged_provider_3 year
	
	* Save temporary version
	save "$temp/temp_MAs", replace
		
		
*	Join MA data with merged_providers_3
	
	*	Load GKV member data
		use "$temp/temp_GKV", clear

		* Keep relevant variables only and rename for merge with temp_MA
		keep provider year insured
		
		rename provider merged_provider_3
		rename insured insured_merged_provider_3
		
	*	Join with MA info
		merge 1:m merged_provider_3 year using "$temp/temp_MAs" 
	
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
	save "$temp/temp_MAs", replace
	
	
*	Join MA data with merged_providers_4
	
	*	Load GKV member data
		use "$temp/temp_GKV", clear

		* Keep relevant variables only and rename for merge with temp_MA
		keep provider year insured
		
		rename provider merged_provider_4
		rename insured insured_merged_provider_4
		
	*	Join with MA info
		merge 1:m merged_provider_4 year using "$temp/temp_MAs" 
	
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
	save "$temp/temp_MAs", replace
	

* Join MA data with general GKV membership data

	* Load GKV membership data
	use "$temp/temp_GKV", clear
	
	* Merge with M&A data
	merge 1:1 provider year using "$temp/temp_MAs"
	drop _merge

* Readjust ID variable 
cap drop id
encode provider, gen(id)
duplicates report id year
	
*	Adjust individual entries

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
		replace comment="Counterfactual (total loss) DAK, BKK Gesundheit and Axel Springer" ///
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
		replace comment="Joint loss of BARMER GEK and Deutsche BKK" ///
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

* ------------------------ Clean and generate data --------------------------- *

* Keep relevant variables only
	keep provider id type year rank insured comment insured_lead insured_change_abs merger

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
	local consistency 0 // turn consistency checks on off

	* Visual exploration
	if `consistency'==1 {
		forvalues j=1/138 {
			graph twoway (scatter insured_change_abs year if id==`j') ///
				(line insured_change_abs year if id==`j') ///
				, title("Evolution of insured individuals (`j')") ///
				legend(off) ylab(,labsize(2))
		
			graph export "$figures/Exploratory/GKV_insured_check/GKV_insured_change_abs_check_`j'", ///
				as(png) replace
				
			graph twoway (scatter insured_change_perc year if id==`j') ///
				(line insured_change_perc year if id==`j') ///
				, title("Evolution of insured individuals (`j')") ///
				legend(off) ylab(,labsize(2))
		
			graph export "$figures/Exploratory/GKV_insured_check/GKV_insured_change_perc_check_`j'", ///
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
	save "$data/Input/Membership/GKV_aggregate_members", replace

		
* -------------------------- GKV Rechnungslegung ----------------------------- *

* Set directory
	cd "$data/Input/Rechnungslegung"
	
* Load data
	import delimited "$data/Input/Rechnungslegung/GKV_Rechnungslegung.csv", clear delim(";") encoding("UTF-8") varn(1)

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
	label var revenue_add "Mittel aus Zusatzbeitrag (Bundesanzeiger Rechnungslegung)"
	label var expenditure "Gesamtausgaben (Bundesanzeiger Rechnungslegung)"
	label var expenditure_admin "Verwaltungsausgaben subcat of expenditure (Bundesanzeiger Rechnungslegung)"
	label var comment_rechnungslegung "Comment for data from Bundesanzeiger Rechnungslegung"
	
* Drop not necessary data
	drop source publishingdate
	
* Cleaning
		
	* Destring variables
	local variables members insured_avg capital capital_reserves capital_admin ///
		revenue revenue_fund revenue_addon expenditure expenditure_admin
	
	foreach var in `variables' {
		destring `var' , replace ignore("NA")
		}
		
	*	Check consistency of entries
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
		
* Generate additional variables
		
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
	save "$data/Input/Rechnungslegung/GKV_Rechnungslegung" , replace
	
	
* ----------------------- GKV Add-on premium 2015-2021 ----------------------- *

* Set directory
	cd "$data/Input/Premium"
	
* Load data
	import excel "$data/Input/Premium/GKV_Spitzenverband_ZB.xlsx", clear firstrow

* Reshape wide to long
	drop if provider==""
	duplicates report provider
	reshape long addon, i(provider merge_date type) j(yearmonth)
	
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
		table year, c(mean addon)
		
		// Add-on difference to market average
		cap drop addon_diff_avg
		gen addon_diff_avg = addon - addon_avg
		
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
		
	* Group in below/at/above average
	
		// Distribution of addon difference to market average
		*histogram addon_diff_avg, width(0.1) normal
		sum addon_diff_avg, d // standard deviation of 0.3
	
		// Generate plain group variable by year
		cap drop addon_group_year 
		gen addon_group_year = 2 // default is "average"
			replace addon_group_year = 1 if addon_diff_avg < -0.3
			replace addon_group_year = 3 if addon_diff_avg > 0.3 
			replace addon_group_year = . if year>2018 // since only analyze until 2018
		
		// Label values
		label define addon_group_label 1 "Below average" 2 "Average" 3 "Above average", replace
		label values addon_group_year addon_group_label
		
		// How consistent can providers be allocated?
		cap drop addon_group_fixed
		egen addon_group_fixed = mean(addon_group_year), by(provider)
		
		// Assign to fixed groups 
		replace addon_group_fixed = 1 if addon_group_fixed <= 1.25
		replace addon_group_fixed = 2 if addon_group_fixed >= 1.75 & addon_group_fixed <= 2.25
		replace addon_group_fixed = 3 if addon_group_fixed >= 2.75
		replace addon_group_fixed = . if addon_group_fixed!=1 & addon_group_fixed!=2 & addon_group_fixed!=3
		
		// What's the respective group size?
		tab addon_group_fixed
		
		label values addon_group_fixed addon_group_label
		
* Keep relevant variables only
	keep provider gkv_type year addon merge_date addon_change addon_diff_avg ///
		addon_diff_predicted addon_avg addon_predicted addon_group_fixed addon_group_year
	order provider gkv_type year addon addon_change addon_diff_avg ///
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
	
* Save file
	save "$data/Input/Premium/GKV_Spitzenverband_ZB", replace
	
	
* ------------------------ FOCUS MONEY GKV Ranking --------------------------- *

* Set directory
	cd "$data/input/Ratings"
	
* Import data
	import excel "FOCUS_Money_GKVtest.xlsx", clear firstrow sheet("Gesamtpunktzahl")
	
* Reshape long
	drop if provider==""
	reshape long rating, i(provider) j(year)
	
* Replace "0" entries with missing
	replace rating=. if rating==0
	
* Impute gaps
	
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
	
* Save data
	save "$data/Input/Ratings/FOCUS_Money_GKVtest", replace
	
	
* ----------------------- Add-on premium rebate 2009-2012 -------------------- *
	
* Set directory
	cd "$data/Input/Premium/"
	
* Load data
	import excel using "ZB_2009_2012_Pendzialek.xlsx", clear firstrow
	
* Label variables
	label var addon_abs "Absolute add-on premium 2009-2012 (Pendzialek et al 2015)"
	label var addon_pct "Percentag add-on premium 2009-2012 (Pendzialek et al 2015"
	label var addon_dummy "Dummy = 1 if provider charged add-on premium in year 2009-2012 (Pendzialek et al 2015)"
	label var rebate_abs "Absolute rebate 2009-2012 (Pendzialek et al 2015"
	label var rebate_abs_dummy "Dummy = 1 if rebate paid in year 2009-2012 (Pendzialek et al 2015)"
	
* Save data
	save "$data/Input/Premium/ZB_2009_2012_Pendzialek", replace
	
	
	
	
* ---------------------------------------------------------------------------- *	
* ------------------------- Merge aggregate files ---------------------------- *
* ---------------------------------------------------------------------------- *


* -------------- dfg-GKV ratings insured individuals 2009-2021 --------------- *
	use "$data/Input/Membership/GKV_aggregate_members", clear
	
	// duplicates?
	duplicates report provider year
	
	// drop not necessary entries for cleaner merge_success overview
	drop if insured==. & year!=2009
	drop if insured_lead==. & year==2009
	table year
	
* ----------------- GKV-Spitzenverband add-on premium 20215-2021 ------------- *
	merge 1:1 provider year using "$data/Input/Premium/GKV_Spitzenverband_ZB"
	
	* Check what is not merged
	
	// Not merged from GKV Spitzenverband add-premium file
	tab provider if _merge==2
	
		/*
		- BKK Basell not in dfg GKV ranking
		- BKK Demag Krauss-Maffei not in dfg GKV ranking
		- BKK Schleswig-Holstein (S-H) not in dfg GKV ranking
		- BKK family not in dfg GKV ranking
		- HEAG BKK not in dfg GKV ranking
		- BKK Karl Mayer is only partly covered by dfg GKV ranking
		- BKK exklusiv is only partly covered by dfg GKV ranking
		- Koenig & Bauer only partly covered by dfg GKV ranking
		*/
	
		// drop data without information on # of insured individuals
		drop if _merge==2 // deletes 18 observations
	
	// Not matched from dfg GKV ranking
	table year if _merge==1, c(count insured)
	tab provider if _merge==1 & year>=2015
			
		/*
		BARMER GEK:
			- Merge is with "BARMER" in 2016 which is treated as BARMER and Deutsche BKK jointly
			- Drop below of "BARMER GEK" and "Deutsche BKK" does not lose anything because no insured_change for these two
		- Sozialversicherung fuer Landwirtschaft...		
		*/
		
		// BARMER vs. BARMER GEK
		drop if year==2016 & (provider=="BARMER GEK" | provider=="Deutsche BKK") // Treat 2016 values counterfactually jointly in "BARMER"
		
		// SVLG -> very special case, not keep in analysis
		drop if provider=="Sozialversicherung fuer Landwirtschaft Forsten und Gartenbau (SVLFG)"
	
	// Drop merge identifier
	drop _merge
	
* Some cleaning
	
	* Fill in missing types
	replace type="vdek" if provider=="BARMER" & year==2016
	replace type="AOK" if provider=="AOK Rheinland-Pfalz/Saarland" & year==2012
	replace type="vdek" if provider=="DAK-Gesundheit" & year==2011
	
	
* ------------------- Bundesanzeiger GKV Rechnungslegung --------------------- *
	
* Merge with GKV Rechnungslegung
	merge 1:1 provider year using "$data/Input/Rechnungslegung/GKV_Rechnungslegung"
	
	* Check success of merges
	
		// Not matched from GKV-Rechnungslegung
		tab provider if _merge==2
		drop if _merge==2
		
		// Not matched from dfg GKV ranking
		tab year if _merge==1
		tab provider if _merge==1 & year>2012 & year<2020
		// br if _merge==1 & year>2012 & year<2020
	
			/* Systematically missing
			- BKK Grillo-Werke -> only available on Bundesanzeiger for 2013
			*/

		// drop _merge identifier
		drop _merge
	
	
* ----------------------- FOCUS Money GKV test Rating ------------------------ *
	
* Merge with FOCUS Money GKV test rating	
	merge 1:1 provider year using "$data/Input/Ratings/FOCUS_Money_GKVtest"
	
	* Check success of merges
	
		// not matched from FOCUS Money GKV test 
		tab provider if _merge==2
		
		drop if _merge==2 & year!=2009
		drop _merge
				
				
* ------------------- Add-on premium 2009-2012 Pendzialek -------------------- *
		
* Merge with Pendzialek et al 2015 add-on 2009-2012 data
	merge 1:1 provider year using "$data/Input/Premium/ZB_2009_2012_Pendzialek"
		
	* Check success of merges
	
		// not matched from using data
		tab provider if _merge==2
		
		drop if _merge==2 & year!=2009
		drop _merge
		

* ------------------------------ Data cleaning ------------------------------- *
	
* Order variables
	order provider type gkv_type year rank members insured_avg insured insured_lead ///
		insured_change_abs insured_change_perc addon addon_change addon_diff_avg ///
		addon_diff_predicted addon_avg addon_predicted addon_abs addon_pct addon_dummy ///
		rebate_abs rebate_abs_dummy capital capital_pc capital_reserves capital_reserves_pc ///
		capital_admin capital_admin_pc revenue revenue_pc revenue_fund revenue_fund_pc ///
		revenue_addon revenue_addon_pc expenditure expenditure_pc expenditure_admin ///
		expenditure_admin_pc rating rating_relative merger merge_date comment_dfg comment_rechnungslegung

* Drop unrelevant variables
	drop gkv_type
		
* Adjust variables
	
	* Add-on and rebate 2009-2012
	foreach var in addon_abs addon_pct addon_dummy rebate_abs rebate_abs_dummy {
		replace `var' = 0 if `var'==.
		}
	
	* rename variables
	rename addon_abs addon09_abs
	rename addon_dummy addon09_dummy
	rename addon_pct addon09_pct
	rename rebate_abs rebate09_abs
	rename rebate_abs_dummy rebate09_dummy

	* encode variables
		// gkv type
		encode type, gen(gkv_type)
			drop type
			rename gkv_type type
		// provider
		encode provider, gen(id)
	
	* Back-out (proxy) average income pc by provider
	cap drop income_pc
	gen income_pc = (revenue_addon/members)*(100/addon)*(1/12) if revenue_addon!=. & revenue_addon!=0
	label var income_pc "Proxy for average income pc by provider-year (likely lower bound)"	
		
		sum income_pc, d
		replace income_pc=. if income_pc<100
		table type, c(mean income_pc)
	
	* Gen logged variables
		foreach var in members insured_avg insured insured_lead ///
			capital capital_pc capital_reserves capital_reserves_pc capital_admin ///
			capital_admin_pc revenue revenue_pc revenue_fund revenue_fund_pc revenue_addon ///
			revenue_addon_pc expenditure expenditure_pc expenditure_admin expenditure_admin_pc ///
			rating_relative rebate09_abs addon09_abs income_pc insured_initial addon {
		
			cap drop `var'_ln
			gen `var'_ln = ln(`var')
			}		
		
	* Generate DiD group variable over full range
	cap drop addon_did_group
	egen addon_did_group = max(addon_group_fixed), by(provider)
		label values addon_did_group addon_group_label
		
		tab addon_did_group
		
	* Change order of variables
	order provider type year
		
* Data consistency checks

	* Data availability by year
	table year, c(count insured count insured_change_abs count addon count revenue_fund ///
		count rating_relative)
		
	* members and insured individuals
	sum members insured_avg insured
	sum insured, d
	
	* change in insured individuals
		
		// absolute
		sum insured_change_abs, d
			tab provider if (insured_change_abs<r(p1) | insured_change_abs>r(p99)) & insured_change_abs!=.
	
		// percentage
		sum insured_change_perc, d
			tab provider if (insured_change_perc<r(p1) | insured_change_perc>r(p99)) & insured_change_perc!=.
	
		// relationship absolute and percentage change in insured individuals
		/* twoway (scatter insured_change_abs insured_change_perc) ///
			(lfit insured_change_abs insured_change_perc) /// 
			if insured_change_perc<28 & insured_change_perc>-6 ///
				& insured_change_abs<131536 & insured_change_abs>-103905 
		*/
		
	* addon premium
	sum addon addon_change addon_diff_avg addon_diff_predicted addon_avg addon_predicted ///
		addon09_abs addon09_pct rebate09_abs
	
	* Rechnungslegung stats
	sum capital_pc capital_reserves_pc capital_admin_pc revenue_pc revenue_fund_pc ///
		revenue_addon_pc expenditure_pc expenditure_admin_pc
	
	* Focus Money Rating
	sum rating rating_relative
	
* Save data
	drop if insured_lead==. & year==2009

	save "$data/Output/GKV_aggregate", replace
	export delimited  "$data/Output/GKV_aggregate.csv", replace delim(";")
