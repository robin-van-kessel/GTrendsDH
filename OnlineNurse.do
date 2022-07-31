*Creation of database of OnlineNurse

	/* Merge Weekly and Daily DataBases*/

	forvalues i=1/6 {
	global sub_file "Google-trends-OnlineNurse-data/`i'"
	
	insheet using "$data/$sub_file/multiTimeline_w(`i').csv", delimiter(",") clear
	label var date "Date (String)"
	rename hits w_OnlineNurse_19_21
	label var w_OnlineNurse_19_21 "Weekly queries: 19-21"
	save "$data/$sub_file/weekly_search_19_21_(`i').dta", replace
	
	insheet using "$data/$sub_file/multiTimeline(`i')_19.csv", delimiter(",") clear
	label var date "Date (String)"
	rename hits d_OnlineNurse_19
	label var d_OnlineNurse_19 "Daily queries: 19"
	save "$data/$sub_file/daily_search_19_(`i').dta", replace

	insheet using "$data/$sub_file/multiTimeline(`i')_20.csv", delimiter(",") clear
	label var date "Date (String)"
	rename hits d_OnlineNurse_20
	label var d_OnlineNurse_20 "Daily queries: 20"
	save "$data/$sub_file/daily_search_20_(`i').dta", replace

	insheet using "$data/$sub_file/multiTimeline(`i')_21.csv", delimiter(",") clear
	label var date "Date (String)"
	rename hits d_OnlineNurse_21
	label var d_OnlineNurse_21 "Daily queries: 21"
	save "$data/$sub_file/daily_search_21_(`i').dta", replace
	
	use "$data/$sub_file/weekly_search_19_21_(`i').dta", clear
	merge 1:1 date using "$data/$sub_file/daily_search_19_(`i').dta"
	drop _merge
	merge 1:1 date using "$data/$sub_file/daily_search_20_(`i').dta"
	drop _merge
	merge 1:1 date using "$data/$sub_file/daily_search_21_(`i').dta"
	drop _merge
	sort date
	
	drop if d_OnlineNurse_19==. & d_OnlineNurse_20==. & d_OnlineNurse_21==.
	replace w_OnlineNurse_19_21=w_OnlineNurse_19_21[_n-1] if w_OnlineNurse_19_21==.
	destring *OnlineNurse*, replace
	save "$data/$sub_file/daily_search_19_21_(`i').dta", replace
	}

	/* Create Country, Year, Month, Week, Day Variables*/

	forvalues i=1/6 {
	global sub_file "Google-trends-OnlineNurse-data/`i'"

	use "$data/$sub_file/daily_search_19_21_(`i').dta", clear
	gen edate=date(date, "YMD")
	format edate %d
	gen year=year(edate)
	gen month=month(edate)
	gen week=week(edate)

	sort year date
	bysort year week: gen day_w=_n

	drop if month==12 /*Keep from January 1st to April 1st*/
	drop if date=="2020-02-29" /* 2020: bissextile*/

	sort year date
	bysort year: gen day=_n

	label var year "Year"
	label var month "Month"
	label var week "Week"
	label var day "Day"
	label var day_w "Day of the week"
	drop edate

	gen country=`i'
	label var country "Country"

	save "$data/$sub_file/daily_search_19_21_(`i').dta", replace
	}

	/* Rescale Daily data using Weekly Data*/

	forvalues i=1/6 {
	global sub_file "Google-trends-OnlineNurse-data/`i'"

	use "$data/$sub_file/daily_search_19_21_(`i').dta", clear
	egen w_OnlineNurse_19=mean(d_OnlineNurse_19) if year==2019, by(country week)
	egen w_OnlineNurse_20=mean(d_OnlineNurse_20) if year==2020, by(country week)
	egen w_OnlineNurse_21=mean(d_OnlineNurse_21) if year==2021, by(country week)

	gen d_OnlineNurse_19_21=.
	replace d_OnlineNurse_19_21=d_OnlineNurse_19 if year==2019
	replace d_OnlineNurse_19_21=d_OnlineNurse_20 if year==2020
	replace d_OnlineNurse_19_21=d_OnlineNurse_21 if year==2021
	
	*Generating the weekly search interest weights
	gen stand_OnlineNurse_19_21=.
	replace stand_OnlineNurse_19_21=d_OnlineNurse_19*(w_OnlineNurse_19_21/w_OnlineNurse_19) if year==2019
	replace stand_OnlineNurse_19_21=d_OnlineNurse_20*(w_OnlineNurse_19_21/w_OnlineNurse_20) if year==2020
	replace stand_OnlineNurse_19_21=d_OnlineNurse_21*(w_OnlineNurse_19_21/w_OnlineNurse_21) if year==2021

	egen max_stand_OnlineNurse_19_21=max(stand_OnlineNurse_19_21)
	gen normalised_OnlineNurse_19_21=(stand_OnlineNurse_19_21/max_stand_OnlineNurse_19_21)*100
	replace normalised_OnlineNurse_19_21=0 if normalised_OnlineNurse_19_21==.
	label var normalised_OnlineNurse_19_21 "Daily queries (adjusted): 19-21" 

	save "$data/$sub_file/daily_search_19_21_(`i').dta", replace
	}
