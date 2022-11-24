* 	Define folder locations
	global data "/Users/./Local/HIPE/Data"
	global soep "/Users/./Local/HIPE/Data/Input/SOEP/soep.v35.international.stata_dta"
	global soep_cleaned "/Users/./Local/HIPE/Data/Input/SOEP/soep.v35.i.cleaned" 
	global temp "/Users/./Local/HIPE/Data/Temp"
	global output "/Users/./Local/HIPE/Data/Output"
	global soep_description "/Users/./Library/Mobile Documents/com~apple~CloudDocs/EME/EC426 Public Economics/HIPE/Data/SOEP"
	global figures "/Users/./Library/Mobile Documents/com~apple~CloudDocs/EME/EC426 Public Economics/HIPE/Figures"
	global hipe "/Users/./Library/Mobile Documents/com~apple~CloudDocs/EME/EC426 Public Economics/HIPE"
	global tables "/Users/./Library/Mobile Documents/com~apple~CloudDocs/EME/EC426 Public Economics/HIPE/Tables"
	global scripts "/Users/./Library/Mobile Documents/com~apple~CloudDocs/EME/EC426 Public Economics/HIPE/Scripts"
	
* run all do-files

	* SOEP data merge
	do "$scripts/01a_HIPE_SOEP_matching.do"
	
	* GKV aggregate data merge
	do "$scripts/02b_HIPE_GKVdata.do"
	
	* SOEP and GKV aggregate merge
	do "$scripts/02a_HIPE_SOEP_gkv_matching.do"

	* SOEP data analysis
	do "$scripts/03a_analysis_soep_gkv.do"

	* GKV aggregate analyis
	do "$scripts/03b_analysis_GKV_aggregate.do"
