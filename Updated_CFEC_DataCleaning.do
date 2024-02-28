// Do-file to transform scraped spreadsheets from CFEC into .dta files, track permits over time, and prepare data for mapping permit migration in R

// Author: Greg Boudreaux
// Date: January 2024

// Latest save on Line 335, after Section 1a. As of 2/21, sections 2 and 3 need work.

***********************************************************************************
** Preliminaries: Make sure that all .xls files are in the same directory        **
** Three directories in practice: errors, fisheries A-R, fisheries S-Z
***********************************************************************************
{
// three directories where permits live: 

// C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\Raw Data\ErrorCausingFisheries

// C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\Raw Data\FisherySpreadsheetsGB_AthruR\Fishery spreadsheets

// C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\Raw Data\FisherySpreadsheetsJR_SthruZ\Fishery spreadsheets

// looping through each directory and saving as .dta files

cd "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\Raw Data\ErrorCausingFisheries"

local files: dir . files "*.xls"
foreach file in `files' {
	clear 
	import excel "`file'", sheet("Permits") firstrow clear
	// drop in 1
	local year = Year[2]
	local fishery = Fishery[2]
	di `year'
	di "`fishery'"
	
	save "C:/Users/gboud/Dropbox/Reimer GSR/CFEC_permits/Scraping CFEC Website/FinalFisheries/`fishery'_`year'.dta", replace
}

// appending all .dta files, getting rid of blank first rows from CFEC query tool
cd "C:/Users/gboud/Dropbox/Reimer GSR/CFEC_permits/Scraping CFEC Website/FinalFisheries"
local files: dir . files "*.dta"
clear
append using `files', force
duplicates drop // just checking
drop if Year == ""

// data cleaning work
replace Seq = substr(Seq, 2, 1) if substr(Seq, 1, 1) =="0"
gen PermitNumber = PermitSerial + PermitSerialCheckDigit
gen Name = FirstName + " " + LastName
order PermitNumber, after(PermitSerial)
drop PermitSerial PermitSerialCheckDigit
destring Year Seq, replace
sort PermitNumber Year Seq
drop if Year == 2024 // May be incomplete, so dropping just to be safe. 
// drop if PermitType != "Permanent"

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\PreliminaryFullPermitData.dta", replace // this is full data, minus 15 error-causing permit-years.

clear
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\PreliminaryFullPermitData.dta"

// keeping only permanent permits LEFT OFF HERE
keep if PermitType == "Permanent"
codebook Fishery, compact
tab Fishery


save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", replace  // GB - sub in whatever path you are going to use. 
}

***********************************************************************************
** Section 1: Editing to track permits over time (as in Permit_tracking.do) file ** 
** Incomplete, complete with full dataset.
***********************************************************************************
{
**********************************************************************
******* Section 1a. Some exploratory analysis and further cleaning. **
** Incomplete, complete with full dataset.
**********************************************************************
{

use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear

sort PermitNumber Year 
order Year PermitNumber, first
// generating duplicates to get a good grasp on how many multiple year permits I have
duplicates tag PermitNumber, generate(dup)
order dup, after(PermitNumber)
gen dup2 = dup+1
order dup2, after(dup)
drop dup
rename dup2 dup
order dup, after(PermitNumber)
label var dup "Number of times permit appears in panel"

replace Name = strtrim(Name) // removing trailing spaces
// Checking out the importent identifier variables
sort PermitNumber // no blank permit numbers. good!
sort Fishery // no blank fishery entries. good!
sort FileNumber // no blank owner identifiers. good!

tab Country // No country variable in this data.
tab ForeignAddress // use this with full dataset

/* Come back to this with full data
{
replace country = "USA" if ustrpos(country, "AK")>0
replace country = "USA" if ustrpos(country, "ALASKA")>0
replace country = "USA" if ustrpos(country, "FISHERMANS TERMINAL")>0 // WA
replace country = "CANADA" if ustrpos(country, "CANADA")>0
replace country = "CANADA" if ustrpos(country, "BC")>0
replace country = "CANADA" if ustrpos(country, "B.C.")>0
replace country = "CANADA" if ustrpos(country, "ONTARIO")>0
replace country = "CANADA" if ustrpos(country, "ALBERTA")>0
replace country = "CANADA" if ustrpos(country, "AB")>0
replace country = "CANADA" if ustrpos(country, "PT HARDY")>0
replace country = "ENGLAND" if ustrpos(country, "ENGLAND")>0
replace country = "ENGLAND" if ustrpos(country, "LONDON")>0
replace country = "SWITZERLAND" if ustrpos(country, "SWITZERLAND")>0
replace country = "VIRGIN ISLANDS" if ustrpos(country, "VIRGIN ISLANDS")>0
replace country = "VIRGIN ISLANDS" if ustrpos(country, "SAINT JOHN")>0
replace country = "VIRGIN ISLANDS" if ustrpos(country, "VI")>0
replace country = "ISRAEL" if ustrpos(country, "ISRAEL")>0
replace country = "GERMANY" if ustrpos(country, "GERMANY")>0
replace country = "NORWAY" if ustrpos(country, "NORWAY")>0
replace country = "NEW ZEALAND" if ustrpos(country, "NEW ZEALAND")>0
replace country = "SWEDEN" if ustrpos(country, "SWEDEN")>0
replace country = "AUSTRALIA" if ustrpos(country, "AUSTRAILA")>0
replace country = "AUSTRALIA" if ustrpos(country, "NSW")>0
replace country = "PANAMA" if ustrpos(country, "PANAMA")>0
replace country = "GUAM" if ustrpos(country, "GUAM")>0
replace country = "MILITARY BASE" if ustrpos(country, "APO")>0
replace country = "MILITARY BASE" if ustrpos(country, "FPO")>0
replace country = "MILITARY BASE" if ustrpos(country, "AE")>0
replace country = "PHILIPPINES" if ustrpos(country, "PHILLIPPINES")>0
replace country = "ITALY" if ustrpos(country, "ITALY")>0
replace country = "MEXICO" if ustrpos(country, "PUERTO VALLARTA")>0
replace country = "UK" if ustrpos(country, "UK")>0
replace country = "UK" if ustrpos(country, "UNITED KINGDOM")>0
replace country = "UK" if country =="ENGLAND"
replace country = "GREECE" if ustrpos(country, "GREECE")>0
replace country = "COSTA RICA" if ustrpos(country, "COSTA RICA")>0
replace country = "IRELAND" if ustrpos(country, "IRELAND")>0
replace country = "JAPAN" if ustrpos(country, "JAPAN")>0

tab state if country ==""
replace country = "GUAM" if state == "GU"
replace country = "USA" if country ==""

count if state != "" & country !="USA" // These are potential US states miscategorized in different countries. Only 20 entries, easy to fix if needed later.
tab country

}
*/

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", replace

// Coding fishery identifiers

// opening historical fisheries codes and cleaning to the needed year-fishery format
import delimited "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Identifier Codes\Current and Hist CFEC codes 2023.csv",varnames(1) clear 

replace fishery = subinstr(fishery, " ", "", .)
split years, parse(" - ") gen(yr) destring
gen `c(obs_t)' obs_no = _n
expand yr2-yr1+1
by obs_no (yr1), sort: gen year = yr1[1] + _n - 1, after(years)
drop yr*

