**********************************************************************************
// File name: corrected_village_leader_survey.do

// Purpose: Correct specific entries in the village leader survey dataset
// Author: Anindya Singh 
// Date created: December 19, 2025

**********************************************************************************

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

use "${interdata}/01_Baseline_Survey/01_village_leader/village_leader_survey_barwani.dta"


replace gp = 133021 if key == "uuid:0688a4c8-f73e-47d3-bd00-4af1fe9de404"
replace village = 478309 if key == "uuid:0688a4c8-f73e-47d3-bd00-4af1fe9de404"