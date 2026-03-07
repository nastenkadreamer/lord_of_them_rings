********************************************************************************
/*
File name: 01_sampling_asset_pilot.do

Purpose: Select sample of assets to audit in Barwani pilot GPs 
Author: Anindya Singh 
Date created: December 31, 2025

Edited by: Charity Troyer Moore
Date: December 31, 2025
Updates: Expanded to sample from both ongoing and completed assets, added paths, etc.

*/ 
********************************************************************************

* SET UP 

if "`c(username)'" == "cmtm" {
	do "/Users/cmtm/Dropbox (Personal)/Building Resilience IEIC/04 Data/02_code/00_master_building_resilience.do"
}

else if "`c(username)'"	== "anind" {
		global main "/Users/`c(username)'/Dropbox/Building Resilience Barwani/04 Data"
}

/* to fill in below once I have the for-sure raw data -- draft code: */ 

// our two data sources: 
// completed assets, as scraped from Yukhtara/Bhuvan by the Commons Connect team and shared with us: 


local barwani_completed_assets "${interdata}/02_Asset_Audit/shared_by_cc/barwani_assets.csv"
local barwani_ongoing_assets "${raw_assets}/Ongoing_assets"

import delimited using "`barwani_completed_assets'", encoding(UTF-8) clear

// keep pilot GPs: 
replace panchayat = lower(panchayat)
	g pilot = 1 if district == "BARWANI" & (panchayat == "dhamnai" | panchayat == "silawad" | panchayat == "valan" | panchayat == "danod" | panchayat == "budi" | panchayat == "osada" | panchayat == "semali" | panchayat == "bhandarda" | panchayat == "semlet" | panchayat == "semli")
	

	unique district block panchayat if pilot == 1  
		assert r(unique) == 8

	keep if pilot == 1 
/*
// sampling will be restricted to assets created starting in 2021 and later 
// note this is based on the "workstart date", so may only reflect when the asset was entered in Yukhtara/Bhuvan, even if created prior to that */

g workstart_date = date(work_start_date, "DM20Yhm")
	format %td workstart_date
	
	codebook workstart_date // dates range from Jan 1 1900 (just 3 obs) - otherwise 26 jan 2006 - Dec 12, 2022, but only 9 supposedly started since April 1, 2021, so will instead incorporate any assets entered registered online on or after April 1, 2021
	
g entered_date = date(creation_date, "DM20Y")	// creation date is the work END date - as reported by Anindya Singh in Jan 2026 after consultation w/ CoreStack/KYL team 
		
		format %td entered_date 
		keep if entered_date>= td(01apr2017)
		
		
		tab workstart_date // lots of supposedly old assets 
		
* Streamline string variables 
replace workname = lower(workname)
replace workcategory = lower(workcategory)
replace work_type = lower(work_type)

rename work_type worktype 


****************************************************
* Classify assets for stratification: create asset_class4
*    1 Water extraction
*    2 Water recharge / conservation
*    3 Plantation / land treatment
*    4 Other
****************************************************

gen byte asset_class4 = .
label define asset4 1 "water_extraction" 2 "water_recharge" 3 "plantation_land" 4 "other", replace

* A. Classify using category-level mapping 
replace asset_class4 = 1 if strpos(workcat, "well") > 0 ///
						| strpos(worktype, "well")>0
						
						
replace asset_class4 = 1 if strpos(workcategory, "irrigation")>0 						
                        

replace asset_class4 = 2 if strpos(workcat, "water conservation") > 0 ///
                        | strpos(workcat, "water harvesting") > 0 ///
						| strpos(worktype, "recharge") > 0 ///
						| strpos(worktype, "farm pond")>0 ///
						| strpos(worktype, "bund")>0 ///
						| strpos(worktype, "check dam")>0 ///
						| strpos(worktype, "water absorption")>0 ///
						| strpos(worktype, "stop dam") > 0 ///
						| strpos(worktype, "feeder channel")>0 // not sure this should be considered recharge
						
replace asset_class4 = 2 if strpos(worktype, "gully")>0 						
replace asset_class4 = 2 if strpos(worktype, "trench")>0 						
		

* Drought proofing is mixed; tentatively set to plantation/land then refine with workname
replace asset_class4 = 3 if strpos(worktype, "plantation") > 0 ///
						| strpos(worktype, "trees")>0 ///
						| strpos(worktype, "afforest") > 0 ///
						| strpos(workcat, "plantation")>0 

