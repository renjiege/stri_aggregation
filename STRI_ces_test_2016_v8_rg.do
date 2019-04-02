/* 
Version 7 of the program nests the 2008, 2016 and 2016 comparable 
aggregation of raw measure scores in one file.  
	1. STRI_ces_test_2008_v5.do
	2. STRI_ces_test_2016_comparable_with_2008_v5.do
	3. STRI_ces_test_2016_v6.do

Version 8 makes adjustments to sectors weights for aggregation to country-level, depending on whether 2008 or 2016 scores are to be aggregated.

This program requires the following ancillary datasets to run:
1. tmp_WDI_2008-16.dta
2. WALI_2012_rescaled
*/

clear all
version 14
set more off
pause on

*cd "H:\CES aggregation\Consolidated aggregation"
*cd "C:\Ingo\quantification\CES aggregation"
*cd "N:\_Personal\Projects\WB projects\WTO Database collaboration\2016 Update\quantification\CES aggregation"
cd /Users/renjiege/Documents/taskdata/Worldbank/

/* 1.a Choose type of data to be aggregated */
**********************************************

local data "2016_comp"			/* 2008 2016_comp 2016_all */

/* 1.b CES aggregation parameters */
************************************

sca rho_mea_eq =  1.5
sca rho_mea_A1 = 10
sca rho_mea_A2 = 10
sca rho_mea_rs =  3
sca rho_cat    =  3
sca rho_mode_A =  3
sca rho_mode_B =  1
sca rho_mode_C = -5


/* 1.c Infile data as supplied by WTO team: */
**********************************************

if "`data'" == "2008" {
		insheet using "STRI_Score_AllCountry_ALLModes_2008_20190301_113257.csv", comma names case clear
		assert Year == 2008
		assert Score >= 0 & Score <= 1
		ren Country cname
		ren CountryISO3 country
		ren Code mcode
		merge m:1 country using av_2016		/* 70 country codes */
		keep if _merge==3
		drop _m
		drop if Subsector==30 | Subsector==152 | Subsector==10897 | Subsector==10898 | Subsector==10903		/* (Ingo) this line was not in STRI_ces_test_2008_v5.do */
	}
	else if "`data'" == "2016_all" {
		 insheet using "STRI_Score_AllCountry_ALLModes_2016_20190301_141307.csv", comma names case clear
		*insheet using "STRI_Score_AllCountry_ALLModes_2016_20181218_175253.csv", comma names case clear
		*insheet using "STRI_Score_AllCountry_ALLModes_2016_20181101_170932.csv", comma names case clear
		assert Year == 2016
		assert Score >= 0 & Score <= 1
		ren Country cname
		ren CountryISO3 country
		ren Code mcode
	}
	else if "`data'" == "2016_comp" {
		insheet using "STRI_Score_AllCountry_ALLModes_2016_20190301_141307.csv", comma names case clear
		assert Year == 2016
		assert Score >= 0 & Score <= 1
		ren Country cname
		ren CountryISO3 country
		ren Code mcode
		merge m:1 country using av_2008 	/* 103 country codes */
		keep if _merge==3
		drop _m
		drop if Subsector==30 | Subsector==152 | Subsector==10897 | Subsector==10898 | Subsector==10903		/* drop sectors not in 2008 or not comparable (Laura) */
	}
	else {
			dis "Raw data not found. Check data type."
			exit
}

/* Temporarily drop countries with incomplete information:
   To be reinstated as and when raw data are ready for publication. 
   -> as of 19/02/2019, decided to still suppress JOR. */
drop if (country=="JOR" | country=="TZA" | country=="VEN")

assert mcode != "999999999"					/* obsolete combination of measures 24, 27, 40, 44, 45) */

** Maritime freight (152 only): old measure codes 888819/888824/888827 made consistent with all other sectors directly in raw data compilation.
if ("`data'" == "2008" | "`data'" == "2016_comp") {
		assert mcode != "888819" & mcode != "888824" & mcode != "888827" if Subsector==152
	}
	else if "`data'" == "2016_all" {
		assert mcode != "19" & mcode != "24" & mcode != "27" if Subsector==152
		replace mcode = "24" if (mcode=="888824" & Subsector==152)
		replace mcode = "27" if (mcode=="888827" & Subsector==152)
		replace mcode = "19" if (mcode=="888819" & Subsector==152)

		assert mcode != "25" & mcode != "28" & mcode != "38" & mcode != "39" & mcode != "58" if Subsector==152
		replace mcode = "25" if (mcode=="888825" & Subsector==152)
		replace mcode = "28" if (mcode=="888828" & Subsector==152)
		replace mcode = "38" if (mcode=="888838" & Subsector==152)
		replace mcode = "39" if (mcode=="888839" & Subsector==152)
		replace mcode = "58" if (mcode=="888858" & Subsector==152)
}

isid country Mode Subsector mcode
keep country Mode Subsector mcode Score Answer Subcategory

/* Jocelyn: We will implement this in the R program later: */
assert Subcategory == "A1" if (mcode=="62" | mcode=="66")

replace Subcategory = "A1" if (mcode=="9991A" | mcode=="9991B" | mcode=="9991C") & Subcategory == ""
replace Subcategory = "A1" if (mcode=="9998") & Subcategory == ""
replace Subcategory = "A2" if (mcode=="9991Aa" | mcode=="9991Ba" | mcode=="9991Ca" | mcode=="9991Ab" | mcode=="9991Bb" | mcode=="9991Cb") & Subcategory == ""
replace Subcategory = "B2" if (mcode=="9993") & Subcategory == ""

assert  Subcategory != ""

tab Subcategory Mode, m
label def secnames 31 "Retailing" 30 "Wholesale" 10904 "Commercial banking" 207 "Non-life insurance" 206 "Life insurance" 136 "Reinsurance" 10903 "Internet services" ///
	10901 "Fixed-line telecom" 10902 "Mobile telecom" 10874 "Legal: advisory" 10875 "Legal: representation" 10891 "Accounting" 10892 "Auditing" 10873 "Legal: Home law" ///
	10880 "Air pass domestic" 10882 "Air pass international" 10881 "Air freight domestic" 10883 "Air freight international" 10897 "Maritime cargo-handling etc" ///
	152 "Maritime: Freight" 10898 "Maritime intermed auxiliary" 174 "Road" 169 "Rail", replace
