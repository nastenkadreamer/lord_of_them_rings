/* nrega_panel.do
   Build a village*year panel from Barwani_data.xlsx following the approach in 01 clean.do
   - Imports 'nrega_assets_village' (main wide asset table), renames and reshapes to long
   - Imports selected annual sheets (e.g., croppingIntensity_annual) and merges them by vill_id & year
   - Shortens overly-long variable names, preserves original names in variable labels
   - Saves `nrega_panel.dta` and `nrega_panel.csv` in the cleaned data folder

   Usage: run this from the project folder (it mirrors the globals used in 01 clean.do)
*/

capture log close
set more off
clear all
set scheme tab2

* --- Path setup (mirror 01 clean.do) ---
if "`c(username)'"=="cmtm" {
    global path "/Users/cmtm/Dropbox (Personal)/Climate & MGNREGA/Data"
}

global data "${path}/01 Data"
global raw  "${data}/01 Raw"
global inter "${data}/02 Inter"
global cleaned "${data}/03 Cleaned"
global figures "${path}/04 Output/01 Figures"
global tables "${path}/04 Output/02 Tables"

global kyldata "${raw}/04 Know Your Landscape"

display as text "Using kyldata = ${kyldata}"

* --- Create output dir if needed ---
cap mkdir "${cleaned}/Barwani_panel"

* ---------------------------------------------------------------------
* 1) Import nrega_assets_village (wide) and standardize column names
* ---------------------------------------------------------------------
import excel using "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("nrega_assets_village") clear firstrow

* Ensure we have a village id variable; common names: vill_id, village_id, id
* If vill_id doesn't exist but vill name exists, keep it and user can map later
capture confirm variable vill_id
if _rc {
    capture confirm variable village_id
    if !_rc {
        rename village_id vill_id
    }
}

* Print variables for quick visual check
ds

* The original 01 clean.do used explicit renames (Excel columns) to place years in variable names.
* We'll attempt the same renames but only when the source variable exists.

* Rename long descriptive column names to a short base + year for two groups: Offfarmlive and Soilwatcons
capture confirm variable Soilandwaterconservation_coun
if !_rc {
    rename Soilandwaterconservation_coun Soilwatcons2005
}
capture confirm variable Offfarmlivelihoodassets_count
if !_rc {
    rename Offfarmlivelihoodassets_count Offfarmlive2005
}

* The original used lists of Excel column names (letters) mapping to years 2006+.
* We'll attempt those renames only if the letter-variables exist in this sheet.
local year = 2006
foreach col in M T AA AH AO AV BC BJ BQ BX CE CL CS CZ DG DN DU EB EI EP {
    capture confirm variable `col'
    if !_rc {
        cap rename `col' Offfarmlive`year'
    }
    local ++year
}

local year = 2006
foreach col in P W AD AK AR AY BF BM BT CA CH CO CV DC DJ DQ DX EE EL ES {
    capture confirm variable `col'
    if !_rc {
        cap rename `col' Soilwatcons`year'
    }
    local ++year
}

* If the dataset contains variables with explicit year suffixes already (e.g., _2005, _2006), no rename occurs.

* --- Shorten overly long variable names safely ---
* Build a list of variables with names longer than 30 characters and shorten them while saving original in var label.

local usednames ""
local ctr = 1
foreach v of varlist _all {
    local len = strlen("`v'")
    if `len' > 30 {
        local new = substr("`v'", 1, 28) 
        * ensure uniqueness
        while strpos(" `usednames' ", " `new' ") {
            local new = substr("`v'", 1, 25) + "_" + string(`ctr')
            local ++ctr
        }
        * store used
        local usednames "`usednames' `new'"
        * set var label to original name
        label variable `v' "orig:`v'"
        rename `v' `new'
        * restore label to hold original name (label now attached to new var)
        label variable `new' "original: `v'"
    }
}

* --- Prepare list of asset variables to reshape ---
* Identify variables that look like Offfarmlive* or Soilwatcons* or other repeated measures
ds Offfarmlive* Soilwatcons* , has(type numeric)
local assetvars `r(varlist)'

* If assetvars is empty, try an alternate pattern (variables ending with 4-digit year)
if "`assetvars'" == "" {
    ds, has(type numeric)
    local allvars `r(varlist)'
    local assetvars ""
    foreach v of local allvars {
        if regexm("`v'", "[0-9]{4}$") {
            local assetvars "`assetvars' `v'"
        }
    }
}

display as text "Asset variables detected for reshape: `assetvars'"

* If no asset variables detected, stop with a hint
if "`assetvars'" == "" {
    display as error "No repeat-measure asset variables detected. Inspect the dataset and modify this script to match your column naming convention."
    exit 1
}

