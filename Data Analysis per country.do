**Windows
	global data "C:/Users/robin/Dropbox/Google Trends/Data"
	global results "C:/Users/robin/Dropbox/Google Trends/Output"
	global root "C:/Users/robin/Dropbox/Google Trends/Scripts"

	ssc inst _gwtmean
	ssc inst coefplot
**Main Analysis

*Figure 1. Google Trends of English keywords
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"
foreach var of local varlist {
		use "$data/Google-trends-`var'-data/daily_`var'_19_21_all_full.dta", clear
		drop if pandemic_duration==0 
		drop if pandemic_duration<-60
		keep if pandemic_duration!=.
		
		bysort year pandemic_duration: egen m_`var'_19_21=wtmean(d_`var'_19_21), weight(pop_size)
		
		twoway (connected m_`var'_19_21 pandemic_duration if year==2019, msize(vsmall) lcolor(gs10) mcolor(gs10)) (connected m_`var'_19_21 pandemic_duration if year==2020, msize(vsmall) /*lcolor(black) mcolor(black)*/) (connected m_`var'_19_21 pandemic_duration if year==2021, msize(vsmall) /*lcolor(black) mcolor(black)*/), ///
		xline(0, lpattern(solid) lcolor(cranberry)) legend(order(1 "2019" 2 "2020" 3 "2021")) /*ylabel(0(50)100)*/ ///
		ytitle("`var'") xlabel(-28 -14 0 14 28 42 56 70 84 98 112 126 140) xscale(range(-35 140)) ///
		saving("$results/`var'/`var'_DID.gph", replace) 	
}

graph combine "$results/OnlineDoctor/OnlineDoctor_DID.gph"  "$results/OnlineHealth/OnlineHealth_DID.gph" "$results/eHealth/eHealth_DID.gph" "$results/Telehealth/Telehealth_DID.gph" "$results/Telemedicine/Telemedicine_DID.gph" "$results/OnlineNurse/OnlineNurse_DID.gph" "$results/OnlinePharmacy/OnlinePharmacy_DID.gph" "$results/HealthApp/HealthApp_DID.gph", rows(3) cols(3) imargin(0 0 0 0 0 0 0) iscale(.6) 
graph export "$results/Tables and Figures/GoogleTrends_A4 EN.pdf", replace

*Figure 2A. Change in digital health-related searches since the start of the pandemic (DiD) 2019-2020
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"

foreach var of local varlist {
	
	use "$data/Google-trends-`var'-data/daily_`var'_19_21_all_full.dta", clear
		drop if pandemic_duration==0
		keep if pandemic_duration!=.
		keep if year!=2021
		
		replace year=year-2019
		gen pandemic_year=pandemic_period*year 
		/*TLN: values of 2019 are all 0 because they multiply by 0; hence baseline*/

		reghdfe normalised_`var'_19_21 pandemic_year pandemic_duration daily_cases_ma daily_deaths_ma [pw=pop_size], ///
		absorb(country year week day_w) vce(cluster day)
		eststo DID_`var'
		estadd local countryFE "Yes", replace
		estadd local timeFE "Yes", replace
}

coefplot (DID_OnlineDoctor, keep(pandemic_year) color(cranberry) asequation(OnlineDoctor) ciopts(lcolor(cranberry) recast(rcap)))  ///
	(DID_OnlineHealth, keep(pandemic_year) color(cranberry) asequation(OnlineHealth) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_eHealth, keep(pandemic_year)  color(cranberry) asequation(eHealth) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_Telehealth, keep(pandemic_year) color(cranberry) asequation(Telehealth) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_Telemedicine, keep(pandemic_year) color(cranberry) asequation(Telemedicine) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_OnlineNurse, keep(pandemic_year) color(cranberry) asequation(OnlineNurse) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_OnlinePharmacy, keep(pandemic_year) color(cranberry) asequation(OnlinePharmacy) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_HealthApp, keep(pandemic_year) color(cranberry) asequation(HealthApp) ciopts(lcolor(cranberry) recast(rcap))) ///
		,label asequation swapnames xline(0, lcolor(black)) recast(bar) ci(95) legend(off) xtitle("DID Estimates")
		graph export "$results/Tables and Figures/DID_Estimates 2019-2020.pdf", replace

*Figure 3B. Duration of effects of pandemic on pursue of digital health solutions (2019-2020)
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"

foreach var of local varlist {
			
		use "$data/Google-trends-`var'-data/daily_`var'_19_21_all_full.dta", clear
		keep if year!=2021
		replace year=year-2019
		gen pandemic_year=pandemic_period*year
		
		gen pandemic_week=11
		bysort country: egen m_pandemic_week=mean(pandemic_week)
		replace pandemic_week=m_pandemic_week
		drop m_pandemic_week		
		bysort country: gen weeksincepandemic=week-pandemic_week
		drop pandemic_week
		
		xi gen i.weeksincepandemic*year, noomit
		
		sort country year day
		
		reghdfe normalised_`var'_19_21 _IweeXyear_9-_IweeXyear_27 _Iweeksince* daily_cases_ma daily_deaths_ma [pw=pop_size]  ///
		, absorb(country year week day_w) vce(cluster day)
		eststo DID_event_`var'
		estadd local countryFE "Yes", replace
		estadd local timeFE "Yes", replace
		
		coefplot DID_event_`var', keep(_IweeXyear_*) recast(connected) color(cranberry) ciopts(lcolor(cranberry) ) vertical  ///
		label yline(0, lcolor(black))  ci(95) legend(off) xtitle("Weeks elapsed since the start of the pandemic") ///
		xline(7, lpattern(dash) lcolor(black)) ///
		rename(_IweeXyear_9="-6" _IweeXyear_10="-5" _IweeXyear_11="-4" _IweeXyear_12="-3" _IweeXyear_13="-2" _IweeXyear_14="-1" _IweeXyear_15="0" _IweeXyear_16="1" _IweeXyear_17="2" _IweeXyear_18="3" _IweeXyear_19="4" _IweeXyear_20="5" _IweeXyear_21="6" _IweeXyear_22="7" _IweeXyear_23="8" _IweeXyear_23="9" _IweeXyear_24="10" _IweeXyear_25="11" _IweeXyear_23="12" _IweeXyear_24="13" _IweeXyear_25="14" _IweeXyear_26="15" _IweeXyear_27="16") omitted ytitle("`var'") ///
		saving("$results/`var'/`var'_DID_Event2020-2021.gph", replace)
		
}

graph combine "$results/OnlineDoctor/OnlineDoctor_DID_Event2020-2021.gph" "$results/OnlineHealth/OnlineHealth_DID_Event2020-2021.gph" "$results/eHealth/eHealth_DID_Event2020-2021.gph" "$results/Telehealth/Telehealth_DID_Event2020-2021.gph" "$results/Telemedicine/Telemedicine_DID_Event2020-2021.gph" "$results/OnlineNurse/OnlineNurse_DID_Event2020-2021.gph" "$results/OnlinePharmacy/OnlinePharmacy_DID_Event2020-2021.gph" "$results/HealthApp/HealthApp_DID_Event2020-2021.gph", rows(3) cols(3) imargin(0 0 0 0 0 0 0) iscale(.5) 
graph export "$results/Tables and Figures/Event plot 2020-2021.pdf", replace