label val Subsector secnames


/*	Remove code 38 if answer to 24 is not 100 (Laura) */ 
tempfile mcode38

preserve
keep if mcode=="24" | mcode=="38"
reshape wide Answer Score, i(country Mode Subsector Subcategory) j(mcode) string
drop if Answer24!="100"	& Answer38=="yes"
reshape long
drop if Score==. | mcode=="24"
save `mcode38', replace
restore

drop if mcode=="38" 
append using `mcode38'
sort country Mode Subsector

/*
foreach x in M1 M3 M4 {
	tab mcode Subcategory if Mode=="`x'", m
} */

* drop if Score == 0						/* unlike OECD!  Not innocuous because number of measures/area affect the set of weights */


/* 2. Identify and save closed subsector-modes for their capping scores */
**************************************************************************

/* Joscelyn (email 28/09/2018): codes that can carry a complete closure of a sector: */
tab mcode Mode if (mcode=="12" | mcode=="19" | mcode=="1009" | mcode=="9991A" | mcode=="9991B" | mcode=="9991C"), m
tab mcode Mode if (mcode=="12" | mcode=="19" | mcode=="1009" | mcode=="9991A" | mcode=="9991B" | mcode=="9991C") & Score==1, m

/* Joscelyn: M3 sector closure to be determined SOLELY on basis of #19 because of manual adjustments for some OECD countries*/

tempfile set1 set2

/* 2.1. Financial sectors: */
* "Commercial banking" "Life insurance" "Non-life insurance" "Reinsurance and retrocession"
preserve
keep if (Subsector==10904 | Subsector==206 | Subsector==207 | Subsector==136)
keep if (mcode=="12" | mcode=="19" | mcode=="39" | mcode=="25" | mcode=="40" | mcode=="9991C" | mcode=="1009")
reshape wide Answer Score, i(country Mode Subsector) j(mcode) string
	assert Answer19=="yes" if (Answer39=="no" & Answer25=="no")
	assert (Answer39=="no"|Answer39=="") & (Answer25=="no"|Answer25=="") if Answer19=="yes"
if "`data'" == "2008" {
		gen score_ces = 1 if (Answer12=="yes" | Answer19=="yes" | Score1009==1)   /* measure 9991C not present in 2008 data */
	}
	else {
		gen score_ces = 1 if (Answer12=="yes" | Answer19=="yes" | Score9991C==1 | Score1009==1) 
}
keep if score_ces==1
	dis "Financial sectors closed: "
	tab Subsector Mode if score_ces==1
keep country Mode Subsector score_ces
save `set1', replace
restore

/* 2.2. Professional sectors: */
* "Accounting services" "Auditing services" "Legal services: Home country law and/or third country law (advisory/representation)"
* "Legal services: Host country advisory services" "Legal services: Host country representation services"
preserve
keep if (Subsector==10891 | Subsector==10892 | Subsector==10873 | Subsector==10874 | Subsector==10875)
keep if (mcode=="12" | mcode=="19" | mcode=="39" | mcode=="25" | mcode=="44" | mcode=="45" | mcode=="9991A")
reshape wide Answer Score, i(country Mode Subsector) j(mcode) string
*	assert Answer19=="yes" if (Answer39=="no" & Answer25=="no" & Answer44=="no")
*	assert (Answer39=="no"|Answer39=="") & (Answer25=="no"|Answer25=="") & (Answer44=="no"|Answer44=="") if Answer19=="yes"
*	tab Answer39 Answer25, m
gen score_ces = 1 if (Answer12=="yes" | Answer19=="yes" | Score9991A==1)
keep if score_ces==1
	dis "Professional sectors closed: "
	tab Subsector Mode if score_ces==1
keep country Mode Subsector score_ces
save `set2', replace
restore

/* 2.3. All other sectors: */
preserve
keep if !(Subsector==10904 | Subsector==206 | Subsector==207 | Subsector==136 | Subsector==10891 | Subsector==10892 | Subsector==10873 | Subsector==10874 | Subsector==10875)
tab mcode Mode if Score==1, m
assert Subcategory == "A1" if Score==1
keep if Score==1
gen score_ces = Score
	dis "All other sectors closed: "
	tab Subsector Mode if score_ces==1
	*list country Subsector Mode if Score==1, noobs sepby(country) abbr(10)
keep country Mode Subsector score_ces
append using `set1' `set2'
save tmp_closed_subsecmodes_`data', replace
restore


/* 3.     First nest: CES indices over measures, within category groups: */
***************************************************************************

* eliminate closed subsectors from aggregation so as to not confound distributional histograms at each step:
merge m:1 country Subsector Mode using tmp_closed_subsecmodes_`data', assert(1 3) keepusing(score_ces)
keep if _m==1
drop _merge score_ces


/* 3.1    "Form of entry and ownership group" of A1 measures */
tempfile synthA1_1 synthA1_2 synthA1_3

/* 3.1.1  All sectors except Fin + Prof: */
preserve
keep if !(Subsector==10904 | Subsector==206 | Subsector==207 | Subsector==136 | Subsector==10891 | Subsector==10892 | Subsector==10873 | Subsector==10874 | Subsector==10875)
keep if (mcode=="25" | mcode=="39" | mcode=="24" | mcode=="27")
reshape wide Answer Score, i(country Mode Subsector) j(mcode) string
*	assert Answer39!="" & Answer25!=""	 		/* not missing */
*	list country Mode Subsector *24 *39 if Answer24 == "0" & Answer39 == "yes"
*	list country Mode Subsector *27 *25 if Answer27 == "0" & Answer25 == "yes"
	list if Answer24 == "0" & Answer39 == "yes"
	list if Answer27 == "0" & Answer25 == "yes"
replace Score24 = 0.5 if Answer39=="no"			/* No Greenfield */
replace Score27 = 0.5 if Answer25=="no"			/* No M&A */
keep country Mode Subsector Subcategory Score24 Score27
reshape long Score, i(country Mode Subsector) j(mcode)
assert (mcode==24 | mcode==27)