drop obs_no years

// looking for year/fishery duplicates

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Identifier Codes\CleanedHistoricalCurrentFisheries.dta", replace

use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear

// merging
rename (Year Fishery) (year fishery)
merge m:1 year fishery using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Identifier Codes\CleanedHistoricalCurrentFisheries.dta"

drop if _merge ==2
order hist_descrip, after(FisheryDescription)
tab Fishery if _merge ==1 // looking at the fishery lines that didn't have a match in the database
di r(r) 

tab FisheryDescription if _merge ==1 // so there are some that have current descrips. 2620.

count if _merge ==1 & FisheryDescription =="" // 23362

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", replace

// let's see if these are present in the current dataset, and I can get descriptions by merging without year. 
import delimited "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Identifier Codes\Current CFEC codes 2023.csv",varnames(1) clear

replace fishery = subinstr(fishery, " ", "", .)
drop status

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Identifier Codes\CleanedCurrentFisheries.dta", replace

use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear

rename _merge orig_merge

merge m:1 fishery using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Identifier Codes\CleanedCurrentFisheries.dta"
drop if _merge ==2
rename _merge new_merge

rename descrip current_descrip
order current_descrip, after(hist_descrip)
sort orig_merge
drop orig_merge new_merge

rename FisheryDescrip descrip
label var descrip "Fishery description from permit data"
label var hist_descrip "Historical description from CFEC site"
label var current_descrip "Current description from CFEC site"

count if descrip =="" & hist_descrip =="" & current_descrip =="" // fill in
tab fishery if descrip =="" & hist_descrip =="" & current_descrip =="" // fill in
tab year if descrip =="" & hist_descrip =="" & current_descrip =="" // fill in

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", replace

// splitting identifiers to be able to sort by catch/gear/region
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear
//////////////////////////////////////////////
//// native description to the permit data.///
//////////////////////////////////////////////
split descrip, gen(descrip) parse(", ")
tab descrip1
rename descrip1 catch_descrip
label var catch_descrip "Catch description from permit data"
tab catch_descrip
replace catch_descrip = "WEATHERVANE SCALLOPS" if catch_descrip == "weathervane scallops"

tab descrip2
rename descrip2 gear_descrip 
label var gear_descrip "Gear description from permit data"
replace gear_descrip = "DREDGE" if gear_descrip =="dredge"

tab descrip3 // there are a few entries that are still gear
replace descrip3 = "VESSEL PERMIT OVER 80'" if descrip3 =="vessel permit over 80'"
replace descrip3 = "VESSEL PERMIT TO 80'" if descrip3 =="vessel permit to 80'"

// remaking variables that have gear in the location variable 
replace gear_descrip = gear_descrip + ", " + descrip3 if descrip3 == "VESSEL PERMIT OVER 80'" | descrip3 == "VESSEL PERMIT TO 80'" | descrip3 == "VL OVER 80'" | descrip3 == "VL UNDER 80'" | descrip3 == "VL UNDER 60'" | descrip3 == "FIXED VL LENGTH TO 60'" | descrip3 == "FIXED VL LENGTH TO 70'" | descrip3 == "FIXED VL LENGTH TO 75'" 
replace descrip3 = descrip4 if descrip3 == "VESSEL PERMIT OVER 80'" | descrip3 == "VESSEL PERMIT TO 80'" | descrip3 == "VL OVER 80'" | descrip3 == "VL UNDER 80'" | descrip3 == "VL UNDER 60'" | descrip3 == "FIXED VL LENGTH TO 60'" | descrip3 == "FIXED VL LENGTH TO 70'" | descrip3 == "FIXED VL LENGTH TO 75'"  
replace descrip4 = "" if descrip3 == descrip4

// cleaning and renaming location variable
tab descrip3
replace descrip3 = "STATEWIDE" if descrip3 =="statewide"
replace descrip3 = "STATEWIDE" if descrip3 =="STATEWIDEDE"
replace descrip3 = "COOK INLET" if descrip3 =="COOK INLETET"
replace descrip3 = "SOUTHEAST" if descrip3 =="SOUTHEASTST"
replace descrip3 = "SOUTHEAST" if descrip3 =="SOUTHEASTERN"
rename descrip3 location_descrip
label var location_descrip "Location from permit data"

