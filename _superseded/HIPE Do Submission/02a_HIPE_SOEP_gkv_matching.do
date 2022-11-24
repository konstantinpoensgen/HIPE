********************************************************************************
*************************** SOEP & GKV aggregate match *************************
********************************************************************************

* SOEP data preparation ------------------------------------------------------ *

* Load the merged soep data set
	use $output/soep_merge.dta, clear

* Set id and time variable
	xtset pid syear
	
* Keep relevent person-year observations only 
	
	* keep relevant year span only
		keep if syear>=2008
		
	* public vs. private health insurance
	
		// Generate lagged hi_type to also include switches from GKV to private
		cap drop hi_type_l
			gen hi_type_l = l.hi_type
			//tab syear if hi_type==2 & hi_type_l==1
			
		// Keep if current hi_type is GKV or current is PKV but lagged is GKV
		tab hi_type
		keep if hi_type==1 | (hi_type==2 & hi_type_l==1) 
			// since I don't have data on prices from PKV I can only analyse GKV -> PKV but not vice versa
	
	* compulsory, voluntary co-insured member
		tab hi_status
		keep if hi_status==1 | (hi_type==2 & hi_type_l==1) // keep "compulsory member" only
	
	* employment status
		tab employment_status
	    keep if employment_status==1 // keep "full-time" employed only
	
	* unemployed
		tab unemployed // since already keeping only "full-time" employed, the remaining umemployed==1 should be wrong
		keep if unemployed==0 

* Data cleaning

	* Income (gross)
	replace income_gross=. if income_gross<0 // replace "does not apply" with missing
	sum income_gross, d
		sum income_gross if income_gross<r(p1),d
		sum income_gross if income_gross<r(p75),d
		
		// drop unrealistc gross income levels
		drop if income_gross==0
		
	* Income (net)
	replace income_net=. if income_net<0
	sum income_net, d
	
		// drop unrealistic net income values
		drop if income_net==0

	* Health insurance

		// Name of health insurance provider

			* Replace name of provider with "PKV" when "private"
			replace hi_name=99 if hi_type==2  
				
				// Adjust labeling of hi_name
				label define hi_name_private -5 "Not in questionnaire" -2 "Does not apply" -1 "no answer" ///
					1 "AOK" 2 "Barmer/GEK" 3 "DAK-Gesundheit" 4 "TK" 5 "IKK/BIG" 6 "KKH/Allianz" 7 "GEK" ///
					8 "Knappschaft" 9 "LKK" 10 "Other company health insurance" 11 "Other" 99 "PKV" , replace
				
				label values hi_name hi_name_private
		
			* Keep only entries with information on provider name
			drop if hi_name<0 // drop when no information on provider and not 