gen score_ces = Score^(rho_mea_eq)
collapse (sum) score_ces , by(country Mode Subsector Subcategory)		/* carry Subcategory along for later re-merge */
gen Score = (score_ces)^(1/(rho_mea_eq))		/* variables Score, mcode dropped in collapse */
drop score_ces
gen mcode = "7771"								/* CHECK that 7771 is a free synthetic code */
assert Subcategory == "A1"
save `synthA1_1', replace
restore

/* 3.1.2  Financial sectors: */
preserve
keep if (Subsector==10904 | Subsector==206 | Subsector==207 | Subsector==136)
keep if (mcode=="25" | mcode=="39" | mcode=="24" | mcode=="27" | mcode=="40")
reshape wide Answer Score, i(country Mode Subsector) j(mcode) string
*	assert Answer39!="" & Answer25!=""	 		/* not missing */
*	list country Mode Subsector *24 *39 if Answer24 == "0" & Answer39 == "yes"
*	list country Mode Subsector *27 *25 if Answer27 == "0" & Answer25 == "yes"
	list if Answer24 == "0" & Answer39 == "yes"
	list if Answer27 == "0" & Answer25 == "yes"
replace Score24 = 0.5 if Answer39=="no"			/* No Greenfield */
replace Score27 = 0.5 if Answer25=="no"			/* No M&A */
gen Score = ((Score24^(rho_mea_eq)+Score27^(rho_mea_eq))^(1/(rho_mea_eq))) + Score40
gen mcode = "7771"								/* CHECK that 7771 is a free synthetic code */
assert Subcategory == "A1"
keep country Mode Subsector Subcategory Score mcode
save `synthA1_2', replace
restore

/* 3.1.3  Professional sectors: */
preserve
keep if (Subsector==10891 | Subsector==10892 | Subsector==10873 | Subsector==10874 | Subsector==10875)
keep if (mcode=="25" | mcode=="39" | mcode=="24" | mcode=="27" | mcode=="44" | mcode=="45")
reshape wide Answer Score, i(country Mode Subsector) j(mcode) string
*	assert Answer39!="" & Answer25!=""	 		/* not missing */
*	list country Mode Subsector *24 *39 if Answer24 == "0" & Answer39 == "yes"
*	list country Mode Subsector *27 *25 if Answer27 == "0" & Answer25 == "yes"
	list if Answer24 == "0" & Answer39 == "yes"
	list if Answer27 == "0" & Answer25 == "yes"
replace Score24 = 0.25 if Answer39=="no"			/* No Greenfield */
replace Score27 = 0.25 if Answer25=="no"			/* No M&A */
gen Score = ((Score24^(rho_mea_eq)+Score27^(rho_mea_eq))^(1/(rho_mea_eq))) + Score44 + Score45  /* same for all 3 data types (Ingo) */
	* (((0.5)^1.5) + ((0.375)^1.5) + ((0.375)^1.5))^(1/1.5) = 0.87096516  But then the entire schedule of scores for equity brackets needs to be adjusted accordingly
	* 0.8709 + 0.125 = .9959
gen mcode = "7771"								/* CHECK that 7771 is a free synthetic code */
assert Subcategory == "A1"
keep country Mode Subsector Subcategory Score mcode
save `synthA1_3', replace
restore

/* replace constituent measures 24/27/40/44/45 with 1 synthetic code */
assert mcode != "7771"							/* line 72 above */
drop if (mcode=="19" | mcode=="24" | mcode=="27" | mcode=="39" | mcode=="25" | mcode=="40" | mcode=="44" | mcode=="45")
	/* Avoid double-counting: */
	drop if (mcode=="136" | mcode=="137" | mcode=="139")				/* SHOULD NOT BE THERE ANYWAY: IN 9991X */
	drop if (mcode=="1020" | mcode=="1021" | mcode=="1022")				/* SHOULD NOT BE THERE ANYWAY: IN 9998 */
append using `synthA1_1' `synthA1_2' `synthA1_3'
isid country Subsector Mode mcode

sum Score if mcode=="7771", det
histogram Score if mcode=="7771", freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 1200)) ylab(0(250)1000, format(%4.0f)) subti("Step 1: code 7771" "(Entry and Ownership)") name(aggr_step1, replace)
*pause


/* 3.2  Aggregate A1 measures on "ownership and control" */
tempfile set2 set3

preserve
keep if Subcategory=="A1"						/* 7771/62/66/38 */
	tab Subsector mcode, m
	*pause
gen score_ces = Score^(rho_mea_A1)
collapse (sum) score_ces (max) score_max_meas=Score, by(country Subsector Mode)		/* zero scores within categories do not affect the CES aggregate score AS LONG AS ces_mea >= 0! */
replace score_ces = (score_ces)^(1/(rho_mea_A1))
gen byte area = 1								/* first set of categories */
save `set2', replace

histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 1200)) ylab(0(250)1000, format(%4.0f)) subti("Step 2: Scores for A1" "(Ownership and control)") name(aggr_step2, replace)
histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 1200)) ylab(0(250)1000, format(%4.0f)) subti("Nest 1: Ownership and Control") name(aggr_Fig4_1, replace) aspectr(0.75)
*pause
restore

/* 3.3  Aggregate A2 measures on "quantitative limitations" */
preserve
keep if (Subcategory=="A2" | Subcategory=="A3" | Subcategory=="A4")	/* mcodes tba */
	tab Subsector mcode, m
	*pause
