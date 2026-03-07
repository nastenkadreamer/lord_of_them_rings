/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

		Date		July 30, 2025
		Project		Building Resilience

		This .do file processes Know Your Landscape data to assess MGNREGS asset information for Barwani, MP.

		Author		Charity Moore moore.1736@osu.edu

	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    set more off
	clear all
	set scheme tab2
	
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*
	* Set paths
	*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   

	if "`c(username)'"=="cmtm" {
		glo path "/Users/cmtm/Dropbox (Personal)/Climate & MGNREGA/Data"
	}
        
		glo data			"${path}/01 Data"
		glo raw			    "${data}/01 Raw"
		glo inter			"${data}/02 Inter"
        glo cleaned			"${data}/03 Cleaned"
		glo figures			"${path}/04 Output/01 Figures"
		glo tables			"${path}/04 Output/02 Tables"
		glo tables2 		"/Users/cmtm/Pande Research Dropbox/Charity Moore/Apps/Overleaf/Building Resilience/Tables"

        glo kyldata         "${raw}/04 Know Your Landscape"

	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   
	
	// data is either mapped to the village or to a unique mws_id (not sure what that is from - weather station perhaps?)
	// but do have a mapping across the two 
		* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   

	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   
	
	// start w/ village level information: 
	
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   

// the kyl excel sheets include data from all types of land dimensions; for now just assessing a few of those along with NREGS assets 
import excel using "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("nrega_assets_village")  clear firstrow

    ** this data is wide and we want it to be long at the village level (it's a village*year dataset)
    ** rename misnamed variables and then reshape: 
    rename Soilandwaterconservation_coun Soilwatcons2005
    rename Offfarmlivelihoodassets_count Offfarmlive2005
    local i = 2006
    foreach var of varlist M T AA AH AO AV BC BJ BQ BX CE CL CS CZ DG DN DU EB EI EP {
        rename `var' Offfarmlive`i'
        local ++i 
    }
   
   local i = 2006
    foreach var of varlist P W AD AK AR AY BF BM BT CA CH CO CV DC DJ DQ DX EE EL ES {
        rename `var' Soilwatcons`i'
        local ++i 
    }

	tostring vill_id, replace
	// 8 villages out of 256 lack a matching id (only a name), so drop them for now
	duplicates tag vill_id, gen(dup)
		drop if dup > 0 
		drop dup

		
reshape long Offfarmlive Communityassets_count_ Irrigationonfarms_count_ Landrestoration_count_  Otherfarmworks_count_ Plantations_count_ Soilwatcons, i(vill_id) j(year)

// this data is at the yearly level and is not cumulative, so produce cdfs of average type of assets over the years 

* Calculate total asset counts per village by type over time
collapse (sum) Offfarmlive Communityassets_count_ Irrigationonfarms_count_ Landrestoration_count_ Otherfarmworks_count_ Plantations_count_ Soilwatcons, by(vill_id year)

foreach var of varlist Offfarmlive Communityassets_count_ Irrigationonfarms_count_ Landrestoration_count_ Otherfarmworks_count_ Plantations_count_ Soilwatcons {
    g cdf_`var' = `var' if year == 2005
    forv i = 2006/2025 {
        replace cdf_`var' = `var' + cdf_`var'[_n-1] if year == `i'
    }
}
	
	tempfile assets
		save "`assets'", replace 
		
		
// BRING IN CROPPING INTENSITY DATA: 		
import excel using  "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("croppingIntensity_annual") clear firstrow


	
// rename vars that are too long	
ds, 
local allvars `r(varlist)'
foreach v of local allvars {
    * Detect common long prefixes (case-insensitive): cropping_intensity, croppingintensity, cropintensity, cropping
	local vlab: var lab `v'
	local new_label = subinstr("`vlab'", "cropping_intensity_unit_", "cropint_unit", .)
	local new_label2 = subinstr("`new_label'", "single_cropped_area_in_ha", "singcrop_ha", .)
	local new_label3 = subinstr("`new_label2'", "doubly_cropped_area_in_ha", "doubcrop_ha", .)	
	local new_label4 = subinstr("`new_label3'", "triply_cropped_area_in_ha", "tripcrop_ha", .)
	local new_label5 = subinstr("`new_label4'", "single_kharif_cropped_area_in_ha", "singcrop_khar_ha", .)	
	local new_label6 = subinstr("`new_label5'", "doubly_kharif_cropped_area_in_ha", "doubcrop_khar_ha", .)
	local new_label7 = subinstr("`new_label6'", "triply_kharif_cropped_area_in_ha", "tripcrop_khar_ha", .)
	local new_label8 = subinstr("`new_label7'", "single_non_kharif_cropped_area_in_ha", "singcrop_nonkhar_ha", .)
	local new_label9 = subinstr("`new_label8'", "doubly_non_kharif_cropped_area_in_ha", "doubcrop_nonkhar_ha", .)
	local new_label10 = subinstr("`new_label9'", "triply_non_kharif_cropped_area_in_ha", "tripcrop_nonkhar_ha", .)
	local new_label11 = subinstr("`new_label10'", "-", "_", .)
		lab var `v' "`new_label11'"		
}
	
	
* Auto-detect letter-coded variables (1 or 2 alpha characters) and convert names to common label 
local letter_vars ""
	ds,  
	local allvars `r(varlist)'
foreach v of local allvars {
	 if regexm("`v'", "^[A-Z][A-Z]")|regexm("`v'", "^[A-Z]") local letter_vars "`letter_vars' `v'"
	}
	
	di "`letter_vars'"
	
	foreach varname in `letter_vars' {
	 	local vlab: var lab `varname'
		d `varname'
		rename `varname' `vlab'
	}

	tempfile cropping_intensity
		save "`cropping_intensity'", replace 
	
	
	
