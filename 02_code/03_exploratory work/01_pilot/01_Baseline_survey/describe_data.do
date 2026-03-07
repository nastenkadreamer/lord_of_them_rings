* Temporary file to describe data
if "`c(username)'" == "cmtm" {
    do "/Users/cmtm/Dropbox (Personal)/Building Resilience IEIC/04 Data/02_code/00_master_building_resilience.do"
}

use "${interdata}/01_Baseline_Survey/01_village_leader/village_leader_survey_barwani.dta", clear

describe