gen score_ces = Score^(rho_mea_A2)
collapse (sum) score_ces (max) score_max_meas=Score, by(country Subsector Mode)		/* zero scores within categories do not affect the CES aggregate score AS LONG AS ces_mea >= 0! */
replace score_ces = (score_ces)^(1/(rho_mea_A2))
gen byte area = 2			/* second set of categories */
save `set3', replace

histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 1500)) ylab(0(500)1500, format(%4.0f)) subti("Step 3: Scores for A2-A4" "(Quantitative limits)") name(aggr_step3, replace)
histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 1200)) ylab(0(250)1000, format(%4.0f)) subti("Nest 2: Quantitative Limits") name(aggr_Fig4_2, replace) aspectr(0.75)
*pause
restore

/* 3.4  Aggregate categories B-E on "operations and regulatory recourse": */
keep if !(Subcategory=="A1" | Subcategory=="A2" | Subcategory=="A3" | Subcategory=="A4")
	tab Subcategory, m
	*pause
gen score_ces = Score^(rho_mea_rs)
collapse (sum) score_ces (max) score_max_meas=Score, by(country Subsector Mode)		/* zero scores within categories do not affect the CES aggregate score AS LONG AS ces_mea >= 0! */
replace score_ces = (score_ces)^(1/(rho_mea_rs))
gen byte area = 3			/* third set of categories */

histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 1500)) ylab(0(500)1500, format(%4.0f)) subti("Step 4: Scores for B/C/D/E" "(Operations and reg recourse)") name(aggr_step4, replace)
histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 1200)) ylab(0(250)1000, format(%4.0f)) subti("Nest 3: Operations/Reg Recourse") name(aggr_Fig4_3, replace) aspectr(0.75)
*pause

append using `set2' `set3'
isid country Subsector Mode area
	*sort country Subsector Mode area
	*format score* %4.1f
	*list country Subsector Mode area score* if country=="ARG", sepby(Subsector) noobs
	

/* 4.  Second nest: CES indices over category areas, within mode: */
***************************************************************************
	
replace score_ces = score_ces^(rho_cat)
collapse (sum) score_ces (max) score_max_cat=score_max_meas, by(country Subsector Mode)	/* over areas 1-3 */
replace score_ces = (score_ces)^(1/(rho_cat))
	*sort country Subsector Mode
	*format score* %4.1f
	*list country Subsector Mode score* if country=="ARG", sepby(Subsector) noobs

histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 700)) ylab(0(200)600, format(%3.0f)) subti("Step 5: Across categories" "(A1 - E)") name(aggr_step5, replace)
*pause

/* Bunching around 0.75, most of which originates from ~500 instances with quantitative limits (A2):
	368 cases in (.70, .75),
	306 cases in (.75, .80) interval */

* Reminder: do ANOVA -oneway score_ces country-

/* Add scores of closed subsector-modes: */
append using tmp_closed_subsecmodes_`data'

sum score_ces
histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 700)) ylab(0(200)600, format(%3.0f)) subti("Step 6: Adding closed sec/modes" "(Total: `r(N)' obs)") name(aggr_step6, replace)
histogram score_ces, freq width(.025) start(0) graphr(col(white)) plotr(col(white)) xti("") xsc(r(0 1)) xlab(0(.25)1, format(%3.2f)) ///
	ysc(r(0 1200)) ylab(0(250)1000, format(%3.0f)) subti("Nest 4: Overall Scores") name(aggr_Fig4_4, replace) aspectr(0.75)

gr combine aggr_step1 aggr_step2 aggr_step3 aggr_step4 aggr_step5 aggr_step6 , rows(3) cols(2) xcomm ti("CES scores by Stage of Aggregation") iscale(*.8) graphr(color(white)) plotr(color(white))
pause
*gr export .\graphs\aggr_histograms_all.wmf, replace fontface("Times New Roman")

/* Restrictiveness by Principal Stage of Aggregation: */
gr combine aggr_Fig4_1 aggr_Fig4_2 aggr_Fig4_3 aggr_Fig4_4, rows(2) cols(2) xcomm iscale(*.8) graphr(color(white)) plotr(color(white))
pause
gr export .\graphs\aggr_histograms_Fig4_`data'.wmf, replace fontface("Times New Roman")
gr drop _all

count
assert score_ces <= 1

replace score_ces = score_ces*100
format score_ces %5.2f


/*	5. Get WDI country charactistics (GDP/capita) for graphs: 
	(NOTE: same source dataset as in "an_comparison_wbwto_scores_2008-16.do" (l.88 ff), which saves "tmp_ctryvars0816.dta") */
***************************************************************************

/*  5.1 WDI country characteristics: */
/*
preserve
use "N:\_Personal\Projects\Gravity\ITC-Trade-Production_Database\ITPD July04 2018\WDI_ctry_vars", clear
isid exporter_iso3 year
ren exporter_iso3 country
replace country = "CHT" if country == "TWN"
keep if year==2008 | year==2016
keep   country year GDP_cons_PPP GDP_pc_cons_PPP population
qui ds country year, not
* local vlist "`r(varlist)'"
reshape wide `r(varlist)', i(country) j(year)
save tmp_WDI_2008-16, replace
restore
*/
if ("`data'" == "2008") {
		local keeplist "GDP_pc_cons_PPP2008 GDP_cons_PPP2008 population2008"
	}
	else if ("`data'" == "2016_all" | "`data'" == "2016_comp") {
		local keeplist "GDP_pc_cons_PPP2016 GDP_cons_PPP2016 population2016"
}
merge m:1 country using tmp_WDI_2008-16, keepusing(`keeplist')
if ("`data'" == "2008" | "`data'" == "2016_comp") {
		assert _m==2 | _m==3
	}
	else if "`data'" == "2016_all" {
		assert country=="CHT" if _m==1											/* neither CHT nor TWN in WDI */
		replace GDP_pc_cons_PPP2016 = 48128         if country=="CHT" 			/* approx number only */
		replace GDP_cons_PPP2016    = 1132900000000 if country=="CHT" 			/* 1,132.9 bn USD PPP */
		replace population2016      = 23539816      if country=="CHT" 			/* 23.5m */
}
drop if _m==2
drop _m
gen lngdppc_`data' = ln(GDP_pc_cons_PPP)
gen lngdp_`data'   = ln(GDP_cons_PPP)
gen lnpop_`data'   = ln(population)
drop `keeplist'