* Create additional variables 

	*	Age
	cap drop age
		gen age = syear - birthyear
		sum age if syear==2018, d 
		
	* Adjust naming of health insurance providers
		
		cap drop provider
		gen provider = ""
	
		* Regional AOKs
			
			* Single state AOKs
			replace provider = "AOK Baden-Wuerttemberg" if hi_name==1 & bula==8 // Baden-Württemberg 				
			replace provider = "AOK Bayern" if hi_name==1 & bula==9 // Bayern 
			replace provider = "AOK Hessen" if hi_name==1 & bula==6 // Hessen 
			replace provider = "AOK Niedersachsen" if hi_name==1 & bula==3 // Niedersachsen 
			replace provider = "AOK Sachsen-Anhalt" if hi_name==1 & bula==15 // Sachsen-Anhalt 
			
			* Multiple state AOKS
				
				// AOK Bremen/Bremerhaven
				replace provider = "AOK Bremen/Bremerhaven" if hi_name==1 & bula==4 	// Bremen
			
				// AOK Nordost
				replace provider = "AOK Mecklenburg-Vorpommern" if hi_name==1 & bula==13 // Mecklenburg-Vorpommern
				replace provider = "AOK Berlin-Brandenburg" if hi_name==1 & (bula==11 | bula==12) // Berlin and Brandenburg				
				replace provider = "AOK Nordost" if hi_name==1 & syear>2010 & (bula==11 | bula==12 | bula==13)  // established 01.01.2011
			
				// AOK NordWest
				replace provider = "AOK Schleswig-Holstein" if hi_name==1 & bula==1  // Schleswig-Holstein
				replace provider = "AOK NordWest" if hi_name==1 & bula==1 & syear>2010 // established 01.10.2010
			
				// AOK PLUS
				replace provider = "AOK Sachsen" if hi_name==1 & bula==14 // Sachsen
				replace provider = "AOK Thueringen" if hi_name==1 & bula==16 // Thüringen
				replace provider = "AOK PLUS" if hi_name==1 & syear>2007 & (bula==14 | bula==16) // established 01.01.2008
								
				// AOK Rheinland-Pfalz/Saarland
				replace provider = "AOK Rheinland-Pfalz" if hi_name==1 & bula==7 // Rheinland-Pfalz
				replace provider = "AOK Saarland" if hi_name==1 & bula==10 	// Saarland
				replace provider = "AOK Rheinland-Pfalz/Saarland" if hi_name==1 & (bula==7 | bula==10) & syear>2012 // established 01.03.2012
				
				// AOK Rheinland/Hamburg
				replace provider = "AOK Rheinland/Hamburg" if hi_name==1 & bula==2 // Hamburg (NRW cannot be attributed)

			* Unattributtable Nordrhein-Westfalen AOK members
			replace provider = "AOK unattributable" if hi_name==1 & bula==5 // Nordrhein-Westfalen --> cannot be clearly assigned
			
		* vdek
		
			// Barmer
			replace provider = "Barmer Ersatzkasse (BEK)" if hi_name==2 & syear<2010
			replace provider = "Gmuender Ersatzkasse (GEK)" if hi_name==7 & syear<2010
			replace provider = "BARMER GEK" if hi_name==2 & syear>2009 & syear<2016 // established 01.01.2010
			replace provider = "BARMER" if hi_name==2 & syear>=2016 // established 01.01.2017 but label from 2016 onwards because of GKV aggregate data
			
			// DAK
			replace provider = "Deutsche Angestellten Krankenkasse" if hi_name==3 & syear<2012 
			replace provider = "DAK-Gesundheit" if hi_name==3 & syear>2011 // naming since 2012 
			
			// other vdek
			replace provider = "Techniker Krankenkasse (TK)" if hi_name==4
			replace provider = "KKH Kaufmaennische Krankenkasse" if hi_name==6
			replace provider = "Knappschaft" if hi_name==8
		
		* other types (non attributable)
			replace provider = "IKK/BIG" if hi_name==5
			replace provider = "LKK" if hi_name==9
			replace provider = "BKK" if hi_name==10
			replace provider = "Other" if hi_name==11
			
		* PKV
			replace provider = "PKV" if hi_name==99
					
	* Create "hi_switch" variable
	
		* Set panel variables
		xtset pid syear
	
		* Lagged health insurance provider 
		
			// encode provider variable
			cap drop provider_id
			encode provider, gen(provider_id)
			
			// lag encoded provider variable
			cap drop provider_id_l
				gen provider_id_l = l.provider_id
				label values provider_id_l provider_id
			
			// convert encoded provider-lag to string
			cap drop provider_l
				decode provider_id_l, gen(provider_l)
				
			// drop unrelevant encoded variables
			cap drop provider_id provider_id_l
			
		* Generate provider-switch variable
		cap drop hi_switch
			gen hi_switch = .
			
				* Create general "switch" variable
				replace hi_switch = 0 if provider==provider_l & provider!="" & provider_l!=""
				replace hi_switch = 1 if provider!=provider_l  & provider!="" & provider_l!=""
				
				* Set switch to 0 when name_change/merge of health provider
				
						// AOK Nordost
						replace hi_switch = 0 if provider=="AOK Nordost" & syear==2011 & ///
							(provider_l=="AOK Mecklenburg-Vorpommern" | provider_l=="AOK Berlin-Brandenburg")
				
						// AOK NordWest
						replace hi_switch = 0 if provider=="AOK NordWest"& syear==2011 & ///
							provider_l=="AOK Schleswig-Holstein"
						
						// AOK PLUS
						replace hi_switch = 0 if provider=="AOK PLUS" & syear==2008 & ///
							(provider_l=="AOK Sachsen" | provider_l=="AOK Thueringen")
 						
						// AOK Rheinland-Pfalz/Saarland
						replace hi_switch = 0 if provider=="AOK Rheinland-Pfalz/Saarland" & ///
							syear==2013 & (provider_l=="AOK Rheinland-Pfalz" | provider_l=="AOK Saarland")
						
						// Barmer
							// Barmer + GEK -> BARMER GEK
							replace hi_switch = 0 if provider=="BARMER GEK" & syear==2010 & ///
								(provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)")
							// BARMER GEK -> BARMER 
							replace hi_switch = 0 if provider=="BARMER" & syear==2016 & ///
								provider_l=="BARMER GEK"
								
						// DAK
						replace hi_switch = 0 if provider=="DAK-Gesundheit" & syear==2012 ///
							& provider_l=="Deutsche Angestellten Krankenkasse"
						replace hi_switch = 0 if provider=="DAK-Gesundheit" & syear==2012 ///
							& provider_l=="BKK" // since M&A with BKK "Deutsche BKK"
												
						//br pid syear provider provider_l hi_switch if hi_switch==1
						
						
		* Overview amount of switches per year
			
			// Total number of switches
			table syear hi_switch, c(count pid) row column
			
			// Effective number of switches with info on add-on
			table syear hi_switch if provider_l!="IKK/BIG" & provider_l!="LKK" & provider_l!="BKK" ///
				& provider_l!="PKV" & provider!="Other" & provider_!="AOK unattributable" ///
				& provider_l!="AOK Saarland" & provider_l!="AOK Rheinland-Pfalz" & provider!="AOK Schleswig-Holstein" ///
				& provider_l!="AOK Sachsen" & provider_l!="AOK Thueringen" ///
					, c(count pid) row column

		
		* Drop 2008 variables (not needed anymore)
		drop if syear==2008
		