tab descrip4 // 835 obs. Denote various economic development nonprofits (?)
rename descrip4 misc_descrip
label var misc_descrip "Misc info from permit data"

//////////////////////////////////////////////
////  current descriptions ///////////////////
//////////////////////////////////////////////

split current_descrip, gen(current_descrip) parse(", ")
tab current_descrip1
tab current_descrip2
tab current_descrip3

tab current_descrip4 // kodiak
replace current_descrip2 = current_descrip2 + ", " + current_descrip3 if current_descrip4 == "KODIAK"
replace current_descrip3 = current_descrip4 if current_descrip4 == "KODIAK"
replace current_descrip4 = "" if current_descrip4 == "KODIAK"
tab current_descrip4

tab current_descrip3
tab current_descrip2
tab current_descrip1
replace current_descrip2 = "FIX GEAR MAXIMUM VESSEL LENGTH 60 AND OVER STATEWIDE" if current_descrip1 =="SABLEFISH FIX GEAR MAXIMUM VESSEL LENGTH "
replace current_descrip1 = "SABLEFISH" if current_descrip1 =="SABLEFISH FIX GEAR MAXIMUM VESSEL LENGTH "

replace current_descrip2 = "FIX GEAR MAXIMUM VESSEL LENGTH 60 AND UNDER STATEWIDE" if current_descrip1 =="SABLEFISH FIXED GEAR VESSEL LENGTH 60 AN "
replace current_descrip1 = "SABLEFISH" if current_descrip1 =="SABLEFISH FIXED GEAR VESSEL LENGTH 60 AN "

rename (current_descrip1 current_descrip2 current_descrip3 /*current_descrip4*/) (catch_current_descrip gear_current_descrip location_current_descrip /*misc_current_descrip*/) 

replace catch_current_descrip = trim(catch_current_descrip)

label var catch_current_descrip "Current catch description from CFEC site"
label var gear_current_descrip "Current gear description from CFEC site"
label var location_current_descrip "Current location from CFEC site"
// label var misc_current_descrip "Misc info from CFEC site"

//////////////////////////////////////////////
////  historical descriptions ////////////////
//////////////////////////////////////////////
split hist_descrip, gen(hist_descrip) parse(", ")

tab hist_descrip4 // KODIAK and STATEWIDE are here
tab hist_descrip3 if hist_descrip4 == "STATEWIDE"
replace hist_descrip2 = hist_descrip2 + ", " + hist_descrip3 if hist_descrip4 == "STATEWIDE"
replace hist_descrip3 = hist_descrip4 if hist_descrip4 == "STATEWIDE"
replace hist_descrip4 = "" if hist_descrip4 == "STATEWIDE"
replace hist_descrip2 = hist_descrip2 + ", " + hist_descrip3 if hist_descrip4 == "KODIAK"
replace hist_descrip3 = hist_descrip4 if hist_descrip4 == "KODIAK"
replace hist_descrip4 = "" if hist_descrip4 == "KODIAK"

tab hist_descrip3
replace hist_descrip3 = "COOK INLET" if hist_descrip3 =="COOK INLETET"
tab hist_descrip2 if hist_descrip3 == "VESSEL UNDER 60'"
replace hist_descrip2 = hist_descrip2 + ", " + hist_descrip3 if hist_descrip3 == "VESSEL UNDER 60'"
tab hist_descrip4 if hist_descrip3 == "VESSEL UNDER 60'"
replace hist_descrip3 = hist_descrip4 if hist_descrip3 == "VESSEL UNDER 60'"

tab hist_descrip2
tab hist_descrip3 if hist_descrip2 == "UNDER STATEWIDE"
replace hist_descrip3 = "STATEWIDE" if hist_descrip2 == "UNDER STATEWIDE"

tab hist_descrip1
replace hist_descrip2 = "FIX GEAR MAXIMUM VESSEL LENGTH 60 AND OVER STATEWIDE" if hist_descrip1 =="SABLEFISH FIX GEAR MAXIMUM VESSEL LENGTH "
replace hist_descrip1 = "SABLEFISH" if hist_descrip1 =="SABLEFISH FIX GEAR MAXIMUM VESSEL LENGTH "

replace hist_descrip2 = "FIX GEAR MAXIMUM VESSEL LENGTH 60 AND UNDER STATEWIDE" if hist_descrip1 =="SABLEFISH FIXED GEAR VESSEL LENGTH 60 AN "
replace hist_descrip1 = "SABLEFISH" if hist_descrip1 =="SABLEFISH FIXED GEAR VESSEL LENGTH 60 AN "

rename (hist_descrip1 hist_descrip2 hist_descrip3 /*hist_descrip4*/) (catch_hist_descrip gear_hist_descrip location_hist_descrip /*misc_hist_descrip*/) 

replace catch_hist_descrip = trim(catch_hist_descrip)

label var catch_hist_descrip "Hist catch description from CFEC site"
label var gear_hist_descrip "Hist gear description from CFEC site"
label var location_hist_descrip "Hist location from CFEC site"
// label var misc_hist_descrip "Misc info from CFEC site"
}

** LATEST SAVE OF THE FULL INITIAL PANEL **
save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", replace

