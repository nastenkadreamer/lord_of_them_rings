***************************************************************************************

// File name: 01_variation.do

// Purpose: Looks at the variation in behavioral measures collected from village leaders in Barwani pilot baseline survey
// Author: Anindya Singh 
// Date created: December 24, 2025

***************************************************************************************


if "`c(username)'" == "cmtm" {
    do "/Users/cmtm/Dropbox (Personal)/Building Resilience IEIC/04 Data/02_code/00_master_building_resilience.do"
}
    
else if "`c(username)'"	== "anind" {
		global main "/Users/`c(username)'/Dropbox/Building Resilience Barwani/04 Data"
}
    /* else {
        /// add your paths here! 
    } */ 

pwd

use "${interdata}/01_Baseline_Survey/01_village_leader/village_leader_survey_barwani.dta"



foreach var of varlist beh_pat1 beh_pat2 beh_pat3 beh_equi1 beh_equi2 beh_norms1 beh_norms2 beh_norms3 beh_risk1 beh_risk2 beh_risk3 beh_recip1 beh_alt1 beh_recip2 beh_risk4 beh_timepref1 zero_sum1 zero_sum2 zero_sum3 zero_sum4 {
	di "========================================================"
	di "tabulation for `var'"
	tab `var'
}