/*  5.2 Append WALI Scores for air transport international, mode 1 (Laura) */
tempfile ctrychar
preserve
keep country lngdppc_ lngdp_ lnpop_									/* retain country characteristic for inclusion in WALI file (next step) */
collapse (mean) ln*, by(country)
save `ctrychar', replace
restore

/* GDP vars from above have to be added otherwise -append- leads to missing values for lngdppc_`data' (Ingo) */
tempfile wali
preserve
use WALI_2012_rescaled, clear										/* 70 countries (2016 coverage) + 2 subsectors: 140 obs.  Without any legacy vars such as lngdppc! */
merge m:1 country using `ctrychar', assert(1 3)						/* for 2008 + comparable: WALI has extra 15 countries hence _m==1 */
keep if _m==3
drop _m
save `wali', replace
restore

if "`data'" == "2008" {
		append using `wali'											/* modified to include lngdppc2008 etc from above (Ingo) */
		drop if country=="BEL" & Subsector==10883
		drop if country=="CZE" & Subsector==10883
	}
	else if "`data'" == "2016_comp" {
		append using `wali'											/* modified to include lngdppc2016 etc from above (Ingo) */
		drop if (country=="CHE" | country=="EST" | country=="HKG" | country=="ISL" | country=="ISR" | country=="LUX" | ///
				 country=="LVA" | country=="MMR" | country=="NOR" | country=="SGP" | country=="SVK" | country=="SVN" | country=="CHT") //delete countries not in 2008 (Laura)
}
	else if "`data'" == "2016_all" {
		append using `wali'											/* modified to include lngdppc2016 etc from above (Ingo) */
}

sort country Mode Subsector

export excel country Mode Subsector score_ces lngdppc using STRI_01Mar19_subsec-mode_`data', first(var) nolab replace
save STRI_01Mar19_subsec-mode_`data', replace

use  STRI_01Mar19_subsec-mode_`data', clear

/* Prelim graphs:
levelsof Subsector, l(seclist) clean
foreach sec of local seclist {
	foreach m in M1 M3 M4 {
		qui sum score_ces if Subsector==`sec' & Mode=="`m'"
		local mean = r(mean)
		gr twoway (scatter score_ces lngdppc if Subsector==`sec' & Mode=="`m'" & !(country=="USA"|country=="CHN"|country=="IND"),  msize(*.7) mcol(gs5) mlabc(gs5) mlab(country) mlabs(*.5)) ///
				  (scatter score_ces lngdppc if Subsector==`sec' & Mode=="`m'" &  (country=="USA"|country=="CHN"|country=="IND"),  msize(*.7) mcol(red) mlabc(red) mlab(country) mlabs(*.5) mlabpos(1)) ///
				  (lfit    score_ces lngdppc if Subsector==`sec' & Mode=="`m'", lp(dash) lc(red) lw(medthin)), ///
			subti("Sector: `:label secnames `sec'', Mode: `m'") ///
			yti("STRI Score (CES aggr)") legend(off) xti("Log GDP/capita 2016") ///
			ysc(r(0 100)) ylab(0(20)100, format(%3.0f)) xsc(r(7.8 11.5)) xlab(8(1)11) ///
			note(`"Mean STRI in this subsector-mode = `=round(r(mean),.1)'"' ///
			"Number of countries: `r(N)'") ///
			graphr(color(white)) plotr(color(white)) name(ces_`sec'_`m', replace)
	}
	gr combine ces_`sec'_M1 ces_`sec'_M3 ces_`sec'_M4 , rows(2) cols(2) hole(2) ycomm xcomm subti("Sector `:label secnames `sec'': CES scores") iscale(*.8) graphr(color(white)) plotr(color(white)) 
	gr export .\graphs\ces_secmode_`sec'_`data'.wmf, replace fontface("Times New Roman")
*	pause
}
gr drop _all
 */

/* 6.  Third nest: CES indices over modes, within subsector: */
***************************************************************************
use STRI_01Mar19_subsec-mode_`data', clear

gen w_mode = .
/*  For sectors not in 2008, no replacement but that's inconsequential
	For 2008-16 comparable: (Subsector==30 | Subsector==152 | Subsector==10897 | Subsector==10898 | Subsector==10903) */
	
if ("`data'" == "2008" | "`data'" == "2016_comp") {
		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==30 | Subsector==31))			/* 30 does not exist in 2008 (Ingo) */
		replace w_mode = 1.00 if (Mode=="M3" & (Subsector==30 | Subsector==31))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==30 | Subsector==31))

		replace w_mode = 0.11 if (Mode=="M1" & (Subsector==206 | Subsector==207))
		replace w_mode = 0.89 if (Mode=="M3" & (Subsector==206 | Subsector==207))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==206 | Subsector==207))

		replace w_mode = 0.17 if (Mode=="M1" & (Subsector==10904))
		replace w_mode = 0.83 if (Mode=="M3" & (Subsector==10904))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==10904))

		replace w_mode = 0.78 if (Mode=="M1" & (Subsector==136))
		replace w_mode = 0.22 if (Mode=="M3" & (Subsector==136))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==136))

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10901 | Subsector==10902 | Subsector==10903))	/* 10903 does not exist in 2008 (Ingo) */
		replace w_mode = 1.00 if (Mode=="M3" & (Subsector==10901 | Subsector==10902 | Subsector==10903))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==10901 | Subsector==10902 | Subsector==10903))

		replace w_mode = 0.20 if (Mode=="M1" & (Subsector==10873 | Subsector==10891 | Subsector==10892))
		replace w_mode = 0.40 if (Mode=="M3" & (Subsector==10873 | Subsector==10891 | Subsector==10892))
		replace w_mode = 0.40 if (Mode=="M4" & (Subsector==10873 | Subsector==10891 | Subsector==10892))

		/* No M1 for legal: advisory and legal: representation: */
		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10874 | Subsector==10875))
		replace w_mode = 0.50 if (Mode=="M3" & (Subsector==10874 | Subsector==10875))
		replace w_mode = 0.50 if (Mode=="M4" & (Subsector==10874 | Subsector==10875))

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10880 | Subsector==10881))
		replace w_mode = 1.00 if (Mode=="M3" & (Subsector==10880 | Subsector==10881))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==10880 | Subsector==10881))
		/* Changed weights to 0 for all modes (Laura). Overwrite M1 weight=0 for city economies without domestic air transport: */
		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10880 | Subsector==10881) & (country=="HKG" | country=="SGP"))
		replace w_mode = 0.00 if (Mode=="M3" & (Subsector==10880 | Subsector==10881) & (country=="HKG" | country=="SGP"))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==10880 | Subsector==10881) & (country=="HKG" | country=="SGP")) 

		replace w_mode = 0.625 if (Mode=="M1" & (Subsector==10882))
		replace w_mode = 0.375 if (Mode=="M3" & (Subsector==10882))
		replace w_mode = 0.00  if (Mode=="M4" & (Subsector==10882))

		replace w_mode = 0.625 if (Mode=="M1" & (Subsector==10883))
		replace w_mode = 0.375 if (Mode=="M3" & (Subsector==10883))
		replace w_mode = 0.00  if (Mode=="M4" & (Subsector==10883))

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10897))						/* 10897 does not exist in 2008 (Ingo) */
		replace w_mode = 1.00 if (Mode=="M3" & (Subsector==10897))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==10897))

		replace w_mode = 0.75 if (Mode=="M1" & (Subsector==152))						/* 152 does not exist in 2008 (Ingo) */
		replace w_mode = 0.25 if (Mode=="M3" & (Subsector==152))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==152))

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10898 | Subsector==169))		/* 10898 does not exist in 2008 (Ingo) */
		replace w_mode = 1.00 if (Mode=="M3" & (Subsector==10898 | Subsector==169))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==10898 | Subsector==169))
		
		/* Overwrite M1 weight=0 for insular countries without internat rail connectivity: */
		replace w_mode = 0.00 if (Mode=="M1" & Subsector==169 & (country=="IDN"|country=="CHT"|country=="AUS"|country=="NZL"|country=="JPN"))
		replace w_mode = 1.00 if (Mode=="M3" & Subsector==169 & (country=="IDN"|country=="CHT"|country=="AUS"|country=="NZL"|country=="JPN"))
		replace w_mode = 0.00 if (Mode=="M4" & Subsector==169 & (country=="IDN"|country=="CHT"|country=="AUS"|country=="NZL"|country=="JPN")) 

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==174))
		replace w_mode = 1.00 if (Mode=="M3" & (Subsector==174))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==174))
	}
	else if "`data'" == "2016_all" {
		replace w_mode = 0.20 if (Mode=="M1" & (Subsector==30 | Subsector==31))
		replace w_mode = 0.70 if (Mode=="M3" & (Subsector==30 | Subsector==31))
		replace w_mode = 0.10 if (Mode=="M4" & (Subsector==30 | Subsector==31))

		replace w_mode = 0.10 if (Mode=="M1" & (Subsector==206 | Subsector==207))
		replace w_mode = 0.80 if (Mode=="M3" & (Subsector==206 | Subsector==207))
		replace w_mode = 0.10 if (Mode=="M4" & (Subsector==206 | Subsector==207))

		replace w_mode = 0.15 if (Mode=="M1" & (Subsector==10904))
		replace w_mode = 0.75 if (Mode=="M3" & (Subsector==10904))
		replace w_mode = 0.10 if (Mode=="M4" & (Subsector==10904))

		replace w_mode = 0.70 if (Mode=="M1" & (Subsector==136))
		replace w_mode = 0.20 if (Mode=="M3" & (Subsector==136))
		replace w_mode = 0.10 if (Mode=="M4" & (Subsector==136))

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10901 | Subsector==10902 | Subsector==10903))
		replace w_mode = 0.90 if (Mode=="M3" & (Subsector==10901 | Subsector==10902 | Subsector==10903))
		replace w_mode = 0.10 if (Mode=="M4" & (Subsector==10901 | Subsector==10902 | Subsector==10903))

		replace w_mode = 0.20 if (Mode=="M1" & (Subsector==10873 | Subsector==10891 | Subsector==10892))
		replace w_mode = 0.40 if (Mode=="M3" & (Subsector==10873 | Subsector==10891 | Subsector==10892))
		replace w_mode = 0.40 if (Mode=="M4" & (Subsector==10873 | Subsector==10891 | Subsector==10892))

		/* No M1 for legal: advisory and legal: representation: */
		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10874 | Subsector==10875))
		replace w_mode = 0.50 if (Mode=="M3" & (Subsector==10874 | Subsector==10875))
		replace w_mode = 0.50 if (Mode=="M4" & (Subsector==10874 | Subsector==10875))

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10880 | Subsector==10881))
		replace w_mode = 0.80 if (Mode=="M3" & (Subsector==10880 | Subsector==10881))
		replace w_mode = 0.20 if (Mode=="M4" & (Subsector==10880 | Subsector==10881))
		
		/* Overwrite all modal weights=0 for city economies without domestic air transport: */
		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10880 | Subsector==10881) & (country=="HKG" | country=="SGP"))
		replace w_mode = 0.00 if (Mode=="M3" & (Subsector==10880 | Subsector==10881) & (country=="HKG" | country=="SGP"))
		replace w_mode = 0.00 if (Mode=="M4" & (Subsector==10880 | Subsector==10881) & (country=="HKG" | country=="SGP")) 

		replace w_mode = 0.50 if (Mode=="M1" & (Subsector==10882))
		replace w_mode = 0.30 if (Mode=="M3" & (Subsector==10882))
		replace w_mode = 0.20 if (Mode=="M4" & (Subsector==10882))

		replace w_mode = 0.50 if (Mode=="M1" & (Subsector==10883))	
		replace w_mode = 0.30 if (Mode=="M3" & (Subsector==10883))
		replace w_mode = 0.20 if (Mode=="M4" & (Subsector==10883))

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==10897))
		replace w_mode = 0.90 if (Mode=="M3" & (Subsector==10897))
		replace w_mode = 0.10 if (Mode=="M4" & (Subsector==10897))

		replace w_mode = 0.60 if (Mode=="M1" & (Subsector==152))
		replace w_mode = 0.20 if (Mode=="M3" & (Subsector==152))
		replace w_mode = 0.20 if (Mode=="M4" & (Subsector==152))

		replace w_mode = 0.20 if (Mode=="M1" & (Subsector==10898 | Subsector==169))
		replace w_mode = 0.70 if (Mode=="M3" & (Subsector==10898 | Subsector==169))
		replace w_mode = 0.10 if (Mode=="M4" & (Subsector==10898 | Subsector==169))

		/* Overwrite M1 weight=0 for insular countries without internat rail connectivity: */
		replace w_mode = 0.00 if (Mode=="M1" & Subsector==169 & (country=="IDN"|country=="CHT"|country=="AUS"|country=="NZL"|country=="JPN"|country=="LKA"|country=="PHL"))
		replace w_mode = 0.88 if (Mode=="M3" & Subsector==169 & (country=="IDN"|country=="CHT"|country=="AUS"|country=="NZL"|country=="JPN"|country=="LKA"|country=="PHL"))
		replace w_mode = 0.12 if (Mode=="M4" & Subsector==169 & (country=="IDN"|country=="CHT"|country=="AUS"|country=="NZL"|country=="JPN"|country=="LKA"|country=="PHL")) 

		replace w_mode = 0.00 if (Mode=="M1" & (Subsector==174))
		replace w_mode = 0.75 if (Mode=="M3" & (Subsector==174))
		replace w_mode = 0.25 if (Mode=="M4" & (Subsector==174))
}

