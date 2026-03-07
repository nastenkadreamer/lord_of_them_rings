**********************************************************************************
// File name: 02_process_village_leader.do

// Purpose: Data processing
// Author: Anindya Singh 
// Date created: January 26, 2026

**********************************************************************************

clear all
set more off


if "`c(username)'" == "cmtm" {
    do "/Users/cmtm/Dropbox (Personal)/Building Resilience IEIC/04 Data/02_code/00_master_building_resilience.do"
}
    
else if "`c(username)'" == "anind" {
    do "C:/Users/anind/Dropbox/Building Resilience Barwani/04 Data/02_code/00_master_building_resilience.do"
}
    /* else {
        /// add your paths here! 
    } */ 

pwd
cap mkdir "${myoutput}/Summary"
cap mkdir "${myoutput}/Summary/Village_Leader"

use "${interdata}/01_Baseline_Survey/01_village_leader/village_leader_survey_barwani.dta"



duplicates report key
duplicates report gp
sort gp submissiondate
by gp: keep if _n == _N

gen valid_consent = (consent_future_contact == 1)

// Duration sanity check
codebook duration
destring duration, replace
gen valid_duration = duration >= 600

// Final interview validity
gen valid_interview = (valid_consent == 1 & valid_duration == 1)

// Drop invalid interviews
drop if valid_interview == 0


// Replacing block with it's codes and labels
destring block gp village, replace force

replace block = 3558 if gp == 133021 
replace block = 3554 if inlist(gp, 132999, 132840, 132850)
replace block = 3555 if inlist(gp, 133000, 132988, 132970, 133006)

label define block_lbl 3554 "Barwani"  3555 "Pati" 3558 "Rajpur", replace

label values block block_lbl
label variable block "Block code"

tab gp block, missing
assert !missing(block) if inlist(gp, ///
    132840, 132850, 132970, 132988, ///
    132999, 133000, 133006, 133021)
	
ds *_1 *_2

foreach v of varlist *_2 {
    local base = substr("`v'",1,length("`v'")-2)
    quietly count if !missing(`v')
    if r(N)==0 drop `v'
}

// Bianry standardisation *---Repeat fot every binary----*
recode q1_20a_bicycle (1=1) (2=0), gen(q1_20a_bicycle_bin)
label define yesno 0 "No" 1 "Yes"
label values q1_20a_bicycle_bin yesno
label variable q1_20a_bicycle_bin "Bicycle Owner binary"

tempname lbl

postfile `lbl' ///
    str40 varname ///
    str200 varlabel ///
    using ///
    "${myoutput}/Summary/Village_Leader/leader_missing_variable_labels.dta", ///
    replace

foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        post `lbl' ("`v'") ("MISSING VARIABLE LABEL")
    }
}
postclose `lbl'

use "${myoutput}/Summary/Village_Leader/leader_missing_variable_labels.dta", clear

export excel using ///
"${myoutput}/Summary/Village_Leader/leader_missing_variable_labels.xlsx", ///
replace firstrow(variables)

use "${interdata}/01_Baseline_Survey/01_village_leader/village_leader_survey_barwani.dta", clear

ds, has(type numeric)
local numvars `r(varlist)'

// Exclude obvious IDs and codes
local contvars
foreach v of local numvars {
    if !inlist("`v'", ///
        "key", "gp", "block", ///
        "deviceid", "duration") {
        local contvars `contvars' `v'
    }
}

display "`contvars'"

use "${interdata}/01_Baseline_Survey/01_village_leader/village_leader_survey_barwani.dta"

tempname diag

postfile `diag' ///
    str40 varname ///
    str200 varlabel ///
    double min max mean p1 p99 ///
    using ///
    "${myoutput}/Summary/Village_Leader/leader_continuous_diagnostics.dta", ///
    replace

foreach v of local contvars {
    quietly summarize `v', detail
    local lab : variable label `v'
    post `diag' ///
        ("`v'") ///
        ("`lab'") ///
        (r(min)) (r(max)) (r(mean)) (r(p1)) (r(p99))
}
postclose `diag'

use "${myoutput}/Summary/Village_Leader/leader_continuous_diagnostics.dta", clear
count
assert r(N) > 0

gen flag_outlier = ///
    (max == 999 | max == 9999 | max == 99999) | ///
    (min < 0 & p1 >= 0) | ///
    (max > 10*p99 & p99 > 0)

label variable flag_outlier "Potential unreasonable outlier"


export excel using ///
"${myoutput}/Summary/Village_Leader/leader_continuous_diagnostics.xlsx", ///
replace firstrow(variables)