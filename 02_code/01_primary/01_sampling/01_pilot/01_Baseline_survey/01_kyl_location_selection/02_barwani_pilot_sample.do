* draw pilot sample for Barwani Nov 2025 pilot survey on water and assets
* cmtm
* nov 16, 2025

use "${inter}/barwani_pilot_data.dta", clear

// create a strata for # nrega NRM/water-linked assets ever constructed - above/below median 
// cdf is a misnomer - but this tells us the # of these assets produced by nregs over time
g tot_water_restore_assets =  cdf_landrestorationct + cdf_plantnct + cdf_swc if year == 2023
xtile abmed_NRM = tot_water_restore_assets, n(2)
replace abmed_NRM = 0 if abmed_NRM == 1
	replace abmed_NRM =1 if abmed_NRM == 2
	
	lab var abmed_NRM "Above median total water-supporting NREGS assets in Barwani (2023)"


// create another strata for well levels (supposedly water table levels, although we're not fully certain!) Need to resolve for future sampling
xtile abmed_well_depth = WellDepth_in_m_ if year == 2023, n(2)
	replace abmed_well_depth = 0 if abmed_well_depth == 1
	replace abmed_well_depth =1 if abmed_well_depth == 2
		lab var abmed_well_depth "Above median well depth (2023)"
		
		
		egen strata = group(abmed_NRM abmed_well_depth)

		
	keep if !mi(strata)
	keep UID ab* strata
	
		tempfile sampling_info 
			save "`sampling_info'", replace
			
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
	
	
	merge m:1 UID using "`sampling_info'"
		renvars v*, sub(v vill_)
		
		forv i = 2 /15 { 
			local j = `i' - 1
			rename vill_`i' vill_`j'
		}

	
		
		
	export excel using "/Users/cmtm/Dropbox (Personal)/Building Resilience Barwani/01 Data/01 Raw/01_Barwani_Pilot/01_sampling/GP_lists_assets_water.xls", firstrow(variables) replace //
	// awk - update paths!