* Prepare merge with GKV_aggregate data
	
	* Rename year variable
	rename syear year
	
				
* Match GKV aggregate data ----------------------------------------------------*
	
* Merge price data 2015-2018 from GKV-Spitzenverband

	merge m:1 provider year using "$data/Output/GKV_aggregate.dta"
		
		// drop unrelevant years
		drop if year>2018
		
		// check success of merge
		tab _merge
		
			// main period 2015-2018
			tab _merge if year>2014 
			
			// which providers are matched?
			tab provider if _merge==3
		
			// which provider are not matched?
			tab provider if _merge==2
			
				tab year if provider=="AOK Rheinland-Pfalz/Saarland" & _merge==2 // 2012 fine; established only 01.03.2012
				tab year if provider=="DAK-Gesundheit" & _merge==2 // 2011 fine; renamed 2012
				
				// drop unmatched information on providers from USING data
				drop if _merge==2
		
			// which providers are unmatched among master data?
			tab provider if _merge==1 & year>2009 // all seems fine. Note that no information on AOK Schleswig-Holstein
	
			// drop _merge identifier
			drop _merge
	
* Match counterfactual price data of "lagged" (coming_from) provider in "current" year
					
	* Prepare essential GKV aggregate data
		preserve 
		
			* Load GKV_aggregate data
			use "$output/GKV_aggregate.dta", clear
		
			* Keep relevant variables only
			keep provider type year addon addon_change addon_diff_avg addon_diff_predicted ///
				addon09_abs addon09_pct addon09_dummy rebate09_abs rebate09_dummy capital_pc_ln ///
				capital_reserves_pc_ln revenue_fund_pc_ln revenue_addon_pc_ln expenditure_admin_pc_ln ///
				rating rating_relative income_pc_ln members_ln
			
			* Rename variables
		
				// Rename provider to match provider_l in soep data
				rename provider provider_l
			
				// Rename data for current year to signal "prior" provider
				foreach var in type addon addon_change addon_diff_avg addon_diff_predicted ///
					addon09_abs addon09_pct addon09_dummy rebate09_abs rebate09_dummy capital_pc_ln ///
					capital_reserves_pc_ln capital_reserves_pc revenue_fund_pc_ln revenue_addon_pc_ln ///
					expenditure_admin_pc_ln expenditure_admin_pc ///
					rating rating_relative income_pc_ln members_ln {
					
						rename `var' `var'_prior	
				}
			
			* save temp version for match 
			save "$temp/temp.dta", replace
		
		restore
		
	* Match data with prior-adjusted GKV_aggregate data
	
		* rename entries of provider when necessary
		
			// Barmer
			replace provider_l = "BARMER" if provider_l=="BARMER GEK" & year==2016
			replace provider_l = "DAK-Gesundheit" if provider_l=="Deutsche Angestellten Krankenkasse" & year==2012
		
		* Perform actual match
		merge m:1 provider_l year using "$temp/temp.dta"
		
			// drop unsucessful merges and _merge identifier
			drop if _merge==2
			drop _merge
	
	
