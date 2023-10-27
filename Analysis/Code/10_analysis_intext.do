********************************************************************************
*************************** SOEP & GKV SUMMARY STATS ***************************
********************************************************************************

/* 	OBJECTIVES
	- Explore the data with summary statistics
	- Export sum stats for (i) insurer switches and (ii) covariates
	
	OUTLINE
	0) Preliminaries
	1) SOEP Summary Statistics

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
log using "$logs_analysis/`date'_analysis_intext.log", text replace	

* Open intext file
cap file close myfile
local date $date
file open myfile using "$intext/`date'_in_text_results.tex", write replace


* 1) SOEP Summary Statistics
* ---------------------------------------------------------------------------- *

* Load data 
use if year>=2015 & year<=2018 using "$data_final/soep_gkv_match_cleaned.dta", clear
	
	* 1.1) Number of observations in sample
	* ........................................................................ *

	/* The sample of interest---full-time employed individuals with compulsory 
	health insurance---includes \SampleSoepFullUnique{} individuals, or 
	\SampleSoepFullObs{} person-year observations between 2015--2018 (Table XX). 
	Insurer-level data can be matched to \SampleSoepHIMatch{}\% of these 
	person-year observations. Since data is not year-balanced for all participants, 
	the timing of provider switches can only be determined for \SampleSoepInfoObs{} 
	person-year observations. This final sample size includes \SampleSoepInfoUnique{} 
	unique individuals.*/

	* Full sample of interest 
	distinct pid 																// 47,339 (11,403)
	local sample_soep_full_obs 		= `r(N)'
	local sample_soep_full_unique 	= `r(ndistinct)'

	* & Able to merge insurer information
	distinct pid if !inlist(provider_l, "BKK", "IKK/BIG", "LKK", "Other", "PKV")	// 34,500 (10,391)
	distinct pid if info_l==1 														// 32,214 (10,231)
	local sample_soep_hi_obs 		= `r(N)'
	local sample_soep_hi_unique 	= `r(ndistinct)'

	* Share matched 
	local sample_soep_matched: di %10.0fc 100*(`sample_soep_hi_obs'/`sample_soep_full_obs') 
	di `sample_soep_matched'													// 68%

	* & Balanced panel to identify HI switch
	distinct pid if info_l==1 & hi_switch!=.									// 23,550 (7,454)
	local sample_soep_info_obs 		= `r(N)'
	local sample_soep_info_unique	= `r(ndistinct)'

	* Append to intext file
	file write 		   myfile ///
		"\newcommand{\SampleSoepFullObs}{$" %10.0fc (`sample_soep_full_obs') "$}"	_n 		/// 
		"\newcommand{\SampleSoepFullUnique}{$" %10.0fc (`sample_soep_full_unique') "$}"	_n 	/// 
		"\newcommand{\SampleSoepHIObs}{$" %10.0fc (`sample_soep_hi_obs') "$}"	_n 			/// 
		"\newcommand{\SampleSoepHIUnique}{$" %10.0fc (`sample_soep_hi_unique') "$}"	_n 		/// 
		"\newcommand{\SampleSoepHIMatch}{$" %10.0fc (`sample_soep_matched') "$}"	_n 		/// 
		"\newcommand{\SampleSoepInfoObs}{$" %10.0fc (`sample_soep_info_obs') "$}"	_n 		///
		"\newcommand{\SampleSoepInfoUnique}{$" %10.0fc (`sample_soep_info_unique') "$}"_n 
	
	* 1.2) Socio-demographic characteristics
	* ........................................................................ *

	/* Table \ref{tab:soepsummary} shows that the sample of individuals with available 
	insurer switch information is very similar to the general sample of interest in 
	terms of socio-demographic characteristics. The switching sample is marginally 
	older with a mean age of 44 compared to 43 in the general sample (median of 45 compared to 44). 
	Gross earnings, education, gender and marriage rates are almost identical across the two 
	samples. Lastly, the samples are surprisingly similar in terms of health status, 
	including self-reported health satisfaction, the share of individuals concerned
	with their health, absence from work because of sickness, or number of doctor visits.
	*/

	* Age

		* Full sample
		qui sum age if pid!=., d
		file write myfile "\newcommand{\SoepFullAgeMean}{$" %10.1fc (`r(mean)') "$}"	_n 	 
		file write myfile "\newcommand{\SoepFullAgeMedian}{$" %10.1fc (`r(p50)') "$}"	_n 	

		* Switching sample
		qui sum age if info_l==1 & hi_switch!=., d
		file write myfile "\newcommand{\SoepSwitchingAgeMean}{$" %10.1fc (`r(mean)') "$}"	_n 	 
		file write myfile "\newcommand{\SoepSwitchingAgeMedian}{$" %10.1fc (`r(p50)') "$}"	_n 	


* Close my file 
file close myfile 

* Close log file 
log close 
