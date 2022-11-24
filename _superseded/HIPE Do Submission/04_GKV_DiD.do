* Set directory
cd "$hipe"

* Load data
use "$output/GKV_aggregate", clear

* Set panel var
xtset id year

* Drop those that charged addon premium in 2010-12

	// Ever charged an add-on premium
	cap drop addon09_dummy_ever
	egen addon09_dummy_ever = max(addon09_dummy), by(provider)
	
		tab provider if addon09_dummy_ever==1
		drop if addon09_dummy_ever==1 
		drop if provider=="DAK-Gesundheit"
		
	// Drop providers without did group
	tab provider if addon_did_group==.
	drop if addon_did_group==.
	
* Generate group dummys

	tab addon_did_group

	// Below average
	cap drop below
	gen below = 1 if addon_did_group==1
	replace below = 0 if below==.
	
	// Average 
	cap drop average
	gen average = 1 if addon_did_group==2
	replace average = 0 if average==. 
	
	// Above average
	cap drop above
	gen above = 1 if addon_did_group==3
	replace above = 0 if above==.
	
* Generate post dummy
cap drop post
gen post = 1 if year > 2014
replace post = 0 if post==.
		
* Add overall DiD coefficients
cap drop did_below
gen did_below = post*below

cap drop did_above 
gen did_above = post*above


*** insured_lead_ln

* Add overall DiD coefficients
reg insured_lead_ln below above i.year did_below did_above i.type insured_initial_ln if year<2019, vce(robust)
local b_below = round(_b[did_below],0.001)
local se_below = round(_se[did_below],0.001)
local b_above = round(_b[did_above],0.001)
local se_above = round(_se[did_above],0.001)
	
* DiD over years	
	
// DiD group dummies
forvalues j=1/9 {
	
	// Above
	cap drop above`j'
	gen above`j' = 1 if addon_did_group==3
	replace above`j' = 0 if above`j'==.
	
	cap drop did_above`j'
	gen did_above`j' = post*did_above
	
	// Below
	cap drop below`j'
	gen below`j' = 1 if addon_did_group==1
	replace below`j' = 0 if below`j'==.
	
	cap drop did_below`j'
	gen did_below`j' = post*did_below
}

// Dummies for year
forvalues i=2009/2018 {

	// Year dummies
	cap drop d_`i'
	gen d_`i'=(year==`i')
	
	// By year and group
	cap drop d_`i'_above_t
		gen d_`i'_above_t = (year==`i' & above==1)
		
	cap drop d_`i'_below_t
		gen d_`i'_below_t = (year==`i' & below==1)
}

// Drop baseline 
drop d_2014 d_2014_above_t d_2014_below_t

// Regression
reg insured_lead_ln below above d_* i.type insured_initial_ln if year<2019, vce(robust)

// Baseline effects (2014)
cap drop ball_t
	gen ball_t=0 if year==2014

// Assign coefficients and CI for graph
foreach group in above below {

	// Create variables for following assignment
	foreach var in ball upall lowall { 
	cap drop `var'_`group'
		gen `var'_`group'=.
	}

	// Pre
	forvalues y=2009/2013 {
		replace ball_`group' = _b[d_`y'_`group'_t] if year==`y'
		replace upall_`group' = _b[d_`y'_`group'_t] + 1.96*_se[d_`y'_`group'_t] if year==`y'
		replace lowall_`group' = _b[d_`y'_`group'_t] - 1.96*_se[d_`y'_`group'_t] if year==`y'
	}
	
	// Post
	forvalues y=2015/2018 {
		replace ball_`group' = _b[d_`y'_`group'_t] if year==`y'
		replace upall_`group' = _b[d_`y'_`group'_t] + 1.96*_se[d_`y'_`group'_t] if year==`y'
		replace lowall_`group' = _b[d_`y'_`group'_t] - 1.96*_se[d_`y'_`group'_t] if year==`y'
	}
}

replace ball_below = 0 if year==2014
replace ball_above = 0 if year==2014

sort year

// Plot graph
graph twoway (connected ball_above year, msize(medsmall) lcolor(orange) mcolor(orange) lpattern(solid) lwidth(medthin)) ///
	(rcap upall_above lowall_above year, lcolor(orange) mcolor(orage) lpattern(solid)) ///
	(connected ball_below year, msize(medsmall) lcolor(navy) mcolor(navy) lpattern(solid) lwidth(medthin)) ///
	(rcap upall_below lowall_below year, lcolor(navy) mcolor(navy) lpattern(solid)) ///
	if (year>=2009 & year<=2018) ///
	, yline(0, lcolor(black)) xtitle("Year", height(6)) xscale(range(2009 2018)) xlabel(2009 (1) 2018) yscale(range(-0.4 0.5)) ///
	xline(2014.5, lp(dash) lcol(gs5)) ///
	legend(order(1 "Above average" 3 "Below average")) ///
	text(0.5 2015.7 "ß_below = `b_below' (`se_below')", size(small)) ///
	text(-0.37 2015.7 "ß_above = `b_above' (`se_above')", size(small)) ///
	ytitle("Effect on log(enrollment)")
	
graph export "$figures/DiD/Provider/DiD_Provider_insured_Lead_ln_V2.pdf", replace
	
// Test for pre-trends
test (d_2012=0) (d_2013=0) 

