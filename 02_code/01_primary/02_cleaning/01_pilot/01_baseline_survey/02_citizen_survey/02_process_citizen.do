**********************************************************************************
// File name: 02_process_citizen.do

// Purpose: 
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
cap mkdir "${myoutput}/Summary/Citizen"

use "${interdata}/01_Baseline_Survey/02_citizen_survey/01_citizen_survey_barwani.dta"



duplicates report key

// Household-level duplicates (if applicable)
capture confirm variable hhid
if !_rc {
    duplicates report hhid
}

// Keep latest submission per household (or key if HH not present)
capture confirm variable hhid
if !_rc {
    sort hhid submissiondate
    by hhid: keep if _n == _N
}
else {
    sort key submissiondate
    by uuid: keep if _n == _N
}

tab consent
codebook duration 
destring duration, replace
gen valid_consent = (consent == 1)
label variable valid_consent "Respondent consented to survey"

gen valid_duration = (duration >= 1200)
label variable valid_duration "Interview duration >= 15 minutes"

gen valid_interview = (valid_consent == 1 & valid_duration == 1)
label variable valid_interview "Interview valid (consent + duration)"

drop if valid_interview == 0

gen enumerator_id = username
label variable enumerator_id "Enumerator username"

codebook survey_date_scto
describe submissiondate
gen survey_date = dofc(submissiondate)
format survey_date %td
label variable survey_date "Survey submission date"

summarize survey_date
format survey_date %td

order key gp_id block_id survey_date, first


destring block_id gp_id, replace force
list key gp_id block_id if missing(gp_id)
list key block_id surveyor_name consent duration survey_date_scto if missing(gp_id)
drop if missing(gp_id)
assert !missing(gp_id)


ds *_1 *_2

foreach v of varlist *_2 {
    quietly count if !missing(`v')
    if r(N) == 0 drop `v'
}


tempname lbl

postfile `lbl' ///
    str40 varname ///
    str200 varlabel ///
    using ///
    "${myoutput}/Summary/Citizen/citizen_missing_variable_labels.dta", ///
    replace

foreach v of varlist _all {
    local lab : variable label `v'
    if "`lab'" == "" {
        post `lbl' ("`v'") ("MISSING VARIABLE LABEL")
    }
}
postclose `lbl'

use "${myoutput}/Summary/Citizen/citizen_missing_variable_labels.dta", clear

export excel using ///
"${myoutput}/Summary/Citizen/citizen_missing_variable_labels.xlsx", ///
replace firstrow(variables)

use "${interdata}/01_Baseline_Survey/02_citizen_survey/01_citizen_survey_barwani.dta"
ds, has(type numeric)
local numvars `r(varlist)'

local contvars
foreach v of local numvars {
    if !inlist("`v'", ///
        "key", "gp_id", "block_id", ///
        "deviceid", "duration") {
        local contvars `contvars' `v'
    }
}

display "`contvars'"

tempname diag

postfile `diag' ///
    str40 varname ///
    str200 varlabel ///
    double min max mean p1 p99 ///
    using ///
    "${myoutput}/Summary/Citizen/citizen_continuous_diagnostics.dta", ///
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

pwd

use "${myoutput}/Summary/Citizen/citizen_continuous_diagnostics.dta"

gen flag_outlier = ///
    (max == 999 | max == 9999 | max == 99999) | ///
    (min < 0 & p1 >= 0) | ///
    (max > 10*p99 & p99 > 0)

label variable flag_outlier "Potential unreasonable outlier"
count
export excel using ///
"${myoutput}/Summary/Citizen/citizen_continuous_diagnostics.xlsx", ///
replace firstrow(variables)


pwd

use "${interdata}/01_Baseline_Survey/02_citizen_survey/01_citizen_survey_barwani.dta", clear

preserve
gen one = 1

collapse ///
    (sum)   n_resp   = one ///
    (sum)   n_female = q1_11_gender ///
    , by(gp_id)


gen n_male = n_resp - n_female

label variable n_resp   "Number of respondents (interviews)"
label variable n_female "Number of female respondents"
label variable n_male   "Number of male respondents"

export excel using ///
"${myoutput}/Summary/Citizen/gp_gender_counts.xlsx", ///
replace firstrow(variables)

restore