* Clear "other" categories (edit as needed)
replace asset_class4 = 4 if strpos(workcat, "rural connectivity") > 0 ///
                        | strpos(workcat, "rural sanitation") > 0 ///
                        | strpos(workcat, "anganwadi") > 0 ///
                        | strpos(workcat, "rural infrastructure") > 0 ///
						| strpos(worktype, "hous")>0 ///
						| strpos(worktype, "shelter")>0 ///
						| strpos(worktype, "road")>0  ///
						| strpos(worktype, "toilet")>0  ///
						| strpos(worktype, "crematorium")>0  ///
						| strpos(worktype, "sand moram")>0  ///  this is for roads 
						| strpos(worktype, "play ground")>0 ///
						| strpos(worktype, "cement concrete") >0  /// for cc road (see work name) //
						| strpos(worktype, "anganwadi") > 0 ///
						| strpos(worktype, "bharat nirman") > 0 ///
						| strpos(worktype, "bhawan") > 0 ///
						| strpos(worktype, "shed") > 0 ///
						| strpos(worktype, "play field") > 0 ///
						| strpos(worktype, "produce storage") > 0 ///
						| strpos(worktype, "grain storage") > 0 ///
						| strpos(worktype, "compost")>0 
						

* If still missing, default to "other"
replace asset_class4 = 4 if missing(asset_class4) // nothing changed

label values asset_class4 asset4

****************************************************
* Assess results 
****************************************************
	tab asset_class4

	
****************************************************
* Randomly select and order assets by asset class 
****************************************************

set seed 061510
	gen rand = runiform()

bysort district block panchayat asset_class4 (rand): gen randord_gp = _n
	gen selected = randord_gp <= 4 & asset_class4 == 1 
	replace selected = 1 if randord_gp <=4 & asset_class4 == 2
	replace selected = 1 if randord_gp <=4 & asset_class4 == 3
	replace selected = 1 if randord_gp <=2 & asset_class4 == 4
	
		
	gen target = selected == 1 & randord_gp <= 2 & asset_class4 == 1
		replace target = 1 if selected == 1 & randord_gp<=2 & asset_class4 == 2
		replace target = 1 if selected == 1 & randord_gp<=2 & asset_class4 == 3
		replace target = 1 if selected == 1 & randord_gp <= 1 & asset_class4 == 4
	gen buffer = (selected == 1 & target != 1)
	// for completed assets, we select up to 2 each of water extracting, water recharging, plantations, and 1 of other category (7 total) --> not all GPs have enough of each category
	
	
	replace panchayat = upper(panchayat)

export excel using "${interdata}/02_Asset_Audit/barwani_pilot_selected_assets.xlsx" if selected == 1 & target == 1, ///
	sheet("completed_main_sample", replace) firstrow(var)
	
export excel using "${interdata}/02_Asset_Audit/barwani_pilot_selected_assets.xlsx" if selected == 1 & buffer == 1, ///
	sheet("completed_buffer", replace) firstrow(var)
	

****************************************************
* Classify completed assets 
****************************************************

	bys panchayat: count if buffer == 1	& selected == 1

	g ongoing_asset = 0 
	
	tempfile completed_assets
		save "`completed_assets'", replace
			
	
****************************************************
* Process and bring in the ongoing assets, as in this folder: 
****************************************************	
	
local folder "${raw_assets}/ongoing_assets"
local filelist : dir "`folder'" files "*.csv", respectcase