// bring in socioeconomic data from KYL: 
import excel using  "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("social_economic_indicator") clear firstrow
	notes: data is from SECC (2011)
	
	codebook village_id
	tostring village_id, gen(vill_id)
	
	
// 8 villages out of 256 lack a matching id (only a name), so drop them for now
	duplicates tag vill_id, gen(dup)
		drop if dup > 0 
		drop dup

		

merge 1:m vill_id using "`assets'", 
		
	
	scatter Irrigation SC_percent if year>=2017, by(year)
	scatter Irrigation ST_percent if year>=2017, by(year)
	
	scatter cdf_Irrigation SC_percent if year == 2023 
	scatter cdf_Landrestoration_count_ SC_percent if year == 2023 
	
	scatter cdf_Landrestoration_count_ literacy_rate_percent if year == 2023
	
	graph twoway (lowess cdf_Landrestoration_count_ literacy_rate_percent if year == 2023) ///
		(lowess cdf_Soilwatcons literacy_rate_percent if year == 2023, lcolor(green)) ///
		(lowess cdf_Plantations_count_ literacy_rate_percent if year == 2023, lcolor(black))
	
	
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   
	* 	now bring in nregs data at the unique id level, so can map to 
	*	well depth and socioeconomics 
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   
	
// merge on village ids so can map to assets 
// to facilitate this import, i saved the mws_intersect_villages worksheet as a .csv - since the import is easier this way 
import delimited "${kyldata}/Barwani MP/mws_village_idmapping.csv", bindquote(nobind) stripquote(yes) encoding(UTF-8) clear varn(1) 
	
	foreach var of varlist v*  {
		cap replace `var' = subinstr(`var', "[", "", .)
		cap replace `var' = subinstr(`var', "]", "", .)
		destring `var', replace
	} 
	
	
	rename villageids v2
	
	/*reshape long v, i(mwsuid) j(vill_id_count)
		replace vill_id_count = vill_id_count - 1
	*/
	
	rename mwsuid UID
	*rename v vill_id 
	
	tempfile mwsuid
		save "`mwsuid'", replace 
	
	
// merge in annual hydrological data at the unique id level 

import excel using  "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("hydrological_annual") clear firstrow
// make it simple: keep WellDepth for now

keep UID Well* Delta*
	reshape long WellDepth_in_m_ DeltaG_in_mm_, i(UID) j(year)
		tostring year, gen(yr)
		
	g year2 = substr(yr, 5, .)
	drop year yr 
		destring year2, replace 
		rename year2 year
	
	tempfile welldepth 
		save "`welldepth'"	
	
	
	/*merge m:1 UID using "`mwsuid'",
	tab _merge // merge 98% of wells to a UID with villages associated with them 
	*/
	
// for now, merge assets information on aggregated at the UID level to roughly assess extent of NREGS assets and well depth
import excel using  "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("nrega_annual") clear firstrow
	
		
	renvars Soil*, sub(Soilandwaterconservation swc)
// rename vars that are too long	
ds, 
local allvars `r(varlist)'
foreach v of local allvars {
    * Detect common long prefixes (case-insensitive): cropping_intensity, croppingintensity, cropintensity, cropping
	local vlab: var lab `v'
	local new_label = subinstr("`vlab'", "Soil and water conservation", "swc", .)
	local new_label2 = subinstr("`new_label'", "Off-farm livelihood assets", "offfarm_live", .)
	local new_label3 = subinstr("`new_label2'", "-", "_", .)
	local new_label4 = subinstr("`new_label3'", "Soilandwaterconservation", "swc", .)
		lab var `v' "`new_label4'"	
	
}
	
	
	/*
* Auto-detect letter-coded variables (1 or 2 alpha characters) and convert names to common label 

	ds,  
	local allvars `r(varlist)'
foreach v of local allvars {
		local mylab: var lab `v'
		if regexm("`mylab'", "swc") {
			rename "`v'" `mylab'
		}
	}
	
	
	if regexm("`v'", "^[A-Z][A-Z]") | regexm("`v'", "^[A-Z]") local letter_vars "`letter_vars' `v'"
	}
	
	di "`letter_vars'"
	
	foreach varname in `letter_vars' {
	 	local vlab: var lab `varname'
		d `varname'
		rename `varname' `vlab'
	}
something wront here - fix later - 
	*/ 
	
	rename swc_coun swc2005
	rename Offfarmlivelihoodassets_count offfarmlive2005
	local i = 2006
    
	foreach var of varlist N U AB AI AP AW BD BK BR BY CF CM CT DA DH DO DV EC EJ {

        rename `var' Offfarmlive`i'
        local ++i 
    }
	
	local i = 2006
	foreach var of varlist I P W AD AK AR AY BF BM BT CA CH CO CV DC DJ DQ DX EE {
		rename `var' swc`i'
		local ++i
	}
	
	renvars, lower 
	renvars plantations_count_*, sub(plantations_count plantn_ct)
	*renvars offfarmlivelihoodassets_ct, sub(offfarmlivelihoodassets_ct offfarm_asst_ct)
	renvars *, sub(count ct)
	
	
	reshape long communityassets_ct_ irrigationonfarms_ct_ landrestoration_ct_ otherfarmworks_ct_ plantn_ct_ offfarmlive swc, i(mws_id) j(year)
	
		renvars *, sub(_ )
		rename mwsid UID 
		
		
