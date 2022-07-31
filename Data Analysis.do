**Windows
	global data "C:/Users/robin/Dropbox/Google Trends/Data"
	global results "C:/Users/robin/Dropbox/Google Trends/Output"
	global root "C:/Users/robin/Dropbox/Google Trends/Scripts"

	ssc inst _gwtmean
	ssc inst coefplot
**Main Analysis

*Figure 1. Google Trends of keywords (DiD)
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"
foreach var of local varlist {
		use "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", clear
		drop if pandemic_duration==0 
		drop if pandemic_duration<-60
		keep if pandemic_duration!=.
		
		bysort year pandemic_duration: egen m_`var'_19_21=wtmean(d_`var'_19_21), weight(pop_size)
		
		twoway (connected w_`var'_19_21 pandemic_duration if year==2019, msize(vsmall) lcolor(gs10) mcolor(gs10)) (connected w_`var'_19_21 pandemic_duration if year==2020, msize(vsmall) /*lcolor(black) mcolor(black)*/) (connected w_`var'_19_21 pandemic_duration if year==2021, msize(vsmall) lcolor(gs10) mcolor(gs10)), ///
		xline(0, lpattern(solid) lcolor(cranberry)) legend(order(1 "2019" 2 "2020" 3 "2021")) /*ylabel(0(50)100)*/ ///
		ytitle("`var'") xlabel(-28 -14 0 14 28 42 56 70 84 98 112 126 140) xscale(range(-35 140)) ///
		saving("$results/`var'/`var'_DID.gph", replace) 	
}

graph combine "$results/OnlineDoctor/OnlineDoctor_DID.gph"  "$results/OnlineHealth/OnlineHealth_DID.gph" "$results/eHealth/eHealth_DID.gph" "$results/Telehealth/Telehealth_DID.gph" "$results/Telemedicine/Telemedicine_DID.gph" "$results/OnlineNurse/OnlineNurse_DID.gph" "$results/OnlinePharmacy/OnlinePharmacy_DID.gph" "$results/HealthApp/HealthApp_DID.gph", rows(3) cols(3) imargin(0 0 0 0 0 0 0) iscale(.6) 
graph export "$results/Tables and Figures/GoogleTrends_A4 EN.pdf", replace