* Adjust variables and create additional variables --------------------------- *

	* addon09_dummy
	replace addon09_dummy = 0 if year==2009 & provider!="PKV"
	replace addon09_dummy_prior = 0 if year==2009 & provider!="PKV"
	
	* Exploratory browse data for consistency & quality

		// Dummy for addon premium
		table year, c(mean addon09_dummy) by(provider) 
		table year, c(mean addon09_dummy_prior) by(provider_l) 
	
		// addon (premium level)
		table year if year>2014, c(mean addon mean addon_change mean addon_diff_avg) by(provider)
		table year if year>2014, c(mean addon_prior mean addon_change_prior mean addon_diff_avg_prior) by(provider_l)


		/* Additional browse for consistency check:

			br pid year provider provider_l hi_switch addon addon_prior ///
				addon_l addon_prior_l ///
				addon_change addon_change_prior addon_diff_avg addon_diff_avg_prior ///
				if year>2014
	
			br pid year provider provider_l hi_switch addon addon_prior ///
				addon_change addon_change_prior addon_diff_avg addon_diff_avg_prior ///
				if year>2014 & hi_switch==1
		
		*/	
		
	* Set panel var
	sort pid year
	xtset pid year
		
	* hi_switch lead 
	cap drop hi_switch_lead
		gen hi_switch_lead = f.hi_switch
		
	* addon difference after change
	cap drop addon_diff_prior
		gen addon_diff_prior = addon - addon_prior
			sum addon_diff_prior if hi_switch==1, d
		
	* lagged addon variables -> for "forward" effect of addon premium
	foreach var in addon addon_change addon_diff_avg addon_diff_predicted ///
		addon09_dummy rebate09_dummy {
	
		cap drop `var'_l
			gen `var'_l = l.`var'
	}
	
		* Adjust lagged variables in 2015
		
			// Generate identifer for provider_l without information
			cap drop exclude
				gen exclude = 1 if provider_l=="BKK" | provider_l=="Other" ///
					| provider_l=="PKV" | provider_l=="LKK" | provider_l=="IKK/BIG"  
				
			// change 2015 values for relevant providers -> all providers effectively had 0.9 in 2014
			replace addon_l = 0.9 if year==2015 & exclude!=1		
			replace addon_change_l = 0 if year==2015 & exclude!=1		
			replace addon_diff_avg_l = 0 if year==2015 & exclude!=1	
			replace addon_diff_predicted_l = 0 if year==2015 & exclude!=1
					
			// show table for accurateness check
			table year if year>2014, c(mean addon_l) by(provider_l)
		
			
