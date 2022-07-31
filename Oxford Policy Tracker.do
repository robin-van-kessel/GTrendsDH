**2020
import delimited "/Users/robinvankessel/Downloads/OxCGRT_withnotes_2020.csv", clear
 
drop jurisdiction c1_notes c2_notes c3_notes c4_notes c5_notes c6_notes c7_notes c8_notes e1_notes e2_notes e3_notes e4_notes h1_notes h2_notes h3_notes h4_notes h5_notes h6_notes h7_notes h8_notes m1_wildcard m1_notes v1_notes v2_notes v3_notes v4_notes

save "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2020.dta", replace

use "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2020.dta", clear

keep if countryname == "Australia" | countryname == "Canada" | countryname == "Ireland" | countryname == "United Kingdom" | countryname == "United States" | countryname == "New Zealand"
 
keep if regionname == ""
 
encode countryname, gen(country_enc)
gen country = 0
replace country = 1 if countryname == "Australia"
replace country = 2 if countryname == "Canada"
replace country = 3 if countryname == "New Zealand"
replace country = 4 if countryname == "United Kingdom"
replace country = 5 if countryname == "United States"
replace country = 6 if countryname == "Ireland"
drop countrycode regionname regioncode
tostring date, gen (date_text)
gen year = substr(date_text, 1,4)
gen month = substr(date_text, 5,2)
gen day = substr(date_text, 7,2)
drop date
egen date = concat(year month day), punct(-)
drop year month day date_text

save "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2020.dta", replace

replace confirmedcases = 0 if (confirmedcases == .)
replace confirmeddeaths = 0 if (confirmeddeaths == .)
encode date, gen(date_enc)

* Daily deaths
bysort country_enc(date_enc): gen daily_deaths = confirmeddeaths - confirmeddeaths[_n-1] if (date_enc - date_enc[_n-1]==1)

* Daily cases
bysort country_enc(date_enc): gen daily_cases = confirmedcases - confirmedcases[_n-1] if (date_enc - date_enc[_n-1]==1)

* Daily cases and deaths (moving averages)
xtset country_enc date_enc
bysort country_enc(date_enc): generate daily_cases_ma  = (F3.daily_cases + F2.daily_cases + F1.daily_cases + daily_cases + L1.daily_cases + L2.daily_cases + L3.daily_cases ) / 7
bysort country_enc(date_enc): generate daily_deaths_ma  = (F3.daily_deaths + F2.daily_deaths + F1.daily_deaths + daily_deaths + L1.daily_deaths + L2.daily_deaths + L3.daily_deaths ) / 7

save "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2020.dta", replace

**2021
import delimited "/Users/robinvankessel/Downloads/OxCGRT_withnotes_2021.csv", clear
 
drop jurisdiction c1_notes c2_notes c3_notes c4_notes c5_notes c6_notes c7_notes c8_notes e1_notes e2_notes e3_notes e4_notes h1_notes h2_notes h3_notes h4_notes h5_notes h6_notes h7_notes h8_notes m1_wildcard m1_notes v1_notes v2_notes v3_notes v4_notes

save "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2021.dta", replace

use "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2021.dta", clear

keep if countryname == "Australia" | countryname == "Canada" | countryname == "Ireland" | countryname == "United Kingdom" | countryname == "United States" | countryname == "New Zealand"
 
keep if regionname == ""
 
encode countryname, gen(country_enc)
gen country = 0
replace country = 1 if countryname == "Australia"
replace country = 2 if countryname == "Canada"
replace country = 3 if countryname == "New Zealand"
replace country = 4 if countryname == "United Kingdom"
replace country = 5 if countryname == "United States"
replace country = 6 if countryname == "Ireland"
drop countrycode regionname regioncode
tostring date, gen (date_text)
gen year = substr(date_text, 1,4)
gen month = substr(date_text, 5,2)
gen day = substr(date_text, 7,2)
drop date
egen date = concat(year month day), punct(-)
drop year month day date_text

save "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2021.dta", replace

replace confirmedcases = 0 if (confirmedcases == .)
replace confirmeddeaths = 0 if (confirmeddeaths == .)
encode date, gen(date_enc)

* Daily deaths
bysort country_enc(date_enc): gen daily_deaths = confirmeddeaths - confirmeddeaths[_n-1] if (date_enc - date_enc[_n-1]==1)

* Daily cases
bysort country_enc(date_enc): gen daily_cases = confirmedcases - confirmedcases[_n-1] if (date_enc - date_enc[_n-1]==1)

* Daily cases and deaths (moving averages)
xtset country_enc date_enc
bysort country_enc(date_enc): generate daily_cases_ma  = (F3.daily_cases + F2.daily_cases + F1.daily_cases + daily_cases + L1.daily_cases + L2.daily_cases + L3.daily_cases ) / 7
bysort country_enc(date_enc): generate daily_deaths_ma  = (F3.daily_deaths + F2.daily_deaths + F1.daily_deaths + daily_deaths + L1.daily_deaths + L2.daily_deaths + L3.daily_deaths ) / 7


save "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2021.dta", replace


*combine the two

use "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2020.dta", clear

append using "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2021.dta"

drop country_enc date_enc

save "/Users/robinvankessel/Dropbox/Google Trends/Data/Oxford Policy Tracker/OxPol-2020-2021.dta", replace
