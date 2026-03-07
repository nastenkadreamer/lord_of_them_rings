**********************************************************************************
// File name: 03_labeling.do

// Purpose: Label variables
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



****************************************************
* 1. BASIC YES / NO VARIANTS
****************************************************

label define consent_yesno_lbl ///
    1 "Yes" ///
    0 "No", replace

label define yesno_lbl ///
    1 "Yes" ///
    0 "No", replace

label define yes_no_dk_refuse_lbl ///
    1 "Yes" ///
    0 "No" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define yes_no_other_lbl ///
    1 "Yes" ///
    0 "No" ///
    -997 "Other (specify)", replace

label define yes_no_all_lbl ///
    1 "Yes" ///
    0 "No" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace


****************************************************
* 2. DEMOGRAPHICS
****************************************************

label define gender_lbl ///
    1 "Female" ///
    0 "Male" ///
    -997 "Other" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define marital_status_lbl ///
    0 "Never married" ///
    1 "Currently married" ///
    2 "Separated or divorced" ///
    3 "Widowed" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define hh_relation_lbl ///
    1 "Household head" ///
    2 "Spouse of HH head" ///
    3 "Child of HH head" ///
    4 "Sibling of HH head" ///
    5 "Parent of HH head" ///
    6 "Daughter-in-law/son-in-law of head" ///
    7 "Grandchildren of HH head" ///
    8 "Spouse of sibling of HH head" ///
    9 "Grandparent of HH head" ///
    10 "Niece/nephew of HH head" ///
    11 "Uncle/aunt of the HH head" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define education_level_lbl ///
    1 "No schooling" ///
    2 "Primary" ///
    3 "Secondary" ///
    4 "Higher Secondary" ///
    5 "Diploma" ///
    6 "Started college did not finish" ///
    7 "College graduate" ///
    8 "Postgraduate" ///
    9 "Advance degree after postgraduate" ///
    10 "Religious study" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace


****************************************************
* 3. SOCIO-ECONOMIC
****************************************************

label define hh_primary_income_lbl ///
    1 "Agricultural work on own/leased land (sale)" ///
    2 "Animal husbandry (sale)" ///
    3 "Self-employment/small business" ///
    4 "Income under SRLM/SHG" ///
    5 "Casual agricultural labour" ///
    6 "Casual non-agricultural labour" ///
    7 "NREGA work" ///
    8 "Salaried employment" ///
    9 "Pension" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define social_group_lbl ///
    1 "Scheduled Caste (SC)" ///
    2 "Scheduled Tribe (ST)" ///
    3 "Other Backward Class (OBC)" ///
    4 "General/Other" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define religion_lbl ///
    0 "None" ///
    1 "Hindu" ///
    2 "Muslim" ///
    3 "Christian" ///
    4 "Sikh" ///
    5 "Jain" ///
    6 "Buddhist" ///
    7 "Other, tribal community" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace


****************************************************
* 4. GOVERNANCE / GRAM SABHA
****************************************************

label define gram_topics_lbl ///
    1 "MGNREGS-related issues" ///
    2 "Land-related issues" ///
    3 "Agricultural issues" ///
    4 "Job or earning-related issues" ///
    5 "Education-related issues" ///
    6 "Water-related issues" ///
    7 "Heat-related issues" ///
    8 "Community conflict" ///
    9 "Women's issues" ///
    10 "Crime" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define reasons_not_attend_lbl ///
    1 "No time" ///
    2 "No interest" ///
    3 "Had another commitment" ///
    4 "My opinion isn't valued" ///
    5 "Family did not want me to go" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace


****************************************************
* 5. WATER
****************************************************

label define water_source_lbl ///
    1 "Borehole or tubewell" ///
    2 "Well" ///
    3 "Surface water" ///
    4 "Rainwater collection" ///
    5 "Tanker-truck" ///
    6 "Water tank" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define water_retriever_lbl ///
    1 "Respondent" ///
    2 "Spouse" ///
    3 "Other male adult" ///
    4 "Other female adult" ///
    5 "Male under 18" ///
    6 "Female under 18" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define water_shortage_reasons_lbl ///
    1 "Source is broken" ///
    2 "Not enough water for everyone" ///
    3 "Sometimes no water" ///
    4 "Prevented from accessing water" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace


****************************************************
* 6. AGRICULTURE
****************************************************

label define irrigation_method_lbl ///
    1 "Diesel motor pump" ///
    2 "Electric pump" ///
    3 "Solar pump" ///
    4 "Gravity" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace

label define crops_lbl ///
    1 "Rice" ///
    2 "Wheat" ///
    3 "Maize" ///
    4 "Millets" ///
    5 "Pulses" ///
    6 "Sugarcane" ///
    7 "Cotton" ///
    8 "Jute" ///
    9 "Oilseeds" ///
    10 "Tobacco" ///
    11 "Mango" ///
    12 "Papaya" ///
    13 "Cauliflower" ///
    14 "Potato" ///
    15 "Onion" ///
    16 "Soyabean" ///
    -997 "Other (specify)" ///
    -998 "Don't know" ///
    -999 "Refused to respond", replace