* check values of control variables

	// log additional variables
	foreach var in income_gross income_net age {
		cap drop `var'_ln 
		gen `var'_ln = log(`var')
		}

	* education variables
	
		// education degree
		cap drop degree 
			gen degree = .
				label var degree "Highest degree (derived based on isced1997)"
			
				replace degree = 1 if educ_degree_isced1997==1 | educ_degree_isced1997==2
				replace degree = 2 if educ_degree_isced1997==3 | educ_degree_isced1997==4
				replace degree = 3 if educ_degree_isced1997==5 | educ_degree_isced1997==6
				
				label define degree 1 "Primary" 2 "Secondary" 3 "Tertiary"
				label values degree degree
				
		// tertiary
		cap drop tertiary
			gen tertiary = 0
			replace tertiary = 1 if degree==3
				
	* occupation
	
		// occupation based on ISCO-08 major groups
		cap drop isco08 
			gen isco08 = . 
				replace isco08 = 0 if occupation_isco08>0 & occupation_isco08<1000
				replace isco08 = 1 if occupation_isco08>=1000 & occupation_isco08<2000
				replace isco08 = 2 if occupation_isco08>=2000 & occupation_isco08<3000
				replace isco08 = 3 if occupation_isco08>=3000 & occupation_isco08<4000
				replace isco08 = 4 if occupation_isco08>=4000 & occupation_isco08<5000
				replace isco08 = 5 if occupation_isco08>=5000 & occupation_isco08<6000
				replace isco08 = 6 if occupation_isco08>=6000 & occupation_isco08<7000
				replace isco08 = 7 if occupation_isco08>=7000 & occupation_isco08<8000
				replace isco08 = 8 if occupation_isco08>=8000 & occupation_isco08<9000
				replace isco08 = 9 if occupation_isco08>=9000 & occupation_isco08<10000
			
			label var isco08 "Occupation according to isco08 (pgisco08)"
			label define isco08_major 0 "Armed forces" 1 "Managers" 2 "Professionals" 3 "Technicians and associate professionals" ///
				4 "Clerical support workers" 5 "Services and sales workers" 6 "Skilled agriculture" ///
				7 "Craft and related trade" 8 "Pland and machine operators/assemblers" ///
				9 "Elementary occupations" , replace
			label values isco08 isco08_major
			
		// NACE occupation sector classification
		cap drop nace 
			gen nace = "" 
			
				// Assign broad nace (1) categories
				replace nace = "Agriculture/forestry/fishing" if occupation_nace>=1 & occupation_nace<=5
				replace nace = "Mining/quarrying" if occupation_nace>=10 & occupation_nace<=14
				replace nace = "Manufacturing" if occupation_nace>=15 & occupation_nace<=37
				replace nace = "Electricity/gas/water" if occupation_nace>=40 & occupation_nace<=44
				replace nace = "Construction" if occupation_nace==45
				replace nace = "Wholesale/trade" if occupation_nace>=50 & occupation_nace<=54
				replace nace = "Hospitality" if occupation_nace==55
				replace nace = "Transport/storage/communication" if occupation_nace>=60 & occupation_nace<=64
				replace nace = "Financial services" if occupation_nace>=65 & occupation_nace<=67
				replace nace = "Real estate/renting/other business" if occupation_nace>=70 & occupation_nace<=74
				replace nace = "Public admin/defense" if occupation_nace==75
				replace nace = "Education" if occupation_nace==80
				replace nace = "Health/social" if occupation_nace==85
				replace nace = "Electricity/gas/water" if occupation_nace>=40 & occupation_nace<=44
				replace nace = "other" if occupation_nace>=90
				
				// replace very small categories
				tab nace
					replace nace = "other" if nace=="Mining/quarrying"
					
				// encode variable 
				encode nace, gen(nace2)
					drop nace
					rename nace2 nace					
	
	* marital status
	cap drop married
		gen married = ""
			replace married = "married" if marital_status==1 | marital_status==6 | marital_status==7 | marital_status==8 
			replace married = "single" if marital_status==3 
			replace married = "divorced/separated" if marital_status==2 | marital_status==4
			replace married = "widowed" if marital_status==5
		
		cap drop married2
		encode married, gen(married2)
			drop married
			rename married2 married	
	
	* rename variables
		rename sex gender
			label define gender 1 "Men" 2 "Women", replace
			label values gender gender
		rename ple0053 hospital_stay 
			label var hospital_stay "Hospital Stay Prev. Year (ple0053)"
		rename ple0072 doctor_visits
			label var doctor_visits "Number of doctor visits (ple0072)"
	
	* replace SOEP missing codification with Stata missing
	foreach var in educ_degree educ_degree_isced2011 educ_degree_isced1997 ///
		educ_years health_view health_satisfaction health_worried ///
		active_sport marital_status reported_sick companysize hospital_stay ///
		doctor_visits ///
		 {
		replace `var' = . if `var'<0
		}
				
	
* Drop data with no information on switch 
	drop if hi_switch==. & hi_switch_lead==. // only keep information with clear switch info
	
