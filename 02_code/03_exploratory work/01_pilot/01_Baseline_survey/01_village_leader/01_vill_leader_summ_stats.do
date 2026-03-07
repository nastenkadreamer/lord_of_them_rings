** purpose: generate latex tables of survey questions and summary stats to share with those interested in the work, potentially generate a few summary figures re: areas we should explore further 
** cmtm
** Jan 6, 2026

if "`c(username)'" == "cmtm" {
    do "/Users/cmtm/Dropbox (Personal)/Building Resilience IEIC/04 Data/02_code/00_master_building_resilience.do"
}
    

else if "`c(username)'"	== "anind" {
		global main "/Users/`c(username)'/Dropbox/Building Resilience Barwani/04 Data/02_code/00_master_building_resilience.do"
}
    /* else {
        /// add your paths here! 
    } */ 

pwd

use "${interdata}/01_Baseline_Survey/01_village_leader/village_leader_survey_barwani.dta"



/* Create output directories if they don't exist
cap mkdir "${myoutput}/Tables"
cap mkdir "${myoutput}/Tables/Village_Leader"
cap mkdir "${myoutput}/Figures"
cap mkdir "${myoutput}/Figures/Village_Leader"*/

*------------------------------------------------------------------------------*
* Water Access Section
*------------------------------------------------------------------------------*

* Summary statistics for water access
estpost summarize q8_8_sufficient_last_yr q8_14_water_acceptable
eststo water_summary
esttab water_summary using "${myoutput}/Tables/Village_Leader/water_summary.tex", ///
    cells("mean sd min max") label replace booktabs title("Summary Statistics: Water Access (Village Leader)") ///
    note("Note: Water sufficiency last year: 0=No, 1=Yes. Water acceptable: 1=Not acceptable, 2=Somewhat acceptable, 3=Acceptable, 4=Very acceptable.")

* Tabulation of primary drinking water sources
estpost tabulate q8_1_primary_drinking_source
eststo water_sources
esttab water_sources using "${myoutput}/Tables/Village_Leader/water_sources.tex", ///
    cells("b") label replace booktabs title("Distribution of Primary Drinking Water Sources (Village Leader)")

*------------------------------------------------------------------------------*
* Community Cooperation/Cohesion Section
*------------------------------------------------------------------------------*

* Summary statistics for cooperation and cohesion
estpost summarize q4_9_community_collective q4_2_family_trust q4_3_friends_trust q4_4_other_village_people_trust
eststo cooperation_summary
esttab cooperation_summary using "${myoutput}/Tables/Village_Leader/cooperation_summary.tex", ///
    cells("mean sd min max") label replace booktabs title("Summary Statistics: Community Cooperation and Cohesion (Village Leader)") ///
    note("Note: Trust variables: 1=Not trustworthy at all, 5=Completely trustworthy. Community collective: 1=Never come together, 4=Always come together.")

* Correlation between cooperation variables
eststo cooperation_corr: quietly correlate q4_9_community_collective q4_2_family_trust q4_3_friends_trust q4_4_other_village_people_trust
esttab cooperation_corr using "${myoutput}/Tables/Village_Leader/cooperation_corr.tex", ///
    unstack not noobs compress replace booktabs title("Correlations: Cooperation Variables (Village Leader)")

*------------------------------------------------------------------------------*
* Behavioral Beliefs Section
*------------------------------------------------------------------------------*

* Summary statistics for behavioral beliefs (reciprocity, risk, norms, etc.)
estpost summarize beh_pat1 beh_pat2 beh_pat3 beh_equi1 beh_equi2 beh_norms1 beh_norms2 beh_norms3 beh_risk1 beh_risk2 beh_risk3 beh_recip1 beh_alt1 beh_recip2 beh_risk4 beh_timepref1
eststo behavioral_summary
esttab behavioral_summary using "${myoutput}/Tables/Village_Leader/behavioral_summary.tex", ///
    cells("mean sd min max") label replace booktabs title("Summary Statistics: Behavioral Beliefs (Village Leader)") ///
    note("Note: Most variables: 1=Strongly disagree, 5=Strongly agree. Reciprocity (beh_recip1): 0=No, 1=Yes.")

*------------------------------------------------------------------------------*
* Water Investment Affordability Beliefs Section
*------------------------------------------------------------------------------*

* Summary statistics for beliefs about affordability of water investments
estpost summarize q10_1_af q10_2_af q10_3_af q10_4_af q10_5_af q10_6_af q10_7_af q10_8_af
eststo water_invest_beliefs
esttab water_invest_beliefs using "${myoutput}/Tables/Village_Leader/water_invest_beliefs.tex", ///
    cells("mean sd min max") label replace booktabs title("Summary Statistics: Water Investment Affordability Beliefs (Village Leader)") ///
    note("Note: Affordability beliefs: 1=No, 2=Yes (or scaled 1-5 for some).")

*------------------------------------------------------------------------------*
* Figures (export as PDF for LaTeX inclusion)
*------------------------------------------------------------------------------*

* Histogram of water sufficiency
histogram q8_8_sufficient_last_yr, title("Distribution of Water Sufficiency Last Year (Village Leader)") scheme(gg_tableau)
graph export "${myoutput}/Figures/Village_Leader/water_sufficiency_hist.pdf", replace

* Histogram of community collective action
histogram q4_9_community_collective, title("Distribution of Community Collective Action (Village Leader)") scheme(gg_tableau)
graph export "${myoutput}/Figures/Village_Leader/community_collective_hist.pdf", replace

* Histogram of reciprocity belief
histogram beh_recip1, title("Distribution of Reciprocity Belief (Village Leader)") scheme(gg_tableau)
graph export "${myoutput}/Figures/Village_Leader/reciprocity_hist.pdf", replace

* Scatter plot: family trust vs community collective
scatter q4_9_community_collective q4_2_family_trust, title("Community Collective vs Family Trust (Village Leader)") scheme(gg_tableau)
graph export "${myoutput}/Figures/Village_Leader/collective_trust_scatter.pdf", replace

* Bar chart of irrigation costs by GP (assume gp variable)
graph bar q8_32_cost_irr_kharif q8_34_cost_irr_rabi, over(gp) title("Irrigation Costs by Gram Panchayat (Village Leader)") scheme(gg_tableau)
graph export "${myoutput}/Figures/Village_Leader/irrigation_costs_by_gp.pdf", replace

*------------------------------------------------------------------------------*
* Combined Table
*------------------------------------------------------------------------------*

* Store multiple estimates for a combined table
eststo clear
eststo water: quietly mean q8_8_sufficient_last_yr
eststo cooperation: quietly mean q4_9_community_collective
eststo investment: quietly mean q8_32_cost_irr_kharif
eststo trust: quietly mean q4_2_family_trust

esttab water cooperation investment trust using "${myoutput}/Tables/Village_Leader/combined_stats.tex", ///
    cells("mean se") label replace booktabs title("Combined Summary Statistics (Village Leader)") ///
    note("Note: See individual tables for variable scales.")

* End of file