assert w_mode != . 
bysort country Subsector: egen wsum = total(w_mode)
assert wsum == 1
drop wsum

/* Cobb-Doublas aggregator with modal weights: 
  ==> does not work because of "essentiality of inputs":
	  as soon as one input is zero, all output is zero. */
preserve
tempfile tmp_modal_CB
drop lngdp* lnpop score_max
reshape wide score_ces w_mode, i(country Subsector) j(Mode) string
gen score_ces_D = (score_cesM1^(w_modeM1))*(score_cesM3^(w_modeM3))*(score_cesM4^(w_modeM4))
keep country Subsector score_ces_D
save `tmp_modal_CB', replace
restore

/* pro memoria: A=3; B=1; C=-5*/
gen score_ces_A = (w_mode*score_ces^(rho_mode_A))
gen score_ces_B = (w_mode*score_ces^(rho_mode_B))
gen score_ces_C = (w_mode*score_ces^(rho_mode_C))
collapse (sum) score_ces_? (max) score_max=score_max_cat (mean) lngdppc, by(country Subsector)  /* GDP_* population */
replace score_ces_A = (score_ces_A)^(1/(rho_mode_A))
replace score_ces_B = (score_ces_B)^(1/(rho_mode_B))
replace score_ces_C = (score_ces_C)^(1/(rho_mode_C))

merge 1:1 country Subsector using `tmp_modal_CB', assert(3)
drop _m