* Complete missing GKV information ------------------------------------------- *

	* Type/provider
	
		* AOKen
		replace type = 1 if provider=="AOK Baden-Wuerttemberg" | provider=="AOK Bayern" | provider=="AOK Berlin-Brandenburg" ///
			| provider=="AOK Bremen/Bremerhaven" | provider=="AOK Hessen" | provider=="AOK Mecklenburg-Vorpommern" | provider=="AOK Niedersachsen" ///
			| provider=="AOK PLUS" | provider=="AOK Rheinland-Pfalz" | provider=="AOK Rheinland/Hamburg" | provider=="AOK Saarland" ///
			| provider=="AOK Sachsen-Anhalt" | provider=="AOK Schleswig-Holstein" | provider=="AOK unattributable" 
			
		* Knappschaft
		replace type = 4 if provider=="Knappschaft" // kn
		
		* vdek
		replace type = 6 if provider=="Barmer Ersatzkasse (BEK)" | provider=="Deutsche Angestellten Krankenkasse" | provider=="Gmuender Ersatzkasse (GEK)" ///
			| provider=="KKH Kaufmaennische Krankenkasse" | provider=="Techniker Krankenkasse (TK)"
		
		* BKK
		replace type = 2 if provider=="BKK"
		
		* IKK
		replace type = 3 if provider=="IKK/BIG"
		
		* LKK
		replace type = 5 if provider=="LKK"
		
		* Other
		replace type = 7 if provider=="Other"
		
		* PKV
		replace type = 8 if provider=="PKV" 
		
		* Label define 
		label define type 1 "AOK" 2 "BKK" 3 "IKK" 4 "Kn" 5 "LKK" 6 "vdek" 7 "Other" 8 "PKV", replace
		label values type type
		
		// export check-file
		preserve
			bysort provider year: gen count = _n 
			keep if count==1
			keep year provider type addon addon_change addon_diff_avg addon_diff_predicted addon_avg ///
				addon09_dummy rating rating_relative
		
			export delimited "$temp/temp_gkv_check.csv", replace delim(";")	
		restore
		
	* Type_prior/provider_prior
	
		* AOKen
		replace type_prior = 1 if provider_l=="AOK Baden-Wuerttemberg" | provider_l=="AOK Bayern" | provider_l=="AOK Berlin-Brandenburg" ///
			| provider_l=="AOK Bremen/Bremerhaven" | provider_l=="AOK Hessen" | provider_l=="AOK Mecklenburg-Vorpommern" | provider_l=="AOK Niedersachsen" ///
			| provider_l=="AOK PLUS" | provider_l=="AOK Rheinland-Pfalz" | provider_l=="AOK Rheinland/Hamburg" | provider_l=="AOK Saarland" ///
			| provider_l=="AOK Sachsen-Anhalt" | provider_l=="AOK Schleswig-Holstein" | provider_l=="AOK unattributable" 
			
		* Knappschaft
		replace type_prior = 4 if provider_l=="Knappschaft" // kn
		
		* vdek
		replace type_prior = 6 if provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Deutsche Angestellten Krankenkasse" | provider_l=="Gmuender Ersatzkasse (GEK)" ///
			| provider_l=="KKH Kaufmaennische Krankenkasse" | provider_l=="Techniker Krankenkasse (TK)"
		
		* BKK
		replace type_prior = 2 if provider_l=="BKK"
		
		* IKK
		replace type_prior = 3 if provider_l=="IKK/BIG"
		
		* LKK
		replace type_prior = 5 if provider_l=="LKK"
		
		* Other
		replace type_prior = 7 if provider_l=="Other"
		
		* PKV
		replace type_prior = 8 if provider_l=="PKV" 
		
		* Label define 
		label values type_prior type
		
	* addon09_dummy_prior
	
		replace addon09_dummy_prior = 0 if provider_l=="AOK Berlin-Brandenburg" | provider_l=="AOK Mecklenburg-Vorpommern" | provider_l=="AOK Schleswig-Holstein" | provider_l=="AOK Saarland"
			
		replace addon09_dummy_prior = 0 if (provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)") & year==2010
		
	
	* rating prior
	
		// Barmer Ersatzkasse (BEK) in 2010
		replace rating_prior = 157.73 if (provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)") & year==2010 
		replace rating_relative_prior = 99.56 if (provider_l=="Barmer Ersatzkasse (BEK)" | provider_l=="Gmuender Ersatzkasse (GEK)") & year==2010 
		
		// export check-file
		preserve
			bysort provider_l year: gen count = _n 
			keep if count==1
			keep year provider_l type_prior addon_prior addon_change_prior addon_diff_avg_prior ///
				addon_diff_predicted_prior addon_avg addon09_dummy_prior rating_prior rating_relative_prior
		
			export delimited "$temp/temp_gkv_check.csv", replace delim(";")	
		restore
		
		
* Exporting ------------------------------------------------------------------ *
		
* Save
save "$output/soep_gkv_match.dta", replace


* SCRIPT END