****************************************************
* 7. BEHAVIOUR / NORMS
****************************************************

label define agree_dis_lbl ///
    1 "Agree" ///
    2 "Neither agree nor disagree" ///
    3 "Disagree" ///
    -997 "Other (specify)" ///
    -998 "Refuse" ///
    -999 "Don't know", replace

label define beh_risks_lbl ///
    1 "Willing to take risks" ///
    2 "Avoid taking risks" ///
    -997 "Other (specify)" ///
    -998 "Refuse" ///
    -999 "Don't know", replace


****************************************************
* 8. ADMIN / STATUS
****************************************************

label define block_lbl ///
    3554 "Barwani" ///
    3559 "Pansemal" ///
    3555 "Pati" ///
    3558 "Rajpur", replace

label define survey_status_lbl ///
    1 "Available" ///
    2 "Appointment" ///
    3 "Not available during revisit period" ///
    4 "Not available during work hours" ///
    5 "Refused survey" ///
    6 "House locked" ///
    -997 "Other", replace
	


program define _apply_lbl
    syntax varname, LBL(name)

    capture confirm variable `varname'
    if _rc exit

    capture label list `lbl'
    if _rc exit

    label values `varname' `lbl'
end



* --- Yes / No variants
foreach v in ///
    consent ///
    q5_1_ever_attended_gram_sabha ///
    q5_3_attended ///
    q7_1_mgnrega ///
    q7_2_demanded_work ///
    leader_help {
        _apply_lbl `v', lbl(yesno_lbl)
}

* --- Yes / No / DK / Refuse
foreach v in ///
    q_audio_consent ///
    phone_yn {
        _apply_lbl `v', lbl(yes_no_dk_refuse_lbl)
}

* --- Gender
_apply_lbl q1_11_gender, lbl(gender_lbl)

* --- Marital status
_apply_lbl q1_12_marital_status, lbl(marital_status_lbl)

* --- Relation to HH head
_apply_lbl q1_15_hh_relation, lbl(hh_relation_lbl)

* --- Education
_apply_lbl q1_13_education, lbl(education_level_lbl)

* --- Social group / religion
_apply_lbl q1_17_social_group, lbl(social_group_lbl)
_apply_lbl q1_17_religion, lbl(religion_lbl)

* --- Income
_apply_lbl q1_18_primary_income, lbl(hh_primary_income_lbl)




* --- Gram Sabha topics
foreach v of varlist q5_4_topic_* {
    _apply_lbl `v', lbl(gram_topics_lbl)
}

* --- Reasons not attending Gram Sabha
foreach v of varlist q5_8_reasons_not_attend_* {
    _apply_lbl `v', lbl(reasons_not_attend_lbl)
}

* --- Leader not helping reasons
foreach v of varlist leader_not_help_reasons_* {
    _apply_lbl `v', lbl(leader_not_help_reasons_lbl)
}

* --- Water shortage reasons
foreach v of varlist q8_9_water_shortage_reasons_* {
    _apply_lbl `v', lbl(water_shortage_reasons_lbl)
}

* --- Crops grown
foreach v of varlist q8_31_crops_* {
    _apply_lbl `v', lbl(crops_lbl)
}

* --- Water events (last 5 years)
foreach v of varlist q8_42_water_events_last_5yrs_* {
    _apply_lbl `v', lbl(water_events_last_5yrs_lbl)
}

* --- GP water assets
foreach v of varlist gp_water_assets_* {
    _apply_lbl `v', lbl(gp_water_assets_lbl)
}



_apply_lbl trust_scale, lbl(trust_scale_lbl)
_apply_lbl conflict_level, lbl(conflict_level_lbl)
_apply_lbl influence_level, lbl(influence_level_lbl)
_apply_lbl water_source, lbl(water_source_lbl)
_apply_lbl water_retriever, lbl(water_retriever_lbl)
_apply_lbl irrigation_method, lbl(irrigation_method_lbl)
_apply_lbl water_availability_change_5yrs, lbl(water_availability_change_5yrs_lbl)
_apply_lbl trust_general, lbl(trust_general_lbl)
_apply_lbl water_acceptable, lbl(water_acceptable_lbl)
_apply_lbl beh_risks, lbl(beh_risks_lbl)
_apply_lbl agree_dis, lbl(agree_dis_lbl)
_apply_lbl bets, lbl(bets_lbl)
_apply_lbl truefalse, lbl(truefalse_lbl)
_apply_lbl gp_rule, lbl(gp_rule_lbl)
_apply_lbl break_rule, lbl(break_rule_lbl)


_apply_lbl block_id, lbl(block_lbl)
_apply_lbl survey_status, lbl(survey_status_lbl)
_apply_lbl refusal_reason, lbl(refusal_reason_lbl)



* Check
ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    local vl : value label `v'
    if "`vl'" == "" {
        quietly summarize `v'
        if r(N) > 0 di as error "NO VALUE LABEL: `v'"
    }
}

*
	
	
