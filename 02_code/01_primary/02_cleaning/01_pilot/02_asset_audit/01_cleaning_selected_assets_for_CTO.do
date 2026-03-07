** ********************************************************************************
/*
File name: 01_cleaning_for_CTO.do

Purpose: Appended all the sheets in the barwani_pilot_selected_assets for CTO 
Author: Anindya Singh 
Date created: January 7, 2026

*/ 
********************************************************************************

* SET UP 

if "`c(username)'" == "cmtm" {
	do "/Users/cmtm/Dropbox (Personal)/Building Resilience IEIC/04 Data/02_code/00_master_building_resilience.do"
}

else if "`c(username)'" == "anind" {
    do "C:/Users/anind/Dropbox/Building Resilience Barwani/04 Data/02_code/00_master_building_resilience.do"
}

local barwani_completed_assets 
import excel using "${interdata}/02_Asset_Audit/barwani_pilot_selected_assets.xlsx", ///
    sheet("completed_main_sample") firstrow clear
save sheet1, replace

import excel using "${interdata}/02_Asset_Audit/barwani_pilot_selected_assets.xlsx", sheet("completed_buffer") firstrow clear
save sheet2.dta, replace

import excel using "${interdata}/02_Asset_Audit/barwani_pilot_selected_assets.xlsx", sheet("ongoing_main_sample") firstrow clear
capture rename workcategoryname workcategory
capture rename worktypepernewworkcreationmodule worktype
capture rename workstarteddate work_start_date
save sheet3.dta, replace

import excel using "${interdata}/02_Asset_Audit/barwani_pilot_selected_assets.xlsx", sheet("ongoing_buffer") firstrow clear
capture rename workcategoryname workcategory
capture rename worktypepernewworkcreationmodule worktype
capture rename workstarteddate work_start_date
save sheet4.dta, replace

use sheet1.dta, clear
append using sheet2.dta
append using sheet3.dta
append using sheet4.dta

ds workcategory*
ds worktype*
ds work*_date*

drop workstartfinyear
drop worktypepernewworkcreationmodule
gen completed_asset = (workstatus == "")
gen block_code = .
replace block_code = 3554 if block == "BARWANI"
replace block_code = 3555 if block == "PATI"
replace block_code = 3558 if block == "RAJPUR"

label variable block_code "Block code"

label define block_lbl ///
    3554 "BARWANI" ///
    3555 "PATI" ///
    3558 "RAJPUR", replace

label values block_code block_lbl

gen panchayat_code = .

replace panchayat_code = 132840 if panchayat == "BHANDARDA"
replace panchayat_code = 132850 if panchayat == "DHAMNAI"
replace panchayat_code = 132874 if panchayat == "SILAWAD"
replace panchayat_code = 132970 if panchayat == "BUDI"
replace panchayat_code = 132988 if panchayat == "OSADA"
replace panchayat_code = 133000 if panchayat == "SEMALI"
replace panchayat_code = 133006 if panchayat == "VALAN"
replace panchayat_code = 133021 if panchayat == "DANOD"

label variable panchayat_code "Gram Panchayat code"

label define gp_lbl ///
    132840 "BHANDARDA" ///
    132850 "DHAMNAI" ///
    132874 "SILAWAD" ///
    132970 "BUDI" ///
    132988 "OSADA" ///
    133000 "SEMALI" ///
    133006 "VALAN" ///
    133021 "DANOD", replace

label values panchayat_code gp_lbl

gen block4 = string(block_code, "%04.0f")
gen gp3 = substr(string(panchayat_code), -3, 3)

bysort block gp: gen asset_seq = _n
gen asset4 = string(asset_seq, "%04.0f")

gen asset_id = block4 + gp3 + asset4
destring asset_id, replace
export excel using "${cleandata}/02_Asset_Audit/barwani_pilot_selected_assets_appended.xlsx", firstrow(variables) replace

