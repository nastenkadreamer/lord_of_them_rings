**************************************************************************************************************
**************************************************************************************************************
** File name: 00_master_building_resilience.do 
** Purpose: set up master paths for pilot village leader, citizen surveys, and asset audits 
** Created by: CMTM
** Date written: December 31, 2025
** Edited by: 
** Last Edited Date:  
**************************************************************************************************************
**************************************************************************************************************
*------------------------------------------------------------------------------*
* Setup
*------------------------------------------------------------------------------*

	macro drop _all
	lab drop _all
	clear all
	pause on
	set maxvar 30000
	set matsize 10000
	set more off
	set varabbrev on	
	graph set svg fontface "Garamond"
	graph set window fontface garamond
	cap log close


	/* Making sure packages are loaded */ // Add to these as needed:
		foreach package in fre catplot statplot elabel reclink estout {
  			capture which `package'
  			if _rc == 111 ssc install `package'
		}

		
	
*------------------------------------------------------------------------------*	
* GLOBAL USER PATHS
*------------------------------------------------------------------------------*

		
	if "`c(username)'" == "cmtm" {
			global main "/Users/`c(username)'/Dropbox (Personal)/Building Resilience IEIC/04 Data"
			global mainencrypted "/Users/cmtm/Desktop/Charity\'s\ Encrypted\ Data/Building_Resilience"
			global myoutput "/Users/cmtm/Pande Research Dropbox/Charity Moore/Apps/Overleaf/Building Resilience/2025 Pilot"
	}
		
	else if "`c(username)'"	== "anind" {
		global main "/Users/`c(username)'/Dropbox/Building Resilience IEIC/04 Data"
		global myoutput "/Users/anind/Dropbox/Building Resilience Barwani/04 Data/04_output"
	}

	
		
	global rawsurvey "${mainencrypted}/raw/Barwani_Pilot_2025"
	global raw_assets "${main}/01_data/01 Raw/02_Asset_Audit"
	
	global interdata "${main}/01_data/02 Inter"
	global cleandata "${main}/01_data/03 Clean" 

	
* Setting scheme
	set scheme gg_tableau
		
*------------------------------------------------------------------------------*	
* ADD ADDITIONAL GLOBALS HERE
*------------------------------------------------------------------------------*