foreach var in communityassetsct irrigationonfarmsct landrestorationct otherfarmworksct plantnct offfarmlive swc {
    g cdf_`var' = `var' if year == 2005
    forv i = 2006/2025 {
        replace cdf_`var' = `var' + cdf_`var'[_n-1] if year == `i'
    }
}	
		
	merge 1:1 UID year using "`welldepth'" // data matches for 162/180 locations for 2018 - 2023 - so we'll focus on these for now 
	
	drop if (_m != 3 & _m != 2)
	
	tab _merge
	drop _merge
	
	save "`welldepth'", replace 
	
import excel using  "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("terrain_lulc_slope") clear firstrow

	keep UID area 
	
	merge 1:m UID using "`welldepth'"
	
	
	// assets per hectare

	
	foreach var of varlist cdf_* {
		g `var'_pha = `var'/area
		g ln`var' = ln(`var')
		g ln`var'_pha = ln(`var'_pha)
		sum `var', d
		g `var'_99 = `var'
			replace `var'_99 = r(p99) if `var'>r(p99) & `var' !=. 
			g `var'_99pha = `var'_99/area
		}
		
		foreach var of varlist Delta* {
			g ln`var' = ln(`var')
		}
	
	twoway (scatter cdf_irrigationonfarmsct_pha Delta* if year == 2023)
	twoway (scatter cdf_swc_pha Delta* if year == 2023)
	
// need to merge on the area i think too 
	
	sum cdf_*, d
	
	
	save "${inter}/barwani_pilot_data.dta", replace 
/*
	twoway (scatter cdf_irrigationonfarmsct_pha Delta* if year == 2023) ///
		 (lfit cdf_irrigationonfarmsct_pha Delta* if year == 2023) 
	

	twoway (scatter cdf_swc_pha Delta* if year == 2023) ///
		 (lfit  cdf_swc_pha Delta* if year == 2023) 
	
	
	twoway (scatter cdf_plantnct_pha Delta* if year == 2023) ///
		 (lfit  cdf_plantnct_pha Delta* if year == 2023) 
	
	twoway (scatter lncdf_irrigationonfarmsct_pha Delta* if year == 2023) ///
		(lfit lncdf_irrigationonfarmsct_pha Delta* if year == 2023) 
		
	twoway (scatter cdf_irrigationonfarmsct_99pha Delta* if year == 2023) ///
		 (lfit cdf_irrigationonfarmsct_99pha Delta* if year == 2023) 
		 
			
	twoway (scatter cdf_swc_99pha Delta* if year == 2023) ///
		 (lfit cdf_swc_99pha Delta* if year == 2023)  
		 
	twoway (scatter cdf_plantnct_99pha Delta* if year == 2023) ///
		 (lfit cdf_plantnct_99pha Delta* if year == 2023)  	 */
	
	
	// Positive Δh (or ΔG in mm) → water table went further down → less water available.
	// Negative Δh (or ΔG in mm) → water table rose → more water available.
	
	// if want to bring in demographics, would need to develop a watershed wide version of mean literacy/SC/ST percents
	
	
// Data from MP survey: 
use "/Users/cmtm/Library/CloudStorage/GoogleDrive-cmtm1026@gmail.com/.shortcut-targets-by-id/19qCAXIEFghRHkd2CsJGXRTr_KrjcRsIJ/WISE_MP/04 Data/03 Intermediate Data/Baseline Field Data/Village Information Survey/Final Datasets/vill_info_relabelled.dta", clear 

g gw_improving = (water_assets_undertaken_7==1 |  water_assets_undertaken_6 == 1 | water_assets_undertaken_10 == 1 | water_assets_undertaken_8==1)
g gw_neutral = (water_assets_undertaken_5 ==1 | water_assets_undertaken_3 == 1 | water_assets_undertaken_11==1)
g gw_low = (water_assets_undertaken_1==1 | water_assets_undertaken_2 ==1 | water_assets_undertaken_4 ==1 | water_assets_undertaken_9 ==1)

// asset classification related to water done as reported by claude: https://claude.ai/share/ce33c417-2ccc-4fe4-a976-1a4179fc4f55


	cibar gw_improving, over1(water_access)
	cibar gw_neutral, over1(water_access)
	cibar gw_low, over1(water_access)	
	
	
	g water_chal = (challenges_gp_1==1 |challenges_gp_2==1)
	g survey_pre_JGN = date_subm<td(01apr2025)
	lab var water_chal "Water Top Community Challenge"
	lab var water_access "People in GP Face Issues Accessing Water"
		lab define water_chal 0 "No" 1 "Water Top GP Challenge", modify
		lab define water_access 0 "No" 1 "People in GP Face Issues Accessing Water", modify
		
		lab val water_chal water_chal
		
		lab val water_access water_access
	
	lab var gw_improving "\specialcell{ High\\ Groundwater-Improving \\ Asset}"
	lab var gw_neutral "\specialcell{ Moderate\\ Groundwater- Improving\\ Asset}"
	lab var gw_low "\specialcell{ Low\\ Groundwater- Improving\\ Asset}"
	
	g gw_none = water_assets == 0
	g gw_any = water_assets == 1 
		lab var gw_none "Not Undertaken Water Investments"
		lab var gw_any "\specialcell{Undertaken Any \\ Water-Related \\ Investments}"
 
 foreach var of varlist gw_any gw_low gw_neutral gw_improving {
	eststo `var': reghdfe `var' water_chal i.survey_pre_JGN , clu(final_district_id) a(final_district_id)
	eststo `var'2: reghdfe `var' water_access i.survey_pre_JGN , clu(final_district_id) a(final_district_id)
	*reghdfe `var' water_chal##i.survey_pre_JGN , clu(final_block_id) a(final_block_id)
}
	
	
	/*esttab gw_low gw_low2 gw_neutral gw_neutral2 gw_improving gw_improving2 ///
		using "$tables2/water_invest_mp.tex", replace ///
		keep(water_chal water_access  _cons) label ///
		prehead("\begin{adjustbox}{max width=\textwidth}" "\begin{tabular}{l*{6}{c}}") ///
    postfoot("\end{tabular}" "\end{adjustbox}")
	*/
	
	
	esttab gw_any gw_any2 gw_low gw_low2 gw_neutral gw_neutral2 gw_improving gw_improving2 ///
    using "$tables2/water_invest_mp.tex", replace ///
    keep(water_chal water_access _cons) label ///
    mgroups("Any Water Investment(s)" "Low Groundwater-Enhancing Investment(s)" "Moderate Groundwater-Enhancing Investment(s)" "High Groundwater-Enchancing Investment(s)", ///
            pattern(1 0 1 0 1 0 1 0) ///
            prefix(\multicolumn{@span}{c}{) suffix(}) ///
            span erepeat(\cmidrule(lr){@span})) ///
			nomtitles /// 
    prehead("\begin{adjustbox}{max width=\textwidth}" "\begin{tabular}{l*{8}{c}}" "\hline\hline") ///
    postfoot("\hline\hline" "\end{tabular}" "\end{adjustbox}") ///
    addnotes("Survey data from Madhya Pradesh village leader survey described in \citep{bhattacharyaetal2025}. Standard errors clustered at the district level in parentheses; district fixed effects and indicator for water initiative start date not shown." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1")
			 
			 
		tempfile vill_info
			save "`vill_info'", replace 
			 
			 
	use "/Users/cmtm/Library/CloudStorage/GoogleDrive-cmtm1026@gmail.com/.shortcut-targets-by-id/19qCAXIEFghRHkd2CsJGXRTr_KrjcRsIJ/WISE_MP/04 Data/03 Intermediate Data/Baseline Field Data/Household Survey/Final Datasets/hh_listing_relabelled_6.dta", clear
		 
		 
		keep final_village_id q3_caste practice_nep 
			qui tab practice_nep, g(nep)
			qui tab q3_caste, g(caste)
			
		collapse (mean) nep4 nep5 nep6 caste*, by(final_village_id)
		
		merge 1:m final_village_id using "`vill_info'", gen(_vill_merge)
		
		
	
	/*prehead("\begin{adjustbox}{max width=\textwidth}" "\begin{tabular}{l*{6}{c}}" "\hline\hline") ///
    posthead("\hline" ///
             "\multicolumn{7}{l}{\textbf{Panel A: Low Groundwater}} \\" "\hline") ///
    prefoot("\hline" ///
            "\multicolumn{7}{l}{\textbf{Panel B: Neutral Groundwater}} \\" "\hline" ///
            /* Insert Panel B results here */) ///
    postfoot("\hline" ///
             "\multicolumn{7}{l}{\textbf{Panel C: Improving Groundwater}} \\" "\hline" ///
             /* Insert Panel C results here */ ///
             "\hline\hline" ///
             "\end{tabular}" "\end{adjustbox}") ///
    addnotes("Standard errors in parentheses." ///
             "*** p$<$0.01, ** p$<$0.05, * p$<$0.1")*/
	
	/*
	/*scatter Soilwat SC_percent, by(year)
	
	
	// change in water body coverage or aquifer coverage, correlation w/ MGNREGS assets -- by literacy or SC/ST level
	

/*

collapse (mean) cdf_* , by(year)

* Plot CDFs for all asset types over time with legend

keep if year>=2015 // really nothing happening before this 
twoway ///
    (line cdf_Offfarmlive year, lcolor(ebblue*.8) lwidth(medthin) lpattern(dash)) ///
    (line cdf_Communityassets_count_ year, lcolor(teal*.8) lwidth(medthin) lpattern(dash)) ///
    (line cdf_Irrigationonfarms_count_ year, lcolor(ebblue*1.2) lwidth(medthick) lpattern(solid)) ///
    (line cdf_Landrestoration_count_ year, lcolor(seagreen*.8) lwidth(medthin) lpattern(longdash)) ///
    (line cdf_Otherfarmworks_count_ year, lcolor(navy*.8) lwidth(medthin) lpattern(shortdash)) ///
    (line cdf_Plantations_count_ year, lcolor(ltblue*.8) lwidth(medthin) lpattern(dash_dot)) ///
    (line cdf_Soilwatcons year, lcolor(emerald*.7) lwidth(medthick) lpattern(solid)) ///
    , legend(order(1 "Off-farm Livelihood" 2 "Community Assets" 3 "Irrigation on Farms" 4 "Land Restoration" 5 "Other Farm Works" 6 "Plantations" 7 "Soil & Water Conservation")) ///
    title("Average Number Constructed MGNREGS Assets per Village", size(medsmall)) ///
    xtitle("Year") ///
    ytitle("Cumulative Asset Count") ///
    graphregion(color(white)) ///
    bgcolor(white) ///
    caption("Barwani district, Madhya Pradesh; Source: MGNREGS MIS via Know Your Landscape portal", size(small)) 

graph export "${figures}/barwani_asset_cdf.png", as(png) replace 
graph export "${figures}/barwani_asset_cdf.pdf", as(pdf) replace 


** next step - assess correlation between irrigation assets on farms, SWC, with water scarcity/stress in location
