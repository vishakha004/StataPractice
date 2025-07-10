**********************************************************
* This dofile creates the merged dataset *
**********************************************************

**********************************************************
*This files solves the week 1 assignment given by the Princeton Empirial Studies of Conflict (ESOC) lab for their Pre-doctoral training curriculum, available publicly on Github.
**********************************************************


************************************************************
**# *******1- Constructing Panel Data***********
************************************************************


*This dataset contains 1 variables and 10 observations
import delimited "/Users/vishakhasingla/Desktop/predoc/week1/islamist_groups.csv", varnames(1) clear 

*This dataset contains 9 variables and 191,464 observations
import delimited "/Users/vishakhasingla/Desktop/predoc/week1/GTD.csv", varnames(1) clear 

*understanding dataset
describe
su

*checking for duplicates
duplicates report
duplicates report eventid

*checking for missing values
count if missing(eventid, iyear, imonth, iday, country_txt, provstate, city)

*No missing values or duplicates found.

*891 rows have imonth==0 or iday==0 indicating missing data. These observations are dropped to make the subsequent merge process easier.

tab iyear if imonth==0|iday==0
drop if imonth==0|iday==0
*891 observations are dropped

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/GTD_edited.dta",replace

*This dataset contains 7 variables and 19 observations
import delimited "/Users/vishakhasingla/Desktop/predoc/week1/Russian_Holidays.csv", varnames(1) clear 
 
*understanding dataset
describe
su

*variable Religious is a string and has NA observations

gen religious_binary=.
replace religious_binary=0 if religious=="0"
replace religious_binary=1 if religious=="1"
replace religious_binary=. if religious=="NA"
recast byte religious_binary
drop religious

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/Russian_Holidays_edited.dta", replace

*This dataset contains 5 variables and 66,096 observations
import delimited "/Users/vishakhasingla/Desktop/predoc/week1/IRA_tweets.csv", clear 
describe
su

*checking for missing values
count if missing(date, day, tweet_count_all,tweet_count_blm,tweet_count_islam)

*checking for duplicates
duplicates report
*many duplicate rows found- there are 66096/51=1296 unique observations that need to be derived from these duplicate rows 

duplicates list

*removing the duplicates-now 1,296 observations left
duplicates drop
su 
describe

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/IRA_tweets_edited.dta", replace

*organising a panel dataset

*in the GTD dataset, generating a date, so we can merge it with the IRA tweets dataset

use "/Users/vishakhasingla/Desktop/predoc/week1/edited files/GTD_edited.dta",clear

*creating a date variable for merging
gen date= mdy(imonth,iday,iyear)

*format for readability
format date %tdCY-N-D
keep if date >= td(01jan2015) & date <= td(30jun2018)
sort date

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/GTD_edited.dta", replace

*editing the IRA dataset

use "/Users/vishakhasingla/Desktop/predoc/week1/edited files/IRA_tweets_edited.dta", clear
sort date

*changing the format of the date variable from string to float in stata date type
rename date date_event
gen date= daily(date_event, "YMD")
format date %tdCY-N-D
drop date_event

keep if date >= td(01jan2015) & date <= td(30jun2018)

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/IRA_tweets_edited.dta", replace

*now the date variable in both the IRA tweets and GTA datasets are in stata date format

************************************************************
**# ******* Merging the datasets ***********
************************************************************

use "/Users/vishakhasingla/Desktop/predoc/week1/edited files/GTD_edited.dta"
merge m:1 date using "/Users/vishakhasingla/Desktop/predoc/week1/edited files/IRA_tweets_edited.dta"
tab _merge
drop _merge

*44,532 observations were matched (100% perfect merge)

************************************************************
**# ******* Making indicator binary variables ***********
************************************************************

*indicator column for whether a terrorist event occured in russia
gen te_russia = (country_txt == "Russia")
tab te_russia

*indicator column for whether a islamist terrorist event occured in russia
gen te_islam_russia=.

replace te_islam_russia=1 if te_russia==1 & (gname=="Caucasus Emirate" | gname== "Caucasus Province of the Islamic State" | gname== "Chechen Rebels"|gname== "Gunib Group" | gname=="Imam Shamil Battalion" | gname== "Islamic State of Iraq and the Levant (ISIL)" | gname== "Jihadi-inspired extremists"| gname=="Kizilyurtovskiy Group"| gname=="Muslim extremists" |gname=="Shamil Group")

replace te_islam_russia = 0 if missing(te_islam_russia)

sort date
* Make sure Stata knows the data is sorted by date
egen max_te_russia = max(te_russia), by(date)
egen max_te_islam_russia = max(te_islam_russia), by(date)

* Replace the original variables if you want
replace te_russia = max_te_russia
replace te_islam_russia = max_te_islam_russia

* (Optional) drop the intermediate vars
drop max_te_russia max_te_islam_russia

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/merged_data.dta",replace

*Attaching indicator variables from the Russian Holidays dataset

*First we homogenise the date format in merged dataset and russian holidays dataset

use "/Users/vishakhasingla/Desktop/predoc/week1/edited files/Russian_Holidays_edited.dta"
describe

gen fake_date_s = "2000"+month+"1"
gen fake_date = date(fake_date_s, "YMD")
gen byte monthnum = month(fake_date)
describe
rename imonth month
rename monthnum imonth
rename day iday

*also we have two holidays on the same day- all the binary indicators are the same for both the holidays so we will be dropping one for ease of merging the data
duplicates list iday imonth

drop if holiday_name=="Extra holiday in lieu of Jan. 1"
duplicates list iday imonth

*making holiday indicator
gen holiday=1

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/Russian_Holidays_edited.dta", replace

use "/Users/vishakhasingla/Desktop/predoc/week1/edited files/merged_data.dta",clear

merge m:1 iday imonth using "/Users/vishakhasingla/Desktop/predoc/week1/edited files/Russian_Holidays_edited.dta"
replace holiday = 0 if missing(holiday)
*There are a total of 2,392 holidays in the merged dataset as indicated by the following command
tab _merge
drop _merge

sort date
drop summary notes fake_date_s fake_date


replace public = 0 if missing(public)
replace political = 0 if missing(political)
replace religious_binary = 0 if missing(religious_binary)
xtset eventid date

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/merged_data.dta",replace


*To check whether panel is unbalanced/balanced
*It is a weakly balanced dataset.

*(a) There are a total of 44,532 observations in the merged dataset.
*(b) 

tab te_russia if te_russia==1
*120 days

tab te_islam_russia if te_islam_russia==1
*36 days

tab te_islam_russia if te_islam_russia==1 & te_russia==1
*36 days

*So the number of days there was a terrorist or islamist terrorist event in Russia is 120 days.

*(c)


use "/Users/vishakhasingla/Desktop/predoc/week1/edited files/merged_data.dta",clear
drop if missing(date)
duplicates drop date, force
tab holiday if holiday==1
*There are a total of 70 unique holidays between 1 Jan 2015 and 30 June 2018.

tab public if public==1
tab political if political==1
tab religious_binary if religious_binary==1

*There are 43 public holidays, 0 political holidays and 16 religious holidays. 23 were not public, political or religious holidays and 12 were both religious and public holidays.

save "/Users/vishakhasingla/Desktop/predoc/week1/edited files/holiday_merged_data.dta",replace

**********************************************************