*Figure 1. Google Trends weekly data (ITSA)
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"
foreach var of local varlist {
	use "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", clear
	gen dates = daily(date, "YMD")
	format %td dates

	tsset country dates, delta(7)

	twoway (tsline w_`var'_19_21, tline(08mar2020 20dec2020)), ///
		xline(0, lpattern(solid)) ///
		xtitle("") ///
		title("`var'") ///
		ytitle("") ///
		saving("$results/`var'/`var'_rawweekly.gph", replace)
}
graph combine "$results/OnlineDoctor/OnlineDoctor_rawweekly.gph"  "$results/OnlineHealth/OnlineHealth_rawweekly.gph" "$results/Telehealth/Telehealth_rawweekly.gph" "$results/Telemedicine/Telemedicine_rawweekly.gph" "$results/HealthApp/HealthApp_rawweekly.gph", rows(3) cols(2) imargin(0 0 0 0 0 0 0) iscale(.6) 
graph export "$results/Tables and Figures/GoogleTrends raw ITSA.pdf", replace

*Figure 2 + eTable 1. Change in digital health-related searches since the start of the pandemic (DiD) 2019-2020
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
		,label asequation swapnames xline(0, lcolor(black)) ci(95) legend(off) xtitle("DID Estimates")
		graph export "$results/Tables and Figures/DID_Estimates 2019-2020.pdf", replace


*Figure 3 + eTable 2. Country-specific DiD findings 2019-2020
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"

foreach var of local varlist {
	forvalues i=1/6 {
		
	use "$data/Google-trends-`var'-data/daily_`var'_19_21_all_full.dta", clear
		drop if pandemic_duration==0
		keep if pandemic_duration!=.
		keep if year!=2021
		keep if country == `i'
		
		replace year=year-2019
		gen pandemic_year=pandemic_period*year 
		/*TLN: values of 2019 are all 0 because they multiply by 0; hence baseline*/

		reghdfe normalised_`var'_19_21 pandemic_year pandemic_duration daily_cases_ma daily_deaths_ma, ///
		absorb(year week day_w) vce(cluster day)
		eststo DID_`var'_`i'
		estadd local timeFE "Yes", replace
	}
}			

forvalues i=1/6 {
	coefplot (DID_OnlineDoctor_`i', keep(pandemic_year) color(cranberry) asequation(OnlineDoctor) ciopts(lcolor(cranberry) recast(rcap)))  ///
	(DID_OnlineHealth_`i', keep(pandemic_year) color(cranberry) asequation(OnlineHealth) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_eHealth_`i', keep(pandemic_year)  color(cranberry) asequation(eHealth) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_Telehealth_`i', keep(pandemic_year) color(cranberry) asequation(Telehealth) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_Telemedicine_`i', keep(pandemic_year) color(cranberry) asequation(Telemedicine) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_OnlineNurse_`i', keep(pandemic_year) color(cranberry) asequation(OnlineNurse) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_OnlinePharmacy_`i', keep(pandemic_year) color(cranberry) asequation(OnlinePharmacy) ciopts(lcolor(cranberry) recast(rcap))) ///
	(DID_HealthApp_`i', keep(pandemic_year) color(cranberry) asequation(HealthApp) ciopts(lcolor(cranberry) recast(rcap))) ///
		,label asequation swapnames xline(0, lcolor(black)) ci(95) legend(off) xtitle("DID Estimates")
		graph export "$results/Tables and Figures/DID_Estimates_`i' 2019-2020.pdf", replace

}

		
*Figure 3. Event analysis of effects of pandemic on pursue of digital health solutions (2019-2020)
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
		
		reghdfe normalised_`var'_19_21 _IweeXyear_9-_IweeXyear_27 _Iweeksince* daily_cases_ma daily_deaths_ma [pw=pop_size], absorb(country year week day_w) vce(cluster day)
		eststo DID_event_`var'
		estadd local countryFE "Yes", replace
		estadd local timeFE "Yes", replace
		
		coefplot DID_event_`var', keep(_IweeXyear_*) recast(connected) color(cranberry) ciopts(lcolor(cranberry) ) vertical  ///
		label yline(0, lcolor(black))  ci(95) legend(off) xtitle("Weeks elapsed since the start of the pandemic") ///
		xline(7, lpattern(dash) lcolor(black)) ///
		rename(_IweeXyear_9="-6" _IweeXyear_10="-5" _IweeXyear_11="-4" _IweeXyear_12="-3" _IweeXyear_13="-2" _IweeXyear_14="-1" _IweeXyear_15="0" _IweeXyear_16="1" _IweeXyear_17="2" _IweeXyear_18="3" _IweeXyear_19="4" _IweeXyear_20="5" _IweeXyear_21="6" _IweeXyear_22="7" _IweeXyear_23="8" _IweeXyear_24="9" _IweeXyear_25="10" _IweeXyear_26="11" _IweeXyear_27="12") omitted ytitle("`var'") ///
		saving("$results/`var'/`var'_DID_Event2019-2020.gph", replace)
	}

graph combine "$results/OnlineDoctor/OnlineDoctor_DID_Event2019-2020.gph" "$results/OnlineHealth/OnlineHealth_DID_Event2019-2020.gph" "$results/eHealth/eHealth_DID_Event2019-2020.gph" "$results/Telehealth/Telehealth_DID_Event2019-2020.gph" "$results/Telemedicine/Telemedicine_DID_Event2019-2020.gph" "$results/OnlineNurse/OnlineNurse_DID_Event2019-2020.gph" "$results/OnlinePharmacy/OnlinePharmacy_DID_Event2019-2020.gph" "$results/HealthApp/HealthApp_DID_Event2019-2020.gph", rows(3) cols(3) imargin(0 0 0 0 0 0 0) iscale(.5) 
graph export "$results/Tables and Figures/Event plot 2019-2020.pdf", replace


*Supplementary Table 1. Country-specific DiD findings
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"

foreach var of local varlist {
	forvalues i=1/6 {
		
	use "$data/Google-trends-`var'-data/daily_`var'_19_21_all_full.dta", clear
		drop if pandemic_duration==0
		keep if pandemic_duration!=.
		keep if year!=2021
		keep if country == `i'
		
		replace year=year-2019
		gen pandemic_year=pandemic_period*year 
		/*TLN: values of 2019 are all 0 because they multiply by 0; hence baseline*/

		reghdfe normalised_`var'_19_21 pandemic_year pandemic_duration daily_cases_ma daily_deaths_ma, ///
		absorb(year week day_w) vce(cluster day)
		eststo DID_`var'
		estadd local timeFE "Yes", replace
	}
}	

*eFigure X. Country-specific event analysis of effects of pandemic on pursue of digital health solutions (2019-2020)
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"

foreach var of local varlist {
	forvalues i=1/6 {
		use "$data/Google-trends-`var'-data/daily_`var'_19_21_all_full.dta", clear
		keep if year!=2021
		keep if country==`i'
		replace year=year-2019
		gen pandemic_year=pandemic_period*year
		
		gen pandemic_week=11
		bysort country: egen m_pandemic_week=mean(pandemic_week)
		replace pandemic_week=m_pandemic_week
		drop m_pandemic_week		
		gen weeksincepandemic=week-pandemic_week
		drop pandemic_week
		
		xi gen i.weeksincepandemic*year, noomit
		
		sort year day
		
		reghdfe normalised_`var'_19_21 _IweeXyear_9-_IweeXyear_27 _Iweeksince* daily_cases_ma daily_deaths_ma  ///
		, absorb(year week day_w) vce(cluster day)
		eststo DID_event_`var'
		estadd local timeFE "Yes", replace
		
		coefplot DID_event_`var', keep(_IweeXyear_*) recast(connected) color(cranberry) ciopts(lcolor(cranberry) ) vertical  ///
		label yline(0, lcolor(black))  ci(95) legend(off) xtitle("Weeks elapsed since the start of the pandemic") ///
		xline(7, lpattern(dash) lcolor(black)) ///
		rename(_IweeXyear_9="-6" _IweeXyear_10="-5" _IweeXyear_11="-4" _IweeXyear_12="-3" _IweeXyear_13="-2" _IweeXyear_14="-1" _IweeXyear_15="0" _IweeXyear_16="1" _IweeXyear_17="2" _IweeXyear_18="3" _IweeXyear_19="4" _IweeXyear_20="5" _IweeXyear_21="6" _IweeXyear_22="7" _IweeXyear_23="8" _IweeXyear_23="9" _IweeXyear_24="10" _IweeXyear_25="11" _IweeXyear_23="12" _IweeXyear_24="13" _IweeXyear_25="14" _IweeXyear_26="15" _IweeXyear_27="16") omitted ytitle("`var'") ///
		saving("$results/`var'/`var'_DID_Event2019-2020_`i'.gph", replace)
	}
}

forvalues i=1/6 {
graph combine "$results/OnlineDoctor/OnlineDoctor_DID_Event2019-2020_`i'.gph" "$results/OnlineHealth/OnlineHealth_DID_Event2019-2020_`i'.gph" "$results/eHealth/eHealth_DID_Event2019-2020_`i'.gph" "$results/Telehealth/Telehealth_DID_Event2019-2020_`i'.gph" "$results/Telemedicine/Telemedicine_DID_Event2019-2020_`i'.gph" "$results/OnlineNurse/OnlineNurse_DID_Event2019-2020_`i'.gph" "$results/OnlinePharmacy/OnlinePharmacy_DID_Event2019-2020_`i'.gph" "$results/HealthApp/HealthApp_DID_Event2019-2020_`i'.gph", rows(3) cols(3) imargin(0 0 0 0 0 0 0) iscale(.5) 
graph export "$results/Tables and Figures/Event plot 2019-2020_`i'.pdf", replace
} 


*Interrupted time series analysis

**OnlineDoctor
use "$data/Google-trends-OnlineDoctor-data/weekly_OnlineDoctor_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_OnlineDoctor_19_21 daily_cases_ma daily_deaths_ma, single treat(1) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_1.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21 daily_cases_ma daily_deaths_ma, single treat(2) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_2.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21 daily_cases_ma daily_deaths_ma, single treat(3) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_3.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21 daily_cases_ma daily_deaths_ma, single treat(4) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_4.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21 daily_cases_ma daily_deaths_ma, single treat(5) trperiod(08mar2020; 20dec2020) lag(2) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_5.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21 daily_cases_ma daily_deaths_ma, single treat(6) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_6.gph", replace
actest, lags(6)

**OnlineHealth
use "$data/Google-trends-OnlineHealth-data/weekly_OnlineHealth_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_OnlineHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(1) trperiod(08mar2020; 20dec2020) lag(2) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_1.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(2) trperiod(08mar2020; 20dec2020) lag(2) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_2.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(3) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_3.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(4) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_4.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(5) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_5.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(6) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_6.gph", replace
actest, lags(6)

**eHealth
use "$data/Google-trends-eHealth-data/weekly_eHealth_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_eHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(1) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_1.gph", replace
actest, lags(6)

itsa w_eHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(2) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_2.gph", replace
actest, lags(6)

itsa w_eHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(3) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_3.gph", replace
actest, lags(6)

itsa w_eHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(4) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_4.gph", replace
actest, lags(6)

itsa w_eHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(5) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_5.gph", replace
actest, lags(6)

itsa w_eHealth_19_21 daily_cases_ma daily_deaths_ma, single treat(6) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_6.gph", replace
actest, lags(6)

**Telehealth
use "$data/Google-trends-Telehealth-data/weekly_Telehealth_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_Telehealth_19_21 daily_cases_ma daily_deaths_ma, single treat(1) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_1.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21 daily_cases_ma daily_deaths_ma, single treat(2) trperiod(08mar2020; 20dec2020) lag(3) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_2.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21 daily_cases_ma daily_deaths_ma, single treat(3) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_3.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21 daily_cases_ma daily_deaths_ma, single treat(4) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_4.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21 daily_cases_ma daily_deaths_ma, single treat(5) trperiod(08mar2020; 20dec2020) lag(3) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_5.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21 daily_cases_ma daily_deaths_ma, single treat(6) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_6.gph", replace
actest, lags(6)


**Telemedicine
use "$data/Google-trends-Telemedicine-data/weekly_Telemedicine_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_Telemedicine_19_21 daily_cases_ma daily_deaths_ma, single treat(1) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_1.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21 daily_cases_ma daily_deaths_ma, single treat(2) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_2.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21 daily_cases_ma daily_deaths_ma, single treat(3) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_3.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21 daily_cases_ma daily_deaths_ma, single treat(4) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_4.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21 daily_cases_ma daily_deaths_ma, single treat(5) trperiod(08mar2020; 20dec2020) lag(3) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_5.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21 daily_cases_ma daily_deaths_ma, single treat(6) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_6.gph", replace
actest, lags(6)

**OnlineNurse
use "$data/Google-trends-OnlineNurse-data/weekly_OnlineNurse_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_OnlineNurse_19_21 daily_cases_ma daily_deaths_ma, single treat(1) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_1.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21 daily_cases_ma daily_deaths_ma, single treat(2) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_2.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21 daily_cases_ma daily_deaths_ma, single treat(3) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_3.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21 daily_cases_ma daily_deaths_ma, single treat(4) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_4.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21 daily_cases_ma daily_deaths_ma, single treat(5) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_5.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21 daily_cases_ma daily_deaths_ma, single treat(6) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_6.gph", replace
actest, lags(6)

**OnlinePharmacy
use "$data/Google-trends-OnlinePharmacy-data/weekly_OnlinePharmacy_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_OnlinePharmacy_19_21 daily_cases_ma daily_deaths_ma, single treat(1) trperiod(08mar2020; 20dec2020) lag(3) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_1.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21 daily_cases_ma daily_deaths_ma, single treat(2) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_2.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21 daily_cases_ma daily_deaths_ma, single treat(3) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_3.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21 daily_cases_ma daily_deaths_ma, single treat(4) trperiod(08mar2020; 20dec2020) lag(4) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_4.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21 daily_cases_ma daily_deaths_ma, single treat(5) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_5.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21 daily_cases_ma daily_deaths_ma, single treat(6) trperiod(08mar2020; 20dec2020) lag(5) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_6.gph", replace
actest, lags(6)

**HealthApp
use "$data/Google-trends-HealthApp-data/weekly_HealthApp_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_HealthApp_19_21 daily_cases_ma daily_deaths_ma, single treat(1) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_1.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21 daily_cases_ma daily_deaths_ma, single treat(2) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_2.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21 daily_cases_ma daily_deaths_ma, single treat(3) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_3.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21 daily_cases_ma daily_deaths_ma, single treat(4) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_4.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21 daily_cases_ma daily_deaths_ma, single treat(5) trperiod(08mar2020; 20dec2020) lag(1) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_5.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21 daily_cases_ma daily_deaths_ma, single treat(6) trperiod(08mar2020; 20dec2020) lag(0) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_6.gph", replace
actest, lags(6)

*Merge figures
forvalues i=1/6{
graph combine "$results/OnlineDoctor/OnlineDoctor_ITSA_`i'.gph" "$results/OnlineHealth/OnlineHealth_ITSA_`i'.gph" "$results/Telehealth/Telehealth_ITSA_`i'.gph" "$results/Telemedicine/Telemedicine_ITSA_`i'.gph" "$results/HealthApp/HealthApp_ITSA_`i'.gph", rows(3) cols(2) imargin(0 0 0 0 0 0 0) iscale(.5)
graph export "$results/Tables and Figures/ITSA_Results_`i'.pdf", replace
}

graph combine "$results/OnlineDoctor/OnlineDoctor_ITSA_1.gph" "$results/OnlineHealth/OnlineHealth_ITSA_1.gph" "$results/Telehealth/Telehealth_ITSA_1.gph" "$results/Telemedicine/Telemedicine_ITSA_1.gph" "$results/HealthApp/HealthApp_ITSA_1.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_2.gph" "$results/OnlineHealth/OnlineHealth_ITSA_2.gph" "$results/Telehealth/Telehealth_ITSA_2.gph" "$results/Telemedicine/Telemedicine_ITSA_2.gph" "$results/HealthApp/HealthApp_ITSA_2.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_3.gph" "$results/OnlineHealth/OnlineHealth_ITSA_3.gph" "$results/Telehealth/Telehealth_ITSA_3.gph" "$results/Telemedicine/Telemedicine_ITSA_3.gph" "$results/HealthApp/HealthApp_ITSA_3.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_4.gph" "$results/OnlineHealth/OnlineHealth_ITSA_4.gph" "$results/Telehealth/Telehealth_ITSA_4.gph" "$results/Telemedicine/Telemedicine_ITSA_4.gph" "$results/HealthApp/HealthApp_ITSA_4.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_5.gph" "$results/OnlineHealth/OnlineHealth_ITSA_5.gph" "$results/Telehealth/Telehealth_ITSA_5.gph" "$results/Telemedicine/Telemedicine_ITSA_5.gph" "$results/HealthApp/HealthApp_ITSA_5.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_6.gph" "$results/OnlineHealth/OnlineHealth_ITSA_6.gph" "$results/Telehealth/Telehealth_ITSA_6.gph" "$results/Telemedicine/Telemedicine_ITSA_6.gph" "$results/HealthApp/HealthApp_ITSA_6.gph", rows(6) cols(5) xsize(15) ysize(15) iscale(*0.3)
graph export "$results/Tables and Figures/ITSA_Results_total.pdf", replace

*Placebo interrupted time series analysis using 2017-2019 data
global data "C:/Users/robin/Dropbox/Google Trends/CTA"
global results "C:/Users/robin/Dropbox/Google Trends/Output/CTA"

global data "/Users/robinvankessel/Dropbox/Google Trends/CTA"
global results "/Users/robinvankessel/Dropbox/Google Trends/Output/CTA"

**OnlineDoctor
use "$data/Google-trends-OnlineDoctor-data/weekly_OnlineDoctor_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_OnlineDoctor_19_21, single treat(1) trperiod(11mar2018; 16dec2018) lag(2) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_1.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21, single treat(2) trperiod(11mar2018; 16dec2018) lag(3) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_2.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21, single treat(3) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_3.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21, single treat(4) trperiod(11mar2018; 16dec2018) lag(2) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_4.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21, single treat(5) trperiod(11mar2018; 16dec2018) lag(2) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_5.gph", replace
actest, lags(6)

itsa w_OnlineDoctor_19_21, single treat(6) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineDoctor/OnlineDoctor_ITSA_6.gph", replace
actest, lags(6)

**OnlineHealth
use "$data/Google-trends-OnlineHealth-data/weekly_OnlineHealth_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_OnlineHealth_19_21, single treat(1) trperiod(11mar2018; 16dec2018) lag(2) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_1.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21, single treat(2) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_2.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21, single treat(3) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_3.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21, single treat(4) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_4.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21, single treat(5) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_5.gph", replace
actest, lags(6)

itsa w_OnlineHealth_19_21, single treat(6) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineHealth/OnlineHealth_ITSA_6.gph", replace
actest, lags(6)

**eHealth
use "$data/Google-trends-eHealth-data/weekly_eHealth_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_eHealth_19_21, single treat(1) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_1.gph", replace
actest, lags(6)

itsa w_eHealth_19_21, single treat(2) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_2.gph", replace
actest, lags(6)

itsa w_eHealth_19_21, single treat(3) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_3.gph", replace
actest, lags(6)

itsa w_eHealth_19_21, single treat(4) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_4.gph", replace
actest, lags(6)

itsa w_eHealth_19_21, single treat(5) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_5.gph", replace
actest, lags(6)

itsa w_eHealth_19_21, single treat(6) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/eHealth/eHealth_ITSA_6.gph", replace
actest, lags(6)

**Telehealth
use "$data/Google-trends-Telehealth-data/weekly_Telehealth_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_Telehealth_19_21, single treat(1) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_1.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21, single treat(2) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_2.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21, single treat(3) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_3.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21, single treat(4) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_4.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21, single treat(5) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_5.gph", replace
actest, lags(6)

itsa w_Telehealth_19_21, single treat(6) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/Telehealth/Telehealth_ITSA_6.gph", replace
actest, lags(6)


**Telemedicine
use "$data/Google-trends-Telemedicine-data/weekly_Telemedicine_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_Telemedicine_19_21, single treat(1) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_1.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21, single treat(2) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_2.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21, single treat(3) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_3.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21, single treat(4) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_4.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21, single treat(5) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_5.gph", replace
actest, lags(6)

itsa w_Telemedicine_19_21, single treat(6) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/Telemedicine/Telemedicine_ITSA_6.gph", replace
actest, lags(6)

**OnlineNurse
use "$data/Google-trends-OnlineNurse-data/weekly_OnlineNurse_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_OnlineNurse_19_21, single treat(1) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_1.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21, single treat(2) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_2.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21, single treat(3) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_3.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21, single treat(4) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_4.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21, single treat(5) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_5.gph", replace
actest, lags(6)

itsa w_OnlineNurse_19_21, single treat(6) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/OnlineNurse/OnlineNurse_ITSA_6.gph", replace
actest, lags(6)

**OnlinePharmacy
use "$data/Google-trends-OnlinePharmacy-data/weekly_OnlinePharmacy_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_OnlinePharmacy_19_21, single treat(1) trperiod(11mar2018; 16dec2018) lag(3) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_1.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21, single treat(2) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_2.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21, single treat(3) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_3.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21, single treat(4) trperiod(11mar2018; 16dec2018) lag(4) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_4.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21, single treat(5) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_5.gph", replace
actest, lags(6)

itsa w_OnlinePharmacy_19_21, single treat(6) trperiod(11mar2018; 16dec2018) lag(5) posttrend figure replace
graph save "Graph" "$results/OnlinePharmacy/OnlinePharmacy_ITSA_6.gph", replace
actest, lags(6)

**HealthApp
use "$data/Google-trends-HealthApp-data/weekly_HealthApp_19_21_all_full.dta", clear
gen dates = daily(date, "YMD")
format %td dates

tsset country dates, delta(7)

itsa w_HealthApp_19_21, single treat(1) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_1.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21, single treat(2) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_2.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21, single treat(3) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_3.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21, single treat(4) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_4.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21, single treat(5) trperiod(11mar2018; 16dec2018) lag(1) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_5.gph", replace
actest, lags(6)

itsa w_HealthApp_19_21, single treat(6) trperiod(11mar2018; 16dec2018) lag(0) posttrend figure replace
graph save "Graph" "$results/HealthApp/HealthApp_ITSA_6.gph", replace
actest, lags(6)

*Merge figures
forvalues i=1/6{
graph combine "$results/OnlineDoctor/OnlineDoctor_ITSA_`i'.gph" "$results/OnlineHealth/OnlineHealth_ITSA_`i'.gph" "$results/Telehealth/Telehealth_ITSA_`i'.gph" "$results/Telemedicine/Telemedicine_ITSA_`i'.gph" "$results/HealthApp/HealthApp_ITSA_`i'.gph", rows(3) cols(2) imargin(0 0 0 0 0 0 0) iscale(.5)
graph export "$results/Tables and Figures/ITSA_Results_`i'.pdf", replace
}

graph combine "$results/OnlineDoctor/OnlineDoctor_ITSA_1.gph" "$results/OnlineHealth/OnlineHealth_ITSA_1.gph" "$results/Telehealth/Telehealth_ITSA_1.gph" "$results/Telemedicine/Telemedicine_ITSA_1.gph" "$results/HealthApp/HealthApp_ITSA_1.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_2.gph" "$results/OnlineHealth/OnlineHealth_ITSA_2.gph" "$results/Telehealth/Telehealth_ITSA_2.gph" "$results/Telemedicine/Telemedicine_ITSA_2.gph" "$results/HealthApp/HealthApp_ITSA_2.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_3.gph" "$results/OnlineHealth/OnlineHealth_ITSA_3.gph" "$results/Telehealth/Telehealth_ITSA_3.gph" "$results/Telemedicine/Telemedicine_ITSA_3.gph" "$results/HealthApp/HealthApp_ITSA_3.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_4.gph" "$results/OnlineHealth/OnlineHealth_ITSA_4.gph" "$results/Telehealth/Telehealth_ITSA_4.gph" "$results/Telemedicine/Telemedicine_ITSA_4.gph" "$results/HealthApp/HealthApp_ITSA_4.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_5.gph" "$results/OnlineHealth/OnlineHealth_ITSA_5.gph" "$results/Telehealth/Telehealth_ITSA_5.gph" "$results/Telemedicine/Telemedicine_ITSA_5.gph" "$results/HealthApp/HealthApp_ITSA_5.gph" "$results/OnlineDoctor/OnlineDoctor_ITSA_6.gph" "$results/OnlineHealth/OnlineHealth_ITSA_6.gph" "$results/Telehealth/Telehealth_ITSA_6.gph" "$results/Telemedicine/Telemedicine_ITSA_6.gph" "$results/HealthApp/HealthApp_ITSA_6.gph", rows(6) cols(5) xsize(15) ysize(15) iscale(*0.3)
graph export "$results/Tables and Figures/ITSA_Results_total.pdf", replace
