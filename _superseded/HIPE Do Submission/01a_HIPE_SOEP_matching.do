********************************************************************************
*************************** SOEP DATA MATCHING *********************************
********************************************************************************

cap log close 
clear all

* 	Preliminary settings 
	cd $soep
	
*	Set local for checks (for speed of code)
	local checks 0
	
/*	Export SOEP varlabels

	use hbrutto.dta, clear
	label language EN
	keep if hid==1
	set obs 1
	export excel using "$soep_description/variables/SOEP_v35i_variables_ppathl", firstrow(variables) replace
	export excel using "$soep_description/variables/SOEP_v35i_varlabels_ppathl", firstrow(varlabels) replace
	
	*/
	
	
* ---------------------- SOEP individual identifier ---------------------------*
	
/* 	Objective: 
	- Create a "base" pid set that will be used for later merges
	*/	
	
*	Load individual identifiers (ppathl)
	use ppathl.dta, clear
	
*	General data checks	
	
	if `checks'==1 {
	
		// Level of granularity 
		duplicates report pid syear // -> unique by person-year entry
	
		// IDs per year
		table syear
		
		}
	
*	Relevant variables only
	keep cid hid pid syear sex gebjahr erstbefr austritt letztbef netto ///
		todjahr todinfo immiyear germborn corigin gebmonat migback sexor arefback /// 
		parid partner piyear
	
*	Relevant time span only
	keep if syear>=2008
	
*	Quick variable check
	
		// Year of birth
		tab gebjahr
		drop if gebjahr>syear // 2 obs. 
	
		// First time interviewed
		tab erstbefr
		
			* Investigate first time interviewed = -2
			//br pid syear gebjahr erstbefr letztbef austritt piyear if erstbefr==-2
			//br if pid==1203003
			// Note: "-2" means -> "does not apply"
		
				// Change "does not apply" to missing
				replace erstbefr=. if erstbefr==-2
		
			// Netto
			tab netto
			tab netto if netto>=80
			tab syear if netto==10 | netto==12 | netto==13
			
	if `checks'==1 {
	
		// Exiting the sample
		tab letztbef
	
			* What does it mean if letztbef < syear OR letztbef < piyear?
			tab piyear
			tab piyear if letztbef < piyear 
		
			// br if letztbef < piyear & piyear==2019
			// br if letztbef < syear & letztbef!=-2
		
			// How does it square with Austritt?
			tab austritt
			tab piyear if austritt < piyear
			tab syear if austritt < syear // no observations
			//br if austritt < piyear
			
		// Refugee background
		tab arefback // tab arefback, nolab
	}

*	Export cleaned ppathl
	save "$soep_cleaned/ppathl_c.dta", replace

	
* ------------------------------ SOEP hbrutto ---------------------------------*

*	Load hbrutto
	use hbrutto.dta, clear

*	Check level of granularity
	*duplicates report hid syear // unique on household-year level
	
*	Keep relevant variables only
	keep hid syear htyp bula
	
*	Keep relevant years only
	keep if syear>=2008
	
*	Export "cleaned" (reduced) hbrutto
	save "$soep_cleaned/hbrutto_c.dta", replace
	
	
* ----------------------- SOEP individual pbrutto -----------------------------*
	
*	Load SOEP individual pbrutto 
	use pbrutto.dta, clear
	
*	General checks

	if `checks'==1 {
	
		// Level of granularity
		duplicates report pid syear // unique on person-year level
	
		// Person observations per year
		tab syear
	}
	
*	Keep relevant year span only
	keep if syear>=2008
	
*	Keep relevant variables only
	keep abwesj_h auszugj_h	befstat	cid	dj einzugj_h geburt_v2	/// 
		hhnrold	hid	hk inputdataset	kogzahl	lint_h monin panker	///
		pherkft	pid	pnat_h pnat2	pnrneu	pzug sex	stell_h	stistat	syear ///
		tagin varpnat1 varpnat2	varsex zupan_h

*	Quality checks and cleaning
	
		// Age of birth
		drop if geburt_v2>syear

*	Export cleaned pbrutto
	save "$soep_cleaned/pbrutto_c.dta", replace
	
	
* -------------------------- SOEP individual pgen -----------------------------*

*	Load SOEP individual pgen
	use pgen.dta, clear
	label language EN

*	General checks

	if `checks'==1 {

		// Level of granularity
		duplicates report pid syear // unique on person-year level
	
		// Year coverage
		tab syear
	}
	