* --- Reshape wide-to-long: create village*year panel for asset variables ---
* Before reshape we need a unique id variable (vill_id). If not numeric, keep it as is but ensure a numeric id is available.
capture confirm variable vill_id
if _rc {
    display as error "No variable 'vill_id' found. Please provide a village id column or modify the script to set the id variable."
    exit 1
}

* Create numeric village id if vill_id is string
capture confirm numeric variable vill_id
if _rc {
    * vill_id exists but not numeric -> create numeric code
    encode vill_id, gen(vill_id_num)
    quietly replace vill_id_num = vill_id_num
    rename vill_id vill_id_str
    rename vill_id_num vill_id
    label variable vill_id "Village id (coded from vill_id_str)"
}

* Reshape: We expect variables like Offfarmlive2005 Offfarmlive2006 ... Soilwatcons2005 ...
* Build varlists by stem
local stems Offfarmlive Soilwatcons
local reshape_vars ""
foreach s of local stems {
    ds `s'* 
    if "`r(varlist)'" != "" {
        local reshape_vars "`reshape_vars' `r(varlist)'
    }
}
* Remove leading spaces
local reshape_vars : list reshape_vars

display as text "Variables to reshape: `reshape_vars'"

* Try to infer year suffix from variable names. Create temp names like <stem>_2005 etc.
tempfile assets_wide
save "`assets_wide'", replace

* Create an indicator of variable-year pairing and reshape using -reshape- with j(year)
* We will create lists like Offfarmlive2005 Offfarmlive2006 -> Offfarmlive*

* For safety, create a mapping file in memory: create long form by looping stems and years
preserve
keep vill_id
foreach s of local stems {
    * collect vars for this stem
    ds `s'*
    local vars `r(varlist)'
    if "`vars'" == "" continue
    * determine years present (handle YYYY, YYYY-YYYY, YYYY-YY, YY-YY fiscal suffixes)
    local years ""
    foreach v of local vars {
        local yr ""
        * Case 1: trailing 4-digit year (e.g., var2005)
        if regexm("`v'", "([0-9]{4})$") {
            local yr = regexs(1)
        }
        else if regexm("`v'", "^(.*?)([0-9]{4})[-_/]([0-9]{2,4})$") {
            * e.g. 2017-2018 or 2017-18 -> take second group as end-year
            local g1 = regexs(2)
            local g2 = regexs(3)
            if strlen("`g2'") == 4 {
                local yr = "`g2'"
            }
            else {
                * g2 is 2-digit (e.g. 18) -> take century from g1
                local century = string(floor(real("`g1'")/100)*100)
                local yr = string(real("`century'") + real("`g2'"))
            }
        }
        else if regexm("`v'", "^(.*?)([0-9]{2})[-_/]([0-9]{2})$") {
            * e.g. 17-18 -> assume 2000-based years -> take second as final year
            local g2 = regexs(3)
            local yr = string(2000 + real("`g2'"))
        }
        if "`yr'" != "" local years "`years' `yr'"
    }
    local years : list years
    * for each year, create a temporary var with name <stem>_`yr' and copy the values
    use "`assets_wide'", clear
    foreach v of local vars {
        local yr ""
        if regexm("`v'", "([0-9]{4})$") {
            local yr = regexs(1)
        }
        else if regexm("`v'", "^(.*?)([0-9]{4})[-_/]([0-9]{2,4})$") {
            local g1 = regexs(2)
            local g2 = regexs(3)
            if strlen("`g2'") == 4 {
                local yr = "`g2'"
            }
            else {
                local century = string(floor(real("`g1'")/100)*100)
                local yr = string(real("`century'") + real("`g2'"))
            }
        }
        else if regexm("`v'", "^(.*?)([0-9]{2})[-_/]([0-9]{2})$") {
            local g2 = regexs(3)
            local yr = string(2000 + real("`g2'"))
        }
        if "`yr'" == "" {
            display as error "Could not infer year suffix from variable `v' -- keeping original name and skipping year parsing"
            continue
        }
        gen `s'_`yr' = `v'
    }
    tempfile tmp_`s'
    keep vill_id `s'_* 
    save "`tmp_`s''", replace
    restore
    merge 1:1 vill_id using "`tmp_`s''", nogen
}

* At this point we should have variables with pattern <stem>_YYYY for each stem.
* Build a consolidated dataset with vill_id and repeated-year variables
save "${cleaned}/Barwani_panel/assets_with_years.dta", replace

* Now reshape long across the stems; we choose Offfarmlive and Soilwatcons as example
use "${cleaned}/Barwani_panel/assets_with_years.dta", clear

