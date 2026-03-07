/* rename_croppingIntensity.do
   - Import the sheet "croppingIntensity_annual" from Barwani_data.xlsx
   - For variables imported as single letters (I K L O Q R W X AA AC AD AG AI AJ ...),
     read their variable label, extract a shortened name (substring after "crop"/"cropping" when present),
     sanitize the name for Stata variable naming rules, ensure uniqueness, and rename the variable.
   - Save a mapping of old variable -> new variable -> original label to
     ${cleaned}/Barwani_panel/cropping_varname_map.csv

   Usage: run in Stata from project root so the same globals as `01 clean.do` resolve.
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
global cleaned "${data}/03 Cleaned"
global kyldata "${raw}/04 Know Your Landscape"

display as text "Importing croppingIntensity_annual from: ${kyldata}/Barwani MP/Barwani_data.xlsx"

capture noisily import excel using "${kyldata}/Barwani MP/Barwani_data.xlsx", sheet("croppingIntensity_annual") clear firstrow
if _rc {
    display as error "Failed to import croppingIntensity_annual (rc=`_rc'). Please check path and sheet name."
    exit 1
}

* First: shorten any variable name prefixes that refer to cropping intensity to a compact prefix 'cropint'
ds, has(type any)
local allvars `r(varlist)'
foreach v of local allvars {
    * Detect common long prefixes (case-insensitive): cropping_intensity, croppingintensity, cropintensity, cropping
    if regexm("`v'", "(?i)^(cropping_intensity|croppingintensity|cropintensity|cropping|croppingint)" ) {
        local new = regexr("`v'", "(?i)^(cropping_intensity|croppingintensity|cropintensity|cropping|croppingint)", "cropint")
        * sanitize new to valid Stata name (lowercase, underscores)
        local new : lower "`new'"
        local new : subinstr local new "-" "_" .
        local new : subinstr local new " " "_" .
        * truncate
        local new = substr("`new'", 1, 32)
        capture rename `v' `new'
        if _rc display as error "Failed to rename long prefix `v' -> `new' (rc=`_rc')"
        else display as result "Renamed long prefix `v' -> `new'"
    }
}

* Auto-detect letter-coded variables (1 or 2 alpha characters)
local letter_vars ""
ds, has(type numeric)
local numeric_vars `r(varlist)'
foreach v of local numeric_vars {
    if regexm("`v'", "^[A-Za-z]{1,2}$") local letter_vars "`letter_vars' `v'"
}
display as text "Letter-coded variables detected: `letter_vars'"

* Prepare postfile to collect mapping
tempfile map_dta
postfile maphandle str32 oldname str32 newname str200 origlabel using "`map_dta'", replace

local used ""
local counter = 1

foreach v of varlist `letter_vars' {
    capture confirm variable `v'
    if _rc {
        di as text "Variable `v' not present in sheet - skipping"
        continue
    }
    * Read full variable label
    local lab : variable label `v'
    if "`lab'" == "" local lab "(no label)"
    di as text "`v' label: `lab'"

    * Attempt to extract substring after 'crop' or 'cropping' (case-insensitive)
    local short ""
    if regexm("`lab'", "(?i)cropp?ing[_[:space:][:punct:]]*(.*)") {
        local short = regexs(1)
    }
    else if regexm("`lab'", "(?i)crop[_[:space:][:punct:]]*(.*)") {
        local short = regexs(1)
    }
    else if regexm("`lab'", "(?i)area[_[:space:][:punct:]]*(.*)") {
        local short = regexs(1)
    }
    else {
        * fallback: use the entire label
        local short = "`lab'"
    }

    * Trim whitespace
    local short : trim "`short'"
    * convert to lowercase
    local short : lower "`short'"
    * Replace spaces and common punctuation with underscore
    local short : subinstr local short " " "_" .
    local short : subinstr local short "/" "_" .
    local short : subinstr local short "-" "_" .
    local short : subinstr local short ":" "_" .
    local short : subinstr local short "," "" .
    local short : subinstr local short "%" "pct" .
    local short : subinstr local short "(" "" .
    local short : subinstr local short ")" "" .
    local short : subinstr local short "&" "_and_" .

    * Remove any remaining non-alphanumeric or underscore characters
    while regexm("`short'", "[^a-z0-9_]") {
        local short = regexr("`short'", "[^a-z0-9_]", "")
    }

    * Ensure it doesn't start with a digit
    if regexm("`short'", "^[0-9]") {
        local short = "v_`short'"
    }

    * Truncate to 28 chars for safety
    local short = substr("`short'", 1, 28)

    * Ensure uniqueness
    local base = "`short'"
    local suffix = 1
    while strpos(" `used' ", " `short' ") {
        local short = substr("`base'", 1, 24) + "_" + string(`suffix')
        local ++suffix
    }
    local used "`used' `short'"

    * Perform rename
    capture rename `v' `short'
    if _rc {
        di as error "Failed to rename `v' -> `short' (rc=`_rc')"
        continue
    }
    else {
        di as result "Renamed `v' -> `short'  (label: `lab')"
    }

    post maphandle ("`v'") ("`short'") ("`lab'")
}

postclose maphandle

* Save mapping dataset and export CSV for review
use "`map_dta'", clear
save "${cleaned}/Barwani_panel/cropping_varname_map.dta", replace
export delimited using "${cleaned}/Barwani_panel/cropping_varname_map.csv", replace

di as text "Mapping saved to ${cleaned}/Barwani_panel/cropping_varname_map.csv"

/* End */