*	Relevant year range
	keep if syear>=2008

*	Export cleaned pgen
	save "$soep_cleaned/pgen_c.dta", replace
 
* ------------------------- SOEP individual health ----------------------------*

*	Load SOEP individual health
	// use health.dta, clear
	
		// no checks required
		
	
	
********************************************************************************	
****************************** SOEP MATCHING ***********************************
********************************************************************************
	
* ------------------------- SOEP individual panel -----------------------------*
	
*	Load SOEP individual questionnaire panel (pl) 
	use pl.dta, clear
	label language EN
	
*	General checks
	
	if `checks'==1 {
	
		// Level of granularity 
		duplicates report pid syear // unique on this level	
	} 
	
*	Keep relevant years
	keep if syear>=2008
	
*	Keep relevant variables only
	keep pid hid cid syear plb0021 plb0022_h plb0024_h plb0031_v2 plb0040 ///
		plb0041 plb0058 plb0065 plb0586 plb0635 plc0014_h plc0016 plc0091_h ///
		plc0111 plc0113 plc0112 plc0114 plc0168_h plc0171_h plc0176 plc0177 ///
		plc0220_h plc0313_h plc0328 plc0329 plc0349 plc0430 plc0431 plc0433 ///
		plc0440 plc0443 plc0446 plc0500 plc0502_h plc0557 plc0560 plc0567 /// 
		plj0626 pld0131 pld0132_h pld0140 ple0003 ple0004 ple0005 ple0006 ///
		ple0007 ple0008 ple0009 ple0010_h ple0012 ple0011 ple0013 ple0014 ///
		ple0015 ple0016 ple0017 ple0018 ple0019 ple0020 ple0021 ple0022 ///
		ple0023 ple0024 ple0025 ple0026 ple0027 ple0028 ple0029 ple0030 ///
		ple0031 ple0032 ple0033 ple0034 ple0035 ple0036 ple0037 ple0038 ///
		ple0039 ple0040 ple0041 ple0044_h ple0046 ple0048 ple0049 ple0053 ///
		ple0055 ple0056 ple0071 ple0072 ple0073 ple0081_h ple0082 ple0084 ///
		ple0090 ple0091 ple0092 ple0093 ple0094 ple0097 ple0098_v5 ple0099_h ///
		ple0099_v5 ple0102 ple0104_h ple0104_v9 ple0104_v8 ple0104_v11 ple0104_v7 ///
		ple0104_v10 ple0106 ple0107 ple0107 ple0109 ple0110 ple0111 ple0112 ///
		ple0113 ple0114 ple0115 ple0116 ple0117 ple0118 ple0119 ple0120 ///
		ple0121 ple0126 ple0128_h ple0128_v2 ple0128_v2 ple0130 ple0131 ///
		ple0132 ple0133 ple0135 ple0136_h ple0136_v2 ple0137  ple0138_h ///
		ple0140 ple0141 ple0160 ple0161 ple0162 ple0164 ple0165 ple0167 ///
		ple0176 ple0177 ple0178 ple0187 plg0012 plg0015_h plg0037 plg0038 ///
		plg0196 plg0215 plh0004 plh0007 plh0011_h plh0016 plh0035 plh0171 ///
		plh0258_h plh0263_h pli0092_h pli0162 pli0163 pli0164 plm0577 plj0615


* ----------------------------- Data Merging ---------------------------------*

// pl serves as the starting point, then join prutto, ppathl, pgen and health
// Merging identifiers are: pid cid hid syear


*	Join pbrutto
	merge 1:1 pid cid hid syear using "$soep_cleaned/pbrutto_c.dta", gen(merge_pbrutto)
	
		// 	Check for successful merges
		
		* 	Not in rhs but in master
			//br if merge_pbrutto==1 // 1 obs unmatched from master
			drop if merge_pbrutto==1
		
			* Not in master but in rhs 
			drop if merge_pbrutto==2 // many obs but irrelevant since need master info
		
			* drop redundant _merge variable
			drop merge_pbrutto

*	Join ppathl
	merge 1:1 pid cid hid syear using "$soep_cleaned/ppathl_c.dta", gen(merge_ppathl)

		// Check for successful merges -> all master obs are matched
		drop if merge_ppathl==2 
		drop merge_ppathl

*	Join pgen
	merge 1:1 pid syear using "$soep_cleaned/pgen_c.dta", gen(merge_pgen)
	
		// Check for successful merges -> all master obs are matched
		drop if merge_pgen==2 // 5000+ obs but cannot be used since needing master info
		drop merge_pgen
	
*	Join health
	merge 1:1 pid cid syear using "$soep/health.dta", gen(merge_health)
	
		// Check for successful merges -> all master obs are matched
		drop if merge_health==2
		drop merge_health

*	Join hbrutto
	merge m:1 hid syear using "$soep_cleaned/hbrutto_c.dta", gen(merge_hbrutto)
		
		// Check for successful merges
		drop if merge_hbrutto==2
		
		
* -------------------- Rename and adjust control variables --------------------*

* Employment

	// unemployed
		// tab syear if plb0021==-5 -> was not included for quite some entries in 2016
	cap drop unemployed
	gen unemployed = 1 if plb0021==1 // [1] == "Yes"
		replace unemployed = 0 if plb0021==2 // [2] == "No"
		label var unemployed "Unemployment status (plb0021)"
	
	// employment_status
	tab plb0022_h
	rename plb0022_h employment_status // note: plb0022_h slightly more granular than pgemplst
		label var employment_status "Employment type status (plb0022_h)"
		replace employment_status=. if employment_status<0 // (recode SOEP "no answer")
		
	// job change
	rename plb0031_v2 job_change
		label var job_change "Job change in previous year (plb0031_v2)"
		replace job_change=. if job_change<0 // recode SOEP missing
		replace job_change=1 if (job_change==3 | job_change==1)
		replace job_change=0 if job_change==2 // such that job_change is {0,1} dummys
	
	// civil service job
	rename pgoeffd civil_service
		label var civil_service "Civil service job (pgoeffd)"
		replace civil_service=. if civil_service<0 
		
	// self-employment
	rename plb0586 self_employment
		label var self_employment "Currently self-employed (plb0586)"
		//tab syear if self_employment==-8 // seems like variable not in data set prior to 2014
		
	// labor force status
	rename pglfs laborforce 
		label var laborforce "Labor force status (pglfs)"
		replace laborforce=. if laborforce<0
			
	// company size
	rename pgallbet companysize
		//tab syear if companysize<0 // no systematic missings
		label var companysize "Core category size of the company (pgallbet)"
			
	* Occupation	
			
		// occupational position
		rename pgstib occupation_position
			label var occupation_position "Occupational position (pgstib)"
	
		// Occupational change
		rename pgjobch occupation_change
			label var occupation_change "Occupational change (pgjobch)"
			replace occupation_change=. if occupation_change<0

		// Occupation ICSO-08
		rename pgisco08 occupation_isco08
			//tab syear if occupation_isco08==-8 // spike in 2009
			label var occupation_isco08 "ISCO-08 occupational classification (pgisco08)"
				
		// Occupation KldB2010
		rename pgkldb2010 occupation_kldb2010
			//tab syear if occupation_kldb2010==-8 // spike in 2008 and 2011 
			label var occupation_kldb2010 "KldB2010 occupational classification (pgkldb2010)"
				
		// Industry occupation pgnace
		rename pgnace occupation_nace
			//tab syear if occupation_nace==-8 // only 2018
			label var occupation_nace "NACE occupation sector classification (pgnace)"
			
* Income/financials
	
	// income (net)
	rename pglabnet income_net 
		label var income_net "Net income last month Nettoverdienst (pglabnet)"
		
	// income (gross) 
	rename pglabgro income_gross
		label var income_gross "Current gross labor income in Euro (pglabgro)"
	
	// secondary job income (gross)
	rename pgsndjob income_gross_second
		label var income_gross_second "Current gross secondary income in Euro (pgsndjob)"	
		
	// Riester-Rente
	rename plc0313_h riester
		//tab syear if riester>0 // only asked in some years
		label var riester "Abschluss Riester-Rente (plc0313_h)"

	// Ruerup-Rente
	rename plc0430 ruerup
		//tab syear if ruerup>0 // only asked in some years
		label var ruerup "Ruerup-Pension (plc0430)"
	
* Health status
	
	// reported sick in past year (>6 weeks)
	rename plb0024_h reported_sick 
		//tab syear if reported_sick==-5 // relatively consistent for 2014 onwards
		label var reported_sick "Reported sick > 6 weeks in previous year (plb0024_h)"
		replace reported_sick=. if reported_sick<0 // recode SOEP "no answer" etc.
	
	// current helth
	rename ple0008 health_view 
		label var health_view "Current health (ple0008)"
		
	// worried about own health
	rename plh0035 health_worried
		//tab syear if health_worried==-5 // number of questionnaires without this question 2011-2013
		label var health_worried "Worried about own health (plh0035)"
		
	// satisfaction with health
	rename plh0171 health_satisfaction
		label var health_satisfaction "Satisfaction with health (plh0171)"	
		
	* Specific diagnosis/diseases	
	
		// diabetes
		rename ple0012 diabetes
			label var diabetes "Diabetes (ple0012)"
		
		// sleep disturbances
		rename ple0011 sleep_disturbances
		label var sleep_disturbances "Sleep disturbances (ple0011)"
		
		// asthma 
		rename ple0013 asthma
			label var asthma "Asthma (ple0013)"
		
		// cardiopathy
		rename ple0014 cardiopathy
			label var cardiopathy "Cardiopathy (ple0014)"
	
		// cancer
		rename ple0015 cancer
			label var cancer "Cancer (ple0015)"
		
		// apoplepctic stroke
		rename ple0016 apoplectic_stroke
		label var apoplectic_stroke "Apoplectic stroke (ple0016)"
		
	// active sport
	rename pli0092_h active_sport
		label var active_sport "Active sport (pli0092_h)"
		
* Individual biographical
	
	// Birth year
	rename gebjahr birthyear
		label var birthyear "Birth year (gebjahr)"
		
	// Marital status
	rename pgfamstd marital_status
		label var marital_status "Marital status in survey year (pgfamstd)"		
		
	// Divorced
	rename pld0140 divorced
		label var divorced "Divorced (pld0140)"

* Health insurance
	
	// Type of health insurance
	rename ple0097 hi_type
		label var hi_type "Health insurance type (ple0097)"
	
	// Private supplementary health insurance
	rename ple0098_v5 hi_psupp
		label var hi_psupp "Private supplementary health insurance (ple0098_v5)"
		
	// Insuree status
	rename ple0099_h hi_status
		label var hi_status "Health insurance insuree status (ple0099_h)"
		
	// Private insuree status
	rename ple0102 hi_pstatus
		label var hi_pstatus "Private health insurance insuree status (ple0102)"
		
	// Name health insurance
	rename ple0104_h hi_name
		label var hi_name "Health insurance provider name (ple0104_h)"			
		
	// Contribution to private supplementary health insurance
	rename ple0128_h hi_psupp_contribution
		label var hi_psupp_contribution "Contribution for private supp. ins. (ple0128_h)"
		
	// Private insurance contribution
	rename ple0136_h hi_p_contribution
		label var hi_p_contribution "Monthly contribution private health insurance (ple0136_h)"
		
	* Coverage health insurance 
		
		// Hospital stay
		rename ple0130 coverage_hospital
			label var coverage_hospital "HI hospital stay covered (ple0130)"
			
		// Dentures covered
		rename ple0131 coverage_dentures
			label var coverage_dentures "HI dentures covered (ple0131)"
			
		// ...
				
			
* Education
	
	// Number of years in education or training
	rename pgbilzeit educ_years
		label var educ_years "Amount of education/training in years (pgbilzeit)"
		
	// School-leaving degree
	rename pgpsbil educ_degree
		label var educ_degree "School-leaving degree (pgpsbil)"
		
	// ISCED-2011 degree classification
	rename pgisced11 educ_degree_isced2011
		label var educ_degree_isced2011 "School degree according to ISCED-2011 classification (pgisced11)"
		
	// ISCED-1997 degree classification
	rename pgisced97 educ_degree_isced1997
		label var educ_degree_isced1997 "School degree according to ISCED-1997 classification (pgisced97)"			
		
	// Vocational degree received
	rename pgpbbil01 educ_degree_voc
		label var educ_degree_voc "Vocational degree received (pgpbbil01)"
		
	// Field of tertiary education
	rename pgfield educ_tertiary_field
		label var educ_tertiary_field "Field of tertiary education (pgfield)"
		
	// Type of tertiary education
	rename pgdegree educ_tertiary_type
		label var educ_tertiary_type "Type of tertiary degree (pgdegree)"
		
	
* ------------------------------ Exporting -----------------------------------*
		
*	Export merge
	save $output/soep_merge.dta, replace
		
		
* SCRIPT END
