*Creation of database of eHealth

	/* Merge Weekly and Daily DataBases*/

	forvalues i=1/6 {
	global sub_file "Google-trends-eHealth-data/`i'"
	
	insheet using "$data/$sub_file/multiTimeline_w(`i').csv", delimiter(",") clear
	label var date "Date (String)"
	rename hits w_eHealth_19_21
	label var w_eHealth_19_21 "Weekly queries: 19-21"
	save "$data/$sub_file/weekly_search_19_21_(`i').dta", replace
	
	insheet using "$data/$sub_file/multiTimeline(`i')_19.csv", delimiter(",") clear
	label var date "Date (String)"
	rename hits d_eHealth_19
	label var d_eHealth_19 "Daily queries: 19"
	save "$data/$sub_file/daily_search_19_(`i').dta", replace

	insheet using "$data/$sub_file/multiTimeline(`i')_20.csv", delimiter(",") clear
	label var date "Date (String)"
	rename hits d_eHealth_20
	label var d_eHealth_20 "Daily queries: 20"
	save "$data/$sub_file/daily_search_20_(`i').dta", replace

	insheet using "$data/$sub_file/multiTimeline(`i')_21.csv", delimiter(",") clear
	label var date "Date (String)"
	rename hits d_eHealth_21
	label var d_eHealth_21 "Daily queries: 21"
	save "$data/$sub_file/daily_search_21_(`i').dta", replace
	
	use "$data/$sub_file/weekly_search_19_21_(`i').dta", clear
	merge 1:1 date using "$data/$sub_file/daily_search_19_(`i').dta"
	drop _merge
	merge 1:1 date using "$data/$sub_file/daily_search_20_(`i').dta"
	drop _merge
	merge 1:1 date using "$data/$sub_file/daily_search_21_(`i').dta"
	drop _merge
	sort date

	drop if d_eHealth_19==. & d_eHealth_20==. & d_eHealth_21==.
	replace w_eHealth_19_21=w_eHealth_19_21[_n-1] if w_eHealth_19_21==.
	destring *eHealth*, replace
	save "$data/$sub_file/daily_search_19_21_(`i').dta", replace
	}

	/* Create Country, Year, Month, Week, Day Variables*/

	forvalues i=1/6 {
	global sub_file "Google-trends-eHealth-data/`i'"

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
	global sub_file "Google-trends-eHealth-data/`i'"

	use "$data/$sub_file/daily_search_19_21_(`i').dta", clear
	egen w_eHealth_19=mean(d_eHealth_19) if year==2019, by(country week)
	egen w_eHealth_20=mean(d_eHealth_20) if year==2020, by(country week)
	egen w_eHealth_21=mean(d_eHealth_21) if year==2021, by(country week)

	gen d_eHealth_19_21=.
	replace d_eHealth_19_21=d_eHealth_19 if year==2019
	replace d_eHealth_19_21=d_eHealth_20 if year==2020
	replace d_eHealth_19_21=d_eHealth_21 if year==2021
	
	*Generating the weekly search interest weights
	gen stand_eHealth_19_21=.
	replace stand_eHealth_19_21=d_eHealth_19*(w_eHealth_19_21/w_eHealth_19) if year==2019
	replace stand_eHealth_19_21=d_eHealth_20*(w_eHealth_19_21/w_eHealth_20) if year==2020
	replace stand_eHealth_19_21=d_eHealth_21*(w_eHealth_19_21/w_eHealth_21) if year==2021

	egen max_stand_eHealth_19_21=max(stand_eHealth_19_21)
	gen normalised_eHealth_19_21=(stand_eHealth_19_21/max_stand_eHealth_19_21)*100
	replace normalised_eHealth_19_21=0 if normalised_eHealth_19_21==.
	label var normalised_eHealth_19_21 "Daily queries (adjusted): 19-21" 

	save "$data/$sub_file/daily_search_19_21_(`i').dta", replace
	}
