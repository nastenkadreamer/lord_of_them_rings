**********************************************************************************
// File name: 01_cleaning.do

// Purpose: Auto-label multiselect dummy variables
// Author: Anindya Singh 
// Date created: January 27, 2026

**********************************************************************************

clear all
set more off


if "`c(username)'" == "cmtm" {
    do "/Users/cmtm/Dropbox (Personal)/Building Resilience IEIC/04 Data/02_code/00_master_building_resilience.do"
}
    
else if "`c(username)'" == "anind" {
    do "C:/Users/anind/Dropbox/Building Resilience IEIC/04 Data/02_code/00_master_building_resilience.do"
}
    /* else {
        /// add your paths here! 
    } */ 

pwd

use "${interdata}/01_primary/01_Baseline_Survey/02_citizen_survey/01_citizen_survey_barwani.dta"



set varabbrev off


ds, has(type numeric)
local numvars `r(varlist)'

foreach v of local numvars {

    * Match: base_option (option may be negative)
    if regexm("`v'", "^(.+)_(-?[0-9]+)$") {

        local base = regexs(1)
        local opt  = regexs(2)

        * Skip system / non-question fields
        if strpos("`v'", "_other") continue

        * Get value label FROM THE DUMMY VARIABLE
        local vallab : value label `v'
        if "`vallab'" == "" continue

        * Get option label text
        local optlabel : label `vallab' `opt'
        if "`optlabel'" == "" continue


        ************************************************
        * CLEAN OPTION LABEL
        ************************************************
        local clean = lower("`optlabel'")
        local clean = subinstr("`clean'", "(", "", .)
        local clean = subinstr("`clean'", ")", "", .)
        local clean = subinstr("`clean'", "/", "", .)
        local clean = subinstr("`clean'", "-", "", .)
        local clean = subinstr("`clean'", ",", "", .)
        local clean = subinstr("`clean'", ".", "", .)
        local clean = subinstr("`clean'", "'", "", .)
        local clean = subinstr("`clean'", "'", "", .)
        local clean = subinstr("`clean'", "  ", " ", .)
        local clean = subinstr("`clean'", " ", "_", .)


        ************************************************
        * APPLY VARIABLE LABEL
        ************************************************
        label variable `v' "`base'_`clean'"
    }
}

describe q5_8_reasons_*

describe q5_8_reasons_not_attend*