format score_ces* %5.1f
sum score_ces* , det

qui spearman score_ces_A score_ces_B
gr twoway (scatter score_ces_A score_ces_B , msize(*.5) mcol(gs5) mlabc(gs5) mlabs(*.5)) ///
		  (lfit    score_ces_A score_ces_B , lp(dash) lc(red) lw(medthin)) ///
		  (function y=x, range(0 100) lp(solid) lc(green) lw(medthin)), ///
ysc(r(0 100)) ylab(0(20)100, format(%3.0f)) xsc(r(0 100)) xlab(0(20)100, format(%3.0f)) ///
yti("Modal aggregation: Rho=3") xti(" " "Modal aggregation: Rho=1") legend(off) ///
note(`"Note: Correlation coefficient = `=round(r(rho),.01)' "') ///
aspectr(1) graphr(color(white)) plotr(color(white)) 
gr export .\graphs\ces_modal_robust_AB_`data'.wmf, replace fontface("Times New Roman")

qui spearman score_ces_D score_ces_B
gr twoway (scatter score_ces_D score_ces_B , msize(*.5) mcol(gs5) mlabc(gs5) mlabs(*.5)) ///
		  (lfit    score_ces_D score_ces_B , lp(dash) lc(red) lw(medthin)) ///
		  (function y=x, range(0 100) lp(solid) lc(green) lw(medthin)), ///
ysc(r(0 100)) ylab(0(20)100, format(%3.0f)) xsc(r(0 100)) xlab(0(20)100, format(%3.0f)) ///
yti("Modal aggregation: Rho=0 (Cobb-Douglas)") xti(" " "Modal aggregation: Rho=1") legend(off) ///
note(`"Note: Correlation coefficient = `=round(r(rho),.01)' "') ///
aspectr(1) graphr(color(white)) plotr(color(white)) 
gr export .\graphs\ces_modal_robust_DB_`data'.wmf, replace fontface("Times New Roman")

qui spearman score_ces_C score_ces_B
gr twoway (scatter score_ces_C score_ces_B , msize(*.5) mcol(gs5) mlabc(gs5) mlabs(*.5)) ///
		  (lfit    score_ces_C score_ces_B , lp(dash) lc(red) lw(medthin)) ///
		  (function y=x, range(0 100) lp(solid) lc(green) lw(medthin)), ///
ysc(r(0 100)) ylab(0(20)100, format(%3.0f)) xsc(r(0 100)) xlab(0(20)100, format(%3.0f)) ///
yti("Modal aggregation: Rho=-5") xti(" " "Modal aggregation: Rho=1") legend(off) ///
note(`"Note: Correlation coefficient = `=round(r(rho),.01)' "') ///
aspectr(1) graphr(color(white)) plotr(color(white)) 
gr export .\graphs\ces_modal_robust_CB_`data'.wmf, replace fontface("Times New Roman")


levelsof Subsector, l(seclist) clean
foreach sec of local seclist {
	qui spearman score_ces_B lngdppc if Subsector==`sec'
	gr twoway (scatter score_ces_B lngdppc if Subsector==`sec' & !(country=="USA"|country=="CHN"|country=="IND"),  msize(*.7) mcol(gs5) mlabc(gs5) mlab(country) mlabs(*.5)) ///
			  (scatter score_ces_B lngdppc if Subsector==`sec' &  (country=="USA"|country=="CHN"|country=="IND"),  msize(*.7) mcol(red) mlabc(red) mlab(country) mlabs(*.5) mlabpos(1)) ///
			  (lfit    score_ces_B lngdppc if Subsector==`sec', lp(dash) lc(red) lw(medthin)), ///
	ysc(r(0 100)) ylab(0(20)100, format(%3.0f)) xsc(r(7.8 11.5)) xlab(8(1)11)  ///
	subti("Sector: `:label secnames `sec''") yti("CES index") legend(off) xti(" " "Log GDP/capita 2016") ///
	note(`"Note: Correlation coefficient = `=round(r(rho),.01)' "' ///
	"Number of countries: `r(N)'") ///
	graphr(color(white)) plotr(color(white)) 
	gr export .\graphs\ces_subsector_`sec'_`data'.wmf, replace fontface("Times New Roman")
*	pause
	qui spearman score_ces_A score_ces_B if Subsector==`sec'
	gr twoway (scatter score_ces_A score_ces_B if Subsector==`sec' & !(country=="USA"|country=="CHN"|country=="IND"),  msize(*.7) mcol(gs5) mlabc(gs5) mlab(country) mlabs(*.5)) ///
			  (scatter score_ces_A score_ces_B if Subsector==`sec' &  (country=="USA"|country=="CHN"|country=="IND"),  msize(*.7) mcol(red) mlabc(red) mlab(country) mlabs(*.5) mlabpos(1)) ///
			  (function y=x, range(0 100) lp(dash) lc(red) lw(medthin)), ///
	ysc(r(0 100)) ylab(0(20)100, format(%3.0f)) xsc(r(0 100)) xlab(0(20)100, format(%3.0f)) ///
	subti("Sector: `:label secnames `sec''") yti("CES Score(Rho = 3)") legend(off) xti(" " "CES Score (Rho = 1)") ///
	note(`"Note: Correlation coefficient = `=round(r(rho),.01)' "' ///
	"Number of countries: `r(N)'") ///
	graphr(color(white)) plotr(color(white)) aspect(1)
	gr export .\graphs\ces_subsector_comp_`sec'_`data'.wmf, replace fontface("Times New Roman")
*	pause
} 