* Build lists of variables by stem to feed reshape
ds Offfarmlive*_*, has(type numeric)
local ofv `r(varlist)'
ds Soilwatcons*_*, has(type numeric)
local swc `r(varlist)'

* A helper to remove trailing underscore if present
local ofv : list ofv
local swc : list swc

display as text "Offfarm vars: `ofv'"
display as text "SWC vars: `swc'"

* Make sure we have a year variable encoded in names; reshape will use j(year)
* Create temporary wide structure with combined names: we will prefix variable names with their stem so reshape can be used
* Because reshape in Stata expects common stub names (e.g., of_2005 of_2006 ...), we'll reshape each stem separately and then merge long results by vill_id year.

* Reshape Offfarmlive
if "`ofv'" != "" {
    tempfile long_of
    preserve
    keep vill_id `ofv'
    * rename OfffarmliveYYYY -> ofYYYY (short stub)
    local i = 1
    foreach v of varlist `ofv' {
        local yr ""
        if regexm("`v'", "([0-9]{4})$") {
            local yr = regexs(1)
        }
        else if regexm("`v'", "^(.*?)([0-9]{4})[-_/]([0-9]{2,4})$") {
            local g1 = regexs(2)
            local g2 = regexs(3)
            if strlen("`g2'") == 4 {
                local yr = "`g2'"
            }
            else {
                local century = string(floor(real("`g1'")/100)*100)
                local yr = string(real("`century'") + real("`g2'"))
            }
        }
        else if regexm("`v'", "^(.*?)([0-9]{2})[-_/]([0-9]{2})$") {
            local g2 = regexs(3)
            local yr = string(2000 + real("`g2'"))
        }
        if "`yr'" == "" {
            display as error "Could not infer year suffix from variable `v' -- keeping original name and skipping rename"
            continue
        }
        capture rename `v' of`yr'
    }
    reshape long of, i(vill_id) j(year)
    rename of value_offfarm
    save "`long_of'", replace
    restore
}

* Reshape Soilwatcons
if "`swc'" != "" {
    tempfile long_swc
    preserve
    keep vill_id `swc'
    foreach v of varlist `swc' {
        local yr ""
        if regexm("`v'", "([0-9]{4})$") {
            local yr = regexs(1)
        }
        else if regexm("`v'", "^(.*?)([0-9]{4})[-_/]([0-9]{2,4})$") {
            local g1 = regexs(2)
            local g2 = regexs(3)
            if strlen("`g2'") == 4 {
                local yr = "`g2'"
            }
            else {
                local century = string(floor(real("`g1'")/100)*100)
                local yr = string(real("`century'") + real("`g2'"))
            }
        }
        else if regexm("`v'", "^(.*?)([0-9]{2})[-_/]([0-9]{2})$") {
            local g2 = regexs(3)
            local yr = string(2000 + real("`g2'"))
        }
        if "`yr'" == "" {
            display as error "Could not infer year suffix from variable `v' -- keeping original name and skipping rename"
            continue
        }
        capture rename `v' swc`yr'
    }
    reshape long swc, i(vill_id) j(year)
    rename swc value_swc
    save "`long_swc'", replace
    restore
}

* Merge long datasets by vill_id and year
preserve
use "`long_of'", clear
sort vill_id year
if "`swc'" != "" {
    merge 1:1 vill_id year using "`long_swc'", keep(master match) nogen
}

* If you have other annual sheets to merge (cropping intensity, etc.), import them similarly and merge on vill_id year.
* Example: import croppingIntensity_annual and merge
capture noisily import excel using "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("croppingIntensity_annual") clear firstrow
if _rc == 0 {
    * Expect columns vill_id and year or year-coded columns; attempt to standardize
    capture confirm variable vill_id
    if _rc {
        display as error "croppingIntensity_annual: no vill_id found; adjust the sheet format or mapping in this script"
    } else {
        * If year is a column, use it; otherwise pivot similar to above
        capture confirm variable year
        if !_rc {
            tempfile crop_long
            keep vill_id year cropping_intensity_unit_less_201 // adjust to actual variable names if different
            save "`crop_long'", replace
            merge 1:1 vill_id year using "`crop_long'", nogen
        }
    }
}

* Final panel cleanup
sort vill_id year
xtset vill_id year, yearly

* Save final datasets
save "${cleaned}/Barwani_panel/nrega_panel.dta", replace
export delimited using "${cleaned}/Barwani_panel/nrega_panel.csv", replace

display as text "Saved panel to ${cleaned}/Barwani_panel/nrega_panel.dta and CSV"

* End of file