di `"`filelist'"'

	local gpcount 1
	
	foreach file of local filelist {
		
		import delimited "`folder'/`file'", encoding(UTF-8) clear 

			g gp_name = panchayatname
			
		rename districtname district 
		rename blockname block 
		tempfile GP_`gpcount'

			save "`GP_`gpcount''", replace 
		
		local ++gpcount
		di `gpcount'
		
	}

	local gpcount2 = `gpcount'- 1
		
	forv i = 1/`gpcount2' {
	
	if `i' == 1 {
		use `GP_`i'', clear 
	}
		else {
			append using "`GP_`i''"
			}
			
	
	}
	
	save "${raw_assets}/ongoing_assets", replace 
	
	


* Streamline string variables 
replace workname = lower(workname)
replace workcategoryname = lower(workcategoryname)
replace worktype = lower(worktype)
replace worktypepernew = lower(worktypepernew)

****************************************************
* 1) Flag ownership: public vs private/individual
****************************************************
gen byte ownership = 0
	label define own 0 "public/community" 1 "private/individual", replace

* Strong signals of individual assets
replace ownership = 1 if strpos(workcat, "individual") > 0
replace ownership = 1 if !missing(individualbeneficiaryjcnincaseof) // all align with above definition/0 changes 
replace ownership = 1 if regexm(workname, "individual|beneficiar|private") // same 

label values ownership own

****************************************************
* 2) Classify assets for stratification: create asset_class4
*    1 Water extraction
*    2 Water recharge / conservation
*    3 Plantation / land treatment
*    4 Other
****************************************************

gen byte asset_class4 = .
label define asset4 1 "water_extraction" 2 "water_recharge" 3 "plantation_land" 4 "other", replace


* A. Classify using category-level mapping 
replace asset_class4 = 1 if strpos(workcat, "well") > 0 ///
						| strpos(worktype, "well")>0
						
						
replace asset_class4 = 1 if strpos(workcategory, "irrigation")>0 						
                        

replace asset_class4 = 2 if strpos(workcat, "water conservation") > 0 ///
                        | strpos(workcat, "water harvesting") > 0 ///
						| strpos(worktype, "recharge") > 0 ///
						| strpos(worktype, "farm pond")>0 ///
						| strpos(worktype, "bund")>0 ///
						| strpos(worktype, "check dam")>0 ///
						| strpos(worktype, "water absorption")>0 ///
						| strpos(worktype, "stop dam") > 0 ///
						| strpos(worktype, "feeder channel")>0 // not sure this should be considered recharge
						
replace asset_class4 = 2 if strpos(worktype, "gully")>0 						
replace asset_class4 = 2 if strpos(worktype, "trench")>0 						
		

* Drought proofing is mixed; tentatively set to plantation/land then refine with workname
replace asset_class4 = 3 if strpos(worktype, "plantation") > 0 ///
						| strpos(worktype, "trees")>0 ///
						| strpos(worktype, "afforest") > 0 ///
						| strpos(workcat, "plantation")>0 

* Clear "other" categories (edit as needed)
replace asset_class4 = 4 if strpos(workcat, "rural connectivity") > 0 ///
                        | strpos(workcat, "rural sanitation") > 0 ///
                        | strpos(workcat, "anganwadi") > 0 ///
                        | strpos(workcat, "rural infrastructure") > 0 ///
						| strpos(worktype, "hous")>0 ///
						| strpos(worktype, "shelter")>0 ///
						| strpos(worktype, "road")>0  ///
						| strpos(worktype, "toilet")>0  ///
						| strpos(worktype, "crematorium")>0  ///
						| strpos(worktype, "sand moram")>0  ///  this is for roads 
						| strpos(worktype, "play ground")>0 ///
						| strpos(worktype, "cement concrete") >0  /// for cc road (see work name) //
						| strpos(worktype, "anganwadi") > 0 ///
						| strpos(worktype, "bharat nirman") > 0 ///
						| strpos(worktype, "bhawan") > 0 ///
						| strpos(worktype, "shed") > 0 ///
						| strpos(worktype, "play field") > 0 ///
						| strpos(worktype, "produce storage") > 0 ///
						| strpos(worktype, "grain storage") > 0 ///
						| strpos(worktype, "compost")>0 
						

* If still missing, default to "other"
replace asset_class4 = 4 if missing(asset_class4) // nothing changed

label values asset_class4 asset4

****************************************************
* Assess results 
****************************************************
	tab asset_class4
	tab ownership

****************************************************
* Randomly select and order assets by asset class 
****************************************************

set seed 061510
	gen rand = runiform()

bysort district block panchayat asset_class4 (rand): gen randord_gp = _n
	gen selected = randord_gp <= 4 & asset_class4 == 1 
	replace selected = 1 if randord_gp <=4 & asset_class4 == 2
	replace selected = 1 if randord_gp <=4 & asset_class4 == 3
	replace selected = 1 if randord_gp <=2 & asset_class4 == 4
	
	
		
	gen target = selected == 1 & randord_gp <= 2 & asset_class4 == 1
		replace target = 1 if selected == 1 & randord_gp<=2 & asset_class4 == 2
		replace target = 1 if selected == 1 & randord_gp<=2 & asset_class4 == 3
		replace target = 1 if selected == 1 & randord_gp <= 1 & asset_class4 == 4
	gen buffer = (selected == 1 & target != 1)
	// for ongoing assets, we select up to 2 each of water extracting, water recharging, plantations, and 1 of other category (7 total) --> not all GPs have enough of each category
	

	rename panchayatname panchayat
export excel district block panchayat work* asset* selected target buffer using "${interdata}/02_Asset_Audit/barwani_pilot_selected_assets.xlsx" if selected == 1 & target == 1, ///
	sheet("ongoing_main_sample", replace) firstrow(var) 


export excel district block panchayat work* asset* selected target buffer using "${interdata}/02_Asset_Audit/barwani_pilot_selected_assets.xlsx" if selected == 1 & buffer == 1, ///
	sheet("ongoing_buffer", replace) firstrow(var) 
	
	 bys panchayat: count if target == 1

	
	g ongoing_asset = 1
	
	 
	 append using "`completed_assets'" 
	 
	 save "${interdata}/02_Asset_Audit/assets_barwani_pilot.dta", replace
	 
	 
	 