**********************************************************************
******* Section 1b. Making example tracking dataset and variables  *** 
******* for one permit. Generalize this for whole dataset later.   ***
******** Incomplete, complete with full dataset.
**********************************************************************
{
frames reset

use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear

// looking at distribution of duplicate observations of permits
preserve
keep PermitNumber dup
collapse (mean) dup, by(PermitNumber)
tab dup
hist dup
restore

// looking at distribution of # of observed years for each permit
preserve
gen tag = 0
bysort PermitNumber year: replace tag = 1 if _n==1
egen years_observed = sum(tag), by(PermitNumber)
drop tag
order years_observed, after(PermitNumber)
label var years_observed "Number of years permit is seen in panel"
collapse (mean) years_observed, by(PermitNumber)
sort years_observed
tab years_observed
hist years_observed
restore

// Now, drill down to one permit and explore some features of how they move. 

keep if dup ==65 // 65 seems like a nice number, and it necessitates multiple transfers in at least one year, likely more.
count // 650 entries
sort PermitNumber year
keep if PermitNumber == "55390E" // random permit I chose

********************************************
// generating descriptive yearly variables**
********************************************

// variable which records permit records per year (unique within year)
egen yearly_count = count(year), by(year) // tagging years in which the permit shows up multiple times
label var yearly_count "Permit Entries Per Year"

// variable which records range of time permit is in database (unique to permit)
sum year
local range = r(max)-r(min)+1
gen years_range = `range'
order years_range, after(year)
label var years_range "Range of time permit is in database"

// number of years in which permit is explicitly observed
gen tag = 0
bysort year: replace tag = 1 if _n==1
egen years_observed = sum(tag)
drop tag
order years_observed, after(years_range)
label var years_observed "Number of years permit is seen in panel"

// number of years permit is missing from panel
gen years_missing = years_range- years_observed
order years_missing, after(years_observed)
label var years_missing "Number of years permit is missing from panel"

// renaming dup, which is the number of total records for this permit
rename dup obs
label var obs "Number of total records for this permit"

// ordering
order obs Transferable PermitType, after(PermitNumber)
order PermitStatus FirstName Middle LastName Suffix, after(Name)
order yearly_count, after(year)

***********************************************************************************
// tagging and tracking changes in ownership across and within years.
***********************************************************************************

// variable tracking # of times owner shows up in each year (unique by owner-year)
egen owner_count = count(Name), by(year) 
duplicates tag year Name, generate(within_yr_dup_owners)
sort year Name
order within_yr_dup_owners, after(yearly_count)
rename within_yr_dup_owners temp
gen within_yr_dup_owners = temp+1
order within_yr_dup_owners, after(Name)
label var within_yr_dup_owners "Times owner shows up within year"
drop temp

// variable tracking # of unique owners in each year (unique by year)
duplicates tag year Name, generate(temp)
bysort year Name: replace temp = 1 if _n==1
bysort year Name: replace temp = 0 if _n!=1
order temp, after( within_yr_dup_owners)
egen yr_owners = sum (temp), by(year)
order yr_owners, after(temp)
label var yr_owners "Number of owners in the year"
drop temp

// make binary variable indicating the presence of intra year transfers w/i that year
gen intra_xfers = 0
replace intra_xfers = 1 if yr_owners > 1
order intra_xfers, after(Transferable)
label var intra_xfers "Dummy for transfers within the year"

// make binary variable for first time this person owns of this permit
bysort Name: egen max_yr = max(year)
bysort Name: egen min_yr = min(year)
order min_yr max_yr, after(year)
sort year Name
gen ft_owner = 0
replace ft_owner = 1 if min_yr == year
label var ft_owner "First time owner of this permit"
drop min_yr max_yr
drop owner_count
order ft_owner, after(yr_owners)


// make binary variable for last time this person owns this permit
// IN LARGER PANEL, also look at if the person ever owns other permits
bysort Name: egen max_yr = max(year)
bysort Name: egen min_yr = min(year)
order min_yr max_yr, after(year)
sort year Name
gen lt_owner = 0
replace lt_owner = 1 if max_yr == year
label var lt_owner "Last time owner of this permit"
drop min_yr max_yr
order lt_owner, after(ft_owner)
order years*, after(obs)
order year, after(PermitNumber)


// making variable cataloguing number of years straight the person has had the permit (inclusive), and another for total number of years person has had permit in the past (inclusive)

sort Name
frame put year Name, into(working)
frame change working
duplicates drop
by Name (year), sort: gen yrs_past_inclusive = _n

by Name (year): gen run = sum(year != year[_n-1] + 1)
by Name run (year), sort: gen yrs_straight = _n

frame change default
frlink m:1 year Name, frame(working)
assert `r(unmatched)' == 0
frget yrs_straight yrs_past_inclusive, from(working)
drop working

label var yrs_straight "Consecutive years person has had permit"
label var yrs_past_inclusive "Number of past years person has had permit"
sort year Name
rename (yrs_straight yrs_past_inclusive) (person_yrs_straight person_yrs_past)


***************************************************
// next step: tracking ownership across geography**
***************************************************


// making variables which give the total number of states and countries the permit goes to
qui tab State
gen states = r(r)
label var states "Total states where permit is observed"

/*
qui tab Country
gen countries = r(r)
label var countries "Total countries where permit is observed"
*/

//// first, making variables to mark consecutive number of years permit has been has been in state(inclusive), and total number of years permit has been in state (inclusive). Then, doing same thing for zips. Use these together to make next batch of vars.

sort State
frame put year State, into(working2)
frame change working2
duplicates drop
by State (year), sort: gen state_yrs_past = _n

by State (year): gen run = sum(year != year[_n-1] + 1)
by State run (year), sort: gen state_yrs_straight = _n

frame change default
frlink m:1 year State, frame(working2)
assert `r(unmatched)' == 0
frget state_yrs_straight state_yrs_past, from(working2)
drop working2

label var state_yrs_straight "Consecutive years permit has been in state"
label var state_yrs_past "Number of past years permit has been in state"
sort year State

sort ZipCode
frame put year ZipCode, into(working3)
frame change working3
duplicates drop
by ZipCode (year), sort: gen zip_yrs_past = _n

by ZipCode (year): gen run = sum(year != year[_n-1] + 1)
by ZipCode run (year), sort: gen zip_yrs_straight = _n

frame change default
frlink m:1 year ZipCode, frame(working3)
assert `r(unmatched)' == 0
frget zip_yrs_straight zip_yrs_past, from(working3)
drop working3

label var zip_yrs_straight "Consecutive years permit has been in zip"
label var zip_yrs_past "Number of past years permit has been in zip"
sort year ZipCode

// make variable to indicate that permit was not in the current state in the last yr
// Note- it is the case that in the last period, there could have been intra-state transfers and so the permit could have gone elsewhere. So this variable does not capture that.
gen inter_state_move = 0
replace inter_state_move = 1 if state_yrs_straight ==1
label var inter_state_move "Dummy - permit was not in the current state last yr"

// make variable to indicate that permit was in the same state, but in a different zip code in the last period. Denoting this an "intra-state" move.
gen intra_state_move = 0
replace intra_state_move = 1 if zip_yrs_straight ==1 & inter_state_move == 0 
label var intra_state_move "Dummy - permit was in current state but different zip last yr"


// make variable which explain whether, conditional on a move, the permit is with the same person. ie is the geographical move due to the person moving or the permit being transferred.
gen temp = inter_state_move + intra_state_move
gen person_move = 0
replace person_move = 1 if temp ==1 & person_yrs_straight >1
label var person_move "Dummy - move was due to previous holder re-sorting"
drop temp

order states /*countries*/, after(years_missing)

}