export excel country Subsector score_ces* lngdppc using STRI_01Mar19_subsector_`data', first(var) nolab replace
save STRI_01Mar19_subsector_`data', replace


/* 7.  Fourth nest: Aggregate across subsector to country level (for coverage comparison with 2008): */
***************************************************************************
isid country Subsector

/* at the level for which there are 2013 sectoral value added weights in file "STRI_2016 sector shares.xlsx" */
gen SECTOR = .
replace SECTOR =  1 if (Subsector==30)		//wholesale
replace SECTOR =  2 if (Subsector==31) 		//retail
replace SECTOR =  3 if (Subsector==10904) 	//banking
replace SECTOR =  4 if (Subsector==136 | Subsector==206 | Subsector==207)	//insurance
replace SECTOR =  5 if (Subsector==10891 | Subsector==10892)				//accounting 
replace SECTOR =  6 if (Subsector==10873 | Subsector==10874 | Subsector==10875)	//legal
replace SECTOR =  7 if (Subsector==10901 | Subsector==10902 | Subsector==10903) //telecom
replace SECTOR =  8 if (Subsector==169) 	//rail 
replace SECTOR =  9 if (Subsector==174) 	//road
replace SECTOR = 10 if (Subsector==10880 | Subsector==10881 | Subsector==10882 | Subsector==10883) //air
replace SECTOR = 11 if (Subsector==152) 	//maritime freight
replace SECTOR = 12 if (Subsector==10897 | Subsector==10898) //maritime auxiliary
assert SECTOR !=.
label define SECTOR 1 "Wholesale" 2 "Retail" 3 "Banking" 4 "Insurance" 5 "Accounting" 6 "Legal" 7 "Telecom" 8 "Rail" 9 "Road" 10 "Air" 11 "Maritime: Freight" 12 "Maritime: Auxiliary"
label value SECTOR SECTOR

collapse (mean) score_ces_* lngdppc, by(country SECTOR)

save STRI_01Mar19_SECTOR_`data', replace

gen w_sector = .

/*  Adjust weights for sectors not in 2008:
	(Subsector==30 | Subsector==152 | Subsector==10897 | Subsector==10898 | Subsector==10903) */
if ("`data'" == "2008" | "`data'" == "2016_comp") {
		*replace w_sector = 19.8 if SECTOR==1"
		replace w_sector = 21.8 if SECTOR==2
		replace w_sector = 15.0 if SECTOR==3
		replace w_sector = 3.6  if SECTOR==4
		replace w_sector = 7.15 if SECTOR==5
		replace w_sector = 7.15 if SECTOR==6
		replace w_sector = 6.1  if SECTOR==7
		replace w_sector = 4.5  if SECTOR==8
		replace w_sector = 4.5  if SECTOR==9
		replace w_sector = 1.4  if SECTOR==10
		*replace w_sector = 1.8  if SECTOR==11
		*replace w_sector = 7.0  if SECTOR==12
}
	else if "`data'" == "2016_all" {
		replace w_sector = 19.8 if SECTOR==1
		replace w_sector = 21.8 if SECTOR==2
		replace w_sector = 15.0 if SECTOR==3
		replace w_sector = 3.6  if SECTOR==4
		replace w_sector = 7.15 if SECTOR==5
		replace w_sector = 7.15 if SECTOR==6
		replace w_sector = 6.1  if SECTOR==7
		replace w_sector = 4.5  if SECTOR==8
		replace w_sector = 4.5  if SECTOR==9
		replace w_sector = 1.4  if SECTOR==10
		replace w_sector = 1.8  if SECTOR==11
		replace w_sector = 7.0  if SECTOR==12
}
assert  w_sector != .

collapse (mean) score_ces_* [pweight=w_sector], by(country lngdppc)

save STRI_01Mar19_country_`data', replace

exit

***************************
***************************

/*
1. weights are important: without weights, score is unbound and does not take on convex combinations between (min,max) 
2. conversely, with weights zero measures do matter, and para cannot be negative because 0^r not defined for r < 0.
3. Together, weights are attractive for combining modes in case of partial substitutability, but unattractive for combining measures
   because each measure should add to restrictiveness and scores should reflect number and diversity of applied measures. 
4. What does it mean for measuring marginal restrictiveness if weights are omitted? 
*/

