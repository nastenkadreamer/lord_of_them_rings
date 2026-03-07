# nrega_panel.do

This folder contains `nrega_panel.do`, a Stata script that builds a village*year panel dataset from the Excel workbook
`Barwani_data.xlsx` (Know Your Landscape export for Barwani, MP).

Files added
- `nrega_panel.do` — main Stata script. Auto-discovers Excel sheets and merges those containing a village identifier.
- `lint_stdin.R` — helper R script for linting unsaved R buffers (placed alongside other code).
- `.lintr` — minimal lintr config example for consistent lint rules.

Requirements
- Stata 15+ recommended (script uses `reshape`, `merge`, `xtset`). Should work on earlier versions with minor edits.
- For raster or geospatial processing, use R/Python to extract raster values and then import the CSV into Stata.

How it works (high-level)
1. The script sets the same path `globals` used by `01 clean.do` so it runs in the same project layout.
2. It attempts to import up to 100 sheets from `${kyldata}/Barwani MP/Barwani_data.xlsx`.
3. For each sheet it detects if there is a village identifier (variables like `vill_id`, `village_id`, `village`, `name`).
   - If none found the sheet is skipped and a message is printed.
4. If `year` is present the sheet is treated as long-format (vill_id + year + vars) and merged directly.
5. If no `year` but numeric columns with trailing 4-digit years are found (e.g., `asset2005`, `asset2006`), the script
   reshapes the sheet to long village*year form by inferring year suffixes.
6. Village-level attributes without year suffixes are merged as static attributes (year = .).
7. The script shortens overly-long variable names and preserves original names in variable labels.
8. The final panel is saved to `${cleaned}/Barwani_panel/nrega_panel.dta` and exported as CSV.

Run instructions
1. Open Stata with working directory that resolves the `globals` used in `01 clean.do` (or simply open Stata and run the `.do` file; the script sets globals when your username is `cmtm`).
2. From Stata, run:

    do "02 Code/04 Know Your Landscape/nrega_panel.do"

3. Inspect `${cleaned}/Barwani_panel/nrega_panel.dta` (or CSV) and check the variable labels if any names were shortened.

Troubleshooting & manual steps
- If sheets are skipped because no village identifier was detected, open those sheets and either add a consistent id column or
  edit `nrega_panel.do` to map the correct column name to `vill_id`.
- If a sheet uses non-numeric year columns or has year names in column headers not matching the 4-digit suffix pattern,
  adjust the stub-detection logic in the script where it searches for `[0-9]{4}$` in variable names.
- For spatial/raster sampling: run code in `nrega_analysis.R` or another R/Python script to sample raster values and produce a `processed_assets.csv`,
  then import that csv into Stata for panel merges.

Notes
- The script is intentionally conservative to avoid overwriting data silently; it prints messages for skipped sheets and failed renames.
- If you want me to customize the mapping for specific sheets (e.g., exact variable names for cropping intensity), tell me the sheet and the column names and I will update the `.do` file accordingly.

Contact
- If anything goes wrong or you want extra merges (e.g., merge MIS asset counts with extracted raster water stress values), tell me which sheets/CSV files to integrate.