***********************************************************************
******* Section 1c: Making sumstat variables for the example permit *** 
******* Incomplete, complete with full dataset.
***********************************************************************
{

// avg continuous tenure with one person
keep year Name person_yrs_straight
sort name person_yrs_straight
collapse (max) person_yrs_straight, by(name)
egen avg_cts_tenure = mean(person_yrs_straight) // average continuous tenure with one person
gen number_owners = _N // number of separate holders

// avg total number of years with one person
keep year name person_yrs_past
sort name person_yrs_past
collapse (max) person_yrs_past, by(name)
egen avg_tot_tenure = mean(person_yrs_past) // average total tenure with one person

// number of years with intra yr transfers
keep year intra_xfers
duplicates drop
egen total_intra_xfers = sum(intra_xfers) // number of years with intra-yr transfers

// avg number of owners within an intra-transfer year
keep year name intra_xfers yr_owners
drop if intra_xfers == 0
keep year yr_owners
duplicates drop
egen avg_owners_cond_on_intra = mean(yr_owners) // avg number of owners eithin a transfer year conditional on an intra-year transfer

//making average number of years in state and average duration in state variables
keep year state state_yrs_straight
sort state year state_yrs_straight
duplicates drop
gen temp = 0
replace temp = 1 if state[_n]== state[_n-1] & year[_n]!=year[_n-1]+1
// avg total years in state
egen state_total = count(year), by(state)
collapse (mean) state_total, by(state) // total years the permit is in each state
egen avg_state_total = mean(state_total) // average years in a state
// avg duration RELOAD HERE
keep year state state_yrs_straight
sort state year state_yrs_straight
duplicates drop
gen temp = 0
replace temp = 1 if state[_n]== state[_n-1] & year[_n]!=year[_n-1]+1
// LEFT OFF HERE



}
}

