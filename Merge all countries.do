

local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"
	
	/* Merge All Countries with English Keywords */

	foreach var of local varlist {
	use "$data/Google-trends-`var'-data/1/daily_search_19_21_(1).dta", clear

	forvalues i=2/6 {
	global sub_file "Google-trends-`var'-data/`i'"
	append using "$data/$sub_file/daily_search_19_21_(`i').dta"
	}

	/* Generate pandemic indicators*/ 
	gen pandemic_start=day if date =="2020-03-11"
	bysort country: egen m_pandemic_start = mean(pandemic_start)
	replace pandemic_start=m_pandemic_start
	drop m_pandemic_start
	bysort country date: gen pandemic_duration=day-pandemic_start
	drop pandemic_start
	label var pandemic_duration "Days into the COVID-19 pandemic"
	gen pandemic_period=0
	replace pandemic_period=1 if pandemic_duration>=0 & pandemic_duration!=.
	
	order country date year month week day day_w d_`var'_19_21 w_`var'_19_21 normalised_`var'_19_21
	
	/* Generate population indicators*/
	gen pop_size = 0
	replace pop_size=25750198 if country==1		/*Australia*/
	replace pop_size=36991981 if country==2		/*Canada*/
	replace pop_size=5122600 if country==3		/*New Zealand*/
	replace pop_size=68207116 if country==4		/*United Kingdom*/
	replace pop_size=332915073 if country==5	/*United States*/
	replace pop_size=5010000 if country==6		/*Ireland*/
	
	
	/*Merge with Oxford Policy Tracker data*/
	merge 1:1 country date using "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2020-2021.dta"
	keep if _merge == 1 | _merge == 3
	drop _merge
	
	replace daily_cases_ma = 0 if (daily_cases_ma >= .)
	replace daily_deaths_ma = 0 if (daily_deaths_ma >= .)
	
	save "$data/Google-trends-`var'-data/daily_`var'_19_21_all_full.dta", replace
}



*Operationalise weekly data for interrupted time series analysis
local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"

foreach var of local varlist {
	use "$data/Google-trends-`var'-data/1/weekly_search_19_21_(1).dta", clear
	
	forvalues i=2/6 {
		global sub_file "Google-trends-`var'-data/`i'"
		append using "$data/$sub_file/weekly_search_19_21_(`i').dta"
	}
	save "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", replace

	gen country=.
	replace country=1 if geo=="AU"
	replace country=2 if geo=="CA"
	replace country=3 if geo=="NZ"
	replace country=4 if geo=="GB"
	replace country=5 if geo=="US"
	replace country=6 if geo=="IE"
	
	gen pop_size = 0
	replace pop_size=25750198 if country==1		/*Australia*/
	replace pop_size=36991981 if country==2		/*Canada*/
	replace pop_size=5122600 if country==3		/*New Zealand*/
	replace pop_size=68207116 if country==4		/*United Kingdom*/
	replace pop_size=332915073 if country==5	/*United States*/
	replace pop_size=5010000 if country==6		/*Ireland*/
	
	save "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", replace
	
	bysort country: gen edate=date(date, "YMD")
	format edate %d
	bysort country: gen year=year(edate)
	bysort country: gen month=month(edate)
	bysort country: gen week=week(edate)
	label var year "Year"
	label var month "Month"
	label var week "Week"
	drop edate
	bysort country: gen week_n=_n
	
	save "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", replace
	
		/*Merge with Oxford Policy Tracker data*/
	merge 1:1 country date using "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2020-2021.dta"
	keep if _merge == 1 | _merge == 3
	drop _merge
	
	replace daily_cases_ma = 0 if (daily_cases_ma >= .)
	replace daily_deaths_ma = 0 if (daily_deaths_ma >= .)
	
	save "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", replace
}

*Operationalise weekly data for placebo interrupted time series analysis
global data "C:/Users/robin/Dropbox/Google Trends/CTA"
global results "C:/Users/robin/Dropbox/Google Trends/Output/CTA"

local varlist "OnlineDoctor OnlineHealth eHealth Telehealth Telemedicine OnlineNurse OnlinePharmacy HealthApp"

foreach var of local varlist {
	use "$data/Google-trends-`var'-data/1/weekly_search_19_21_(1).dta", clear
	
	forvalues i=2/6 {
		global sub_file "Google-trends-`var'-data/`i'"
		append using "$data/$sub_file/weekly_search_19_21_(`i').dta"
	}
	save "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", replace

	gen country=.
	replace country=1 if geo=="AU"
	replace country=2 if geo=="CA"
	replace country=3 if geo=="NZ"
	replace country=4 if geo=="GB"
	replace country=5 if geo=="US"
	replace country=6 if geo=="IE"
	
	gen pop_size = 0
	replace pop_size=25750198 if country==1		/*Australia*/
	replace pop_size=36991981 if country==2		/*Canada*/
	replace pop_size=5122600 if country==3		/*New Zealand*/
	replace pop_size=68207116 if country==4		/*United Kingdom*/
	replace pop_size=332915073 if country==5	/*United States*/
	replace pop_size=5010000 if country==6		/*Ireland*/
	
	save "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", replace
	
	bysort country: gen edate=date(date, "YMD")
	format edate %d
	bysort country: gen year=year(edate)
	bysort country: gen month=month(edate)
	bysort country: gen week=week(edate)
	label var year "Year"
	label var month "Month"
	label var week "Week"
	drop edate
	bysort country: gen week_n=_n
	
	save "$data/Google-trends-`var'-data/weekly_`var'_19_21_all_full.dta", replace
}