***********************************************************************************
** Section 2: Data prep for mapping permit migration over time (as in Mapping.do) ** // Incomplete
***********************************************************************************
{
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear


// bookkeeping
sort PermitNumber year Seq
order PermitNumber year Seq, first
order descrip, before(catch_descrip)
order current_descrip, before(catch_current_descrip)
order hist_descrip, before(catch_hist_descrip)
order Name, before(Street)
order FirstName LastName Middle Suffix dup Transferable SeqCheckDigit, last
order Name ZipCode PermitStatus, after(Seq)
replace ZipCode = substr(ZipCode, 1,5) // replacing zip+4 codes


// exploratory analysis of cancelled permits.
// Here, I am seeing how many permits come back online after cancellation.
frames put *, into(cancelled)
frame change cancelled
gen cancel = 0
replace cancel = 1 if PermitStatus == "Permit cancelled"
bysort PermitNumber: egen sum = sum(cancel)
keep if sum > 0
sort PermitNumber year Seq
drop sum
codebook PermitNumber, compact // 26 unique permits were cancelled.
//dropping post-cancellation entries for cancelled permits
gen ind = 1
sort PermitNumber PermitStatus year
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0
sort PermitNumber year Seq
bysort PermitNumber: egen Max = max(year)
count if PermitStatus == "Permit cancelled" & year != Max // 7 of 26 cancelled permits come back online
frame change default
frames drop cancelled



// Dropping all entries for cancelled permits after they are cancelled (and in a few cases, before they are re-activated)
gen ind = 1
sort PermitNumber PermitStatus year
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0


/*
// this code tells us which permits are missing years. in sample data, it's only cancelled permits and I just dropped the years in the cancellation window in the code above
drop sum
bysort PermitNumber: egen max = max(year)
bysort PermitNumber: egen min = min(year)
gen range = max -min + 1
gen ind2 = 1
bysort PermitNumber year: replace ind2 = 0 if _n !=1
bysort PermitNumber: egen sum = sum(ind2)
tab PermitNumber if range !=sum
keep if range !=sum
*/


// making countmax variable- maximum number of yearly transfers per permit
egen countmax = max(Seq), by(PermitNumber)
order countmax, after(PermitNumber)
preserve
duplicates drop PermitNumber, force
tab countmax
restore

*********************************************************
// IN FINAL DATA, DEAL WITH MISSING ZIPCODE VALUES HERE**
*********************************************************

// Now, preparing data for mapping. 
// load initial Test_215B.dta file first
sort PermitNumber year Seq

// making lag and lead zip code variables 
gen lagZip = ZipCode[_n-1]
order lagZip, after(ZipCode)
replace lagZip = "" if PermitNumber[_n-1] != PermitNumber
gen nextZip = ZipCode[_n+1]
replace nextZip = "" if PermitNumber[_n+1] != PermitNumber
order nextZip, after(lagZip)
order lagZip, before(ZipCode)

// Decision rules: 
// If the entry and its next entry have the same name but different zip codes, this is coded as a re-sort. Some of these may be coded as permament or temporary transfers in the data, but I am making the executive decision to give owner names precedence.
// If an entry's PermitStatus is coded as "Permit holder; permanently transferred permit away" and the next entry is another person in another zip code, code this as a permanent transfer.
// If the NEXT entry's PermitStatus is coded as "Temporary holder through emergency transfer" and the next entry is another person in another zip code, code this as a temporary transfer. 

// making note of likely re-sorts labelled as permanent transfers
count if PermitStatus == "Permit holder; permanently transferred permit away" & Name[_n] == Name[_n+1] & ZipCode != nextZip & ZipCode != " " & PermitNumber[_n] == PermitNumber[_n+1] // 15 observations

// making note of likely re-sorts labelled as temporary transfers
count if PermitStatus[_n+1] == "Temporary holder through emergency transfer" & Name[_n] == Name[_n+1] & ZipCode != nextZip & ZipCode != " " & PermitNumber[_n] == PermitNumber[_n+1] // 18 observations

// making general move indicator, capturing whether a permit moves in a given entry
gen move = 0
order move, after(nextZip)
replace move = 1 if nextZip !=ZipCode & PermitNumber[_n+1] == PermitNumber

// making re-sort indicator, which catalogs if a move was due to owner re-sorting
gen re_sort = 0
order re_sort, after(move)
replace re_sort = 1 if move == 1 & Name[_n+1] ==Name

// making indicator for moves that can be attributed to a permanent transfer
gen perm_trans = 0
order perm_trans, after(nextZip)
replace perm_trans = 1 if nextZip != ZipCode & PermitStatus == "Permit holder; permanently transferred permit away" & re_sort == 0

// making indicator for moves that can be attributed to a temporary transfer
gen temp_trans = 0
order temp_trans, after(nextZip)
replace temp_trans = 1 if nextZip != ZipCode & PermitStatus[_n+1] == "Temporary holder through emergency transfer" & re_sort == 0

// there are a few entries that are denoted both temporary and permanent transfers, because the entry's PermitStatus is PermTrans but the next status is TempTrans
count if temp_trans == 1 & perm_trans == 1 // 31
count if temp_trans == 1 & perm_trans == 1 & Name[_n+1] == Name[_n+2] // 28. These are likely mislabelled permanent transfers. That's what I'm deciding.
replace temp_trans = 0 if temp_trans == 1 & perm_trans == 1 & Name[_n+1] == Name[_n+2]

// defining a "transfer back" variable
tab PermitStatus if move == 1 & re_sort == 0 & temp_trans == 0 & perm_trans == 0
gen trans_back = 0
order trans_back, after(temp_trans)
replace trans_back = 1 if move == 1 & re_sort == 0 & temp_trans == 0 & perm_trans == 0 & PermitStatus == "Temporary holder through emergency transfer" & Name[_n-1] == Name[_n+1] & Name[_n] != Name[_n+1]  & PermitNumber[_n] == PermitNumber[_n+1]

// inter-year move indicator
gen inter_year = 0
order inter_year, after(move)
replace inter_year = 1 if move == 1 & year[_n+1] != year

// intra-year move indicator
gen intra_year = 0
order intra_year, after(inter_year)
replace intra_year = 1 if move == 1 & year[_n+1] == year
count if move == 1 & inter_year == 0 & intra_year == 0 // none. great

// which moves are left unaccounted for/ not explained so far?
count if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 // 20 obs
codebook PermitNumber if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 // 19 permits.

gen sum = re_sort + temp_trans + perm_trans + trans_back
tab sum // most are 0 (no transfer) or 1 (some form of transfer), but 3 are 2. 
frames put *, into(new)
frame change new
keep if sum == 2
frame change default
frame drop new


// dealing with cancellations
codebook PermitNumber if PermitStatus == "Permit cancelled" // 26 permits
count if PermitStatus == "Permit cancelled" & PermitNumber[_n+1] == PermitNumber // 7 permits were reinstated.
count if PermitStatus == "Permit cancelled" & PermitNumber[_n+1] == PermitNumber & year[_n+1] == year[_n]+1 // 4 of the reinstated permits were reinstated the next year


// making an indicator for a permit's reinstatement, plus a variable capturing how long it was cancelled
gen year_reinstated = 0
order year_reinstated, after(perm_trans)
replace year_reinstated = 1 if PermitStatus[_n-1] == "Permit cancelled" & PermitNumber[_n-1] == PermitNumber
gen years_cancelled = 0
order years_cancelled, after(year_reinstated)
replace years_cancelled = year - year[_n-1] if year_reinstated == 1


// abstract from unaccounted-for moves for now, as well as the three moves which are still coded as both temporary and permanent. Come back and deal with this with final data, as well as earlier missing zipcodes. Here, no permits (besides the 3 cancellation cases which were now immediately reinstated) are missing years. COme back and check this on full data.
sort PermitNumber year Seq
keep if move == 1
keep PermitNumber year Seq ZipCode nextZip move inter_year intra_year re_sort temp_trans trans_back perm_trans year_reinstated years_cancelled
rename (ZipCode nextZip) (start_zip end_zip)
sort year start_zip end_zip
count if start_zip == end_zip // sould be 0. good.
duplicates list year start_zip end_zip
count if start_zip == " " | end_zip == " " // 10. Why are these here? Just missing?

foreach x in move re_sort intra_year inter_year temp_trans perm_trans trans_back year_reinstated {
	bysort year start_zip end_zip: egen sum = sum(`x')
	rename sum number_`x'
}

gen ind = 1
bysort PermitNumber year start_zip end_zip: replace ind = 0 if _n >1
bysort year start_zip end_zip: egen sum = sum(ind)
drop ind
rename sum number_permits

bysort year start_zip end_zip: keep if _n ==1
drop PermitNumber Seq move intra_year inter_year re_sort temp_trans perm_trans trans_back year_reinstated years_cancelled number_year_reinstated

// making summary variables
order number_re_sort, before(number_temp_trans)
//checking whether intra and inter sum to the total number of moves (they do)
gen sum = number_move - number_intra_year - number_inter_year
//checking whether move types sum to the total number of moves (they mostly do but 23 do not due to the above issues which I am goign to rectify)
gen sum2 = number_move - number_re_sort - number_temp_trans - number_perm_trans - number_trans_back
}

***********************************************************************************
** Section 3: Making net migration flows for r mapping (ie in mapping.do\        **
** There is still a lot of work to do here                                       **
***********************************************************************************
{
// start from the work in Section 2

drop if start_zip ==" " | end_zip == " "
count if start_zip == end_zip // 0

// merging
destring start_zip end_zip, replace

// trying merge with stanford dataset
rename start_zip zip
merge m:m zip using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Zip Coordinates Data\StanfordPHSZips.dta"
drop if _merge == 2
drop _merge geopoint daylight_savings_time_flag timezone state city
rename zip start_zip
rename (latitude longitude) (start_lat start_lgt)
rename end_zip zip	
merge m:m zip using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Zip Coordinates Data\StanfordPHSZips.dta"
drop if _merge == 2
drop _merge geopoint daylight_savings_time_flag timezone state city
rename zip end_zip
rename (latitude longitude) (end_lat end_lgt)
sort year

count if start_lat == . | end_lat == . | start_lgt == . | end_lgt == . // 83 out of 5608
drop if start_lat == . | end_lat == . | start_lgt == . | end_lgt == . // for now, just for mapping
sort year

preserve
egen outflow = sum(number_permits), by(start_zip)
collapse (mean) outflow, by(start_zip)
rename start_zip zip
save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\S15B_outflows.dta", replace
restore

preserve
egen inflow = sum(number_permits), by(end_zip)
collapse (mean) inflow, by(end_zip)
rename end_zip zip
save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\S15B_inflows.dta", replace
restore

use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\S15B_outflows.dta", clear

merge m:m zip using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\S15B_inflows.dta"

replace outflow = 0 if outflow == .
replace inflow = 0 if inflow == .
drop _merge
gen net = inflow- outflow
egen test = sum(net) // it's 0! Sick!
drop test

gen sign = ""
replace sign = "Neg" if net < 0
replace sign = "Pos" if net > 0
replace sign = "Zero" if net == 0

gen absval_net = abs(net)

merge 1:m zip using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Zip Coordinates Data\StanfordPHSZips.dta"
drop if _merge == 2
drop geopoint daylight_savings_time_flag timezone _merge
rename (latitude longitude) (latit longit)

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\S15B_net.dta", replace

// making flows dataset. here, rerun section 2 and start from there.
clear
sort start_zip end_zip
collapse (sum) number*, by(start_zip end_zip)
drop if start_zip ==" " | end_zip == " "
destring start_zip end_zip, replace

// grouping combinations of zip codes
gen zipcombo1 = min(start_zip, end_zip) 
gen zipcombo2 = max(start_zip, end_zip) 
egen zip_combo_id = group(zipcombo1 zipcombo2), label 
sort zip_combo_id
egen count = count(_n), by(zip_combo_id)

gen net_importer = 0
replace net_importer = end_zip if count == 1

bysort zip_combo_id: egen max = max(number_permits)
bysort zip_combo_id: egen min = min(number_permits)
replace net_importer = 411 if max == min & count > 1 // identifier for zero net transfers
replace net_importer = end_zip if max == number_permits & net_importer != 411
replace net_importer = start_zip if net_importer == 0

gen net_exporter = 0
order net_exporter, after(net_importer)
replace net_exporter = net_importer if net_importer == 411
replace net_exporter = start_zip if net_importer == end_zip
replace net_exporter = end_zip if net_exporter == 0

gen net_transfers = max - min
bysort zip_combo_id: egen trading_volume = sum(number_permits)

// here, we can do something with intra, inter, re-sorts later. for now, abstracting away from this. ideas: Look at total re_sorts. Note: find how many unique permits went between each zip combo

collapse (mean) zipcombo1 zipcombo2 count net_importer net_exporter max min net_transfers trading_volume, by(zip_combo_id)

rename (zipcombo1 zipcombo2) (zip1 zip2)
rename (max min) (imports exports)

// merging zips back on
rename zip1 zip
merge m:m zip using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Zip Coordinates Data\StanfordPHSZips.dta"
drop if _merge ==2
drop _merge geopoint daylight_savings_time_flag timezone 
rename (zip latitude longitude state city) (zip1 zip1_lat zip1_lon state1 city1)
rename zip2 zip
merge m:m zip using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Zip Coordinates Data\StanfordPHSZips.dta"
drop if _merge ==2
drop _merge geopoint daylight_savings_time_flag timezone 
rename (zip latitude longitude state city) (zip2 zip2_lat zip2_lon state2 city2)
sort zip_combo_id

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Trial Run Migration Flows\S04W_flows.dta", replace


// Now: make map with color of dots indicating sign, size indicating volume of net flows, arc size indicating trading volume, tooltip indicating direction of net flows between individual zips.

}

// These sections (4 & 5) are done for 215B
{
***********************************************************************************
** Section 4: Making permit-level origin-dest dataset for entire 1975-24 period  **
** DONE for 215B      
***********************************************************************************
{

// Start this from full panel of permits
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear


sort PermitNumber PermitStatus year

// Dropping all entries for permits after they are cancelled 
gen ind = 1
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0

egen Min = min(year), by(PermitNumber)
egen Max = max(year), by(PermitNumber)
order Min Max, after(year)
order ZipCode, after(fishery)
sort fishery PermitNumber year Seq
order fishery PermitNumber year Min Max ZipCode PermitType PermitStatus Seq Name, first

// catalog number of owners, number of zips prior to collapsing
drop ind
gen ind = 1
order ind, after(ZipCode)
bysort PermitNumber ZipCode: replace ind = 0 if _n !=1
egen number_zips = sum(ind), by(PermitNumber)
order number_zips, after(ZipCode)
drop ind
gen ind = 1
order ind, after(Name)
bysort PermitNumber Name: replace ind = 0 if _n !=1
egen number_owners = sum(ind), by(PermitNumber)
order number_owners, after(number_zips)
drop ind

keep if year == Min | year == Max
sort fishery PermitNumber year Seq

// dropping permits which do not have a first or last year because these year observations had blank zip codes and were dropped 
tab ZipCode, mi // none for the example permit. come back to this. 
/*
gen ind = 1
bysort permitnumber year: replace ind = 0 if _n !=1
bysort permitnumber: egen firstlast = sum(ind)
tab firstlast
codebook permitnumber if firstlast ==1 // 29 permits
drop if firstlast == 1
drop firstlast ind
*/

// seeing how many zip codes we have within the first and last year of each permit
gen ind = 1
order ind, after(ZipCode)
bysort PermitNumber ZipCode: replace ind = 0 if _n !=1
egen zips_firstlast = sum(ind), by(PermitNumber)
order zips_firstlast, after(ZipCode)
drop ind
preserve
bysort PermitNumber: keep if _n ==1
tab zips_firstlast
restore // takeaway: 99 percent of permits have <= 3 zipcodes in their first and last years. 0.31% have 4
sort PermitNumber year Seq

// Getting rid of first-year observations not associated with the first holder in that year
drop if year == Min & Seq > 1

// Getting rid of last-year observations not associated with the last holder in that year
bysort PermitNumber year: egen max_seq = max(Seq)
drop if year == Max & Seq != max_seq 
drop max_seq
sort PermitNumber year

// Assigning first observed zip to each permit
gen first_zip = .
order first_zip, after(ZipCode)
destring ZipCode first_zip, replace
replace first_zip = ZipCode if year == Min 
replace first_zip = 0 if first_zip == .
egen sum = sum(first_zip), by(PermitNumber)
tab sum if year == Min // None are zero. Great!
sort PermitNumber year
bysort PermitNumber: egen fz_max = max(first_zip)
order fz_max, after(first_zip)
drop first_zip
rename fz_max first_zip

// Assigning last observed zip to each permit
gen last_zip = .
order last_zip, after(ZipCode)
replace last_zip = ZipCode if year == Max 
replace last_zip = 0 if last_zip == .
drop sum
egen sum = sum(last_zip), by(PermitNumber)
tab sum if year == Max // None are zero. Great!
sort PermitNumber year
order last_zip, after(first_zip)
bysort PermitNumber: egen lz_max = max(last_zip)
order lz_max, after(last_zip)
drop last_zip
rename lz_max last_zip
sort PermitNumber year
duplicates drop PermitNumber, force

// dropping unnecessary vars and cleaning up
drop year ZipCode Seq Name PermitStatus SeqCheckDigit StartDate EndDate LastName FirstName Middle Suffix Street City State ForeignAddress Residency sum
rename (Min Max) (first_yr last_yr)
codebook PermitNumber, compact
bysort PermitNumber: egen fz = sum(first_zip)
bysort PermitNumber: egen lz = sum(last_zip)
order fz lz, after(last_zip)
duplicates drop PermitNumber fz lz, force // 0 are duplicates.
drop first_zip last_zip
rename (fz lz) (first_zip last_zip)
gen nomove = 0
replace nomove = 1 if first_zip == last_zip
order nomove, after(last_zip)
sort fishery

// Merging coordinates on for mapping
destring first_zip last_zip, replace
rename first_zip zip
merge m:m zip using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Zip Coordinates Data\StanfordPHSZips.dta"
drop if _merge == 2
sort _merge // 4 permits not matched. dropping 
drop if _merge == 1
drop _merge geopoint daylight_savings_time_flag timezone state city
rename zip first_zip
rename (latitude longitude) (first_lat first_lgt)
rename last_zip zip	
merge m:m zip using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Zip Coordinates Data\StanfordPHSZips.dta"
drop if _merge == 2
sort _merge // 2 permits not matched. dropping 
drop if _merge == 1
drop _merge geopoint daylight_savings_time_flag timezone state city
rename zip last_zip
rename (latitude longitude) (last_lat last_lgt)
sort fishery
order first_lgt first_lat last_lgt last_lat, after(last_zip)
gen net_move = 1 - nomove
drop nomove


// creating final set of variables
gen stat_zips = 0
replace stat_zips = 1 if number_zips == 1
order stat_zips, after(number_zips)
gen stat_owners = 0
replace stat_owners = 1 if number_owners == 1
order stat_owners, after(number_owners)
gen stat_all = 0
replace stat_all = 1 if stat_owners == 1 & stat_zips == 1
order stat_all, after(stat_owners)
gen range = last_yr - first_yr + 1
order range, after(last_yr)
}

***********************************************************************************
** Section 5: Making the inputs for an area chart which shows how many permits   **
** exist in the system at any give time.                                         **
** DONE for 215B      
***********************************************************************************
{
// Start this from full panel of permits
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear

// Dropping all entries for permits after they are cancelled 
drop if PermitStatus == "Permit cancelled"
duplicates drop PermitNumber year, force

// Making area map counts by year (break this up by catch/region/etc in final version)
bysort year: egen Permits_in_Yr = count(_n)
duplicates drop year, force

twoway line Permits_in_Yr year
}
}