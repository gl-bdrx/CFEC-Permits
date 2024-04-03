// Do-file to transform scraped spreadsheets from CFEC into a panel dataset of permanent permits, and other related data.

// Upon opening, use the built-in code-folding to collapse sections for better organization and ease of use. Unfortunately, Stata likes to open do files with all the code unfolded.

// Author: Greg Boudreaux
// Date: 2024

// Datasets this do-file creates:
//// Section 0 creates FullPermitData.dta      (Raw data for all permits)
//// Section 1 creates PermanentPermitData.dta (Panel of permanent permits)  
//// Section 2 creates YearlyMoves.dta         (Dataset of moves by year-zip combo)
//// Section 3 creates Permanent_net.dta       (Zip-level net permit migration data)
//// Section 4 creates OriginDestination.dta   (Origin-destination data for each permit)
//// Section 5 creates figures and summary statistics.

// Input data needed, which is all in sub-folders of the repository:
//// Raw CFEC permit-year data, in .xls format, located in the "Raw Data" folder.
//// Fishery Identifier codes from CFEC: 
//// --- "Misc Permit Data from CFEC\Permit Identifier Codes\Current and Hist CFEC codes 2023.csv"
//// --- "Misc Permit Data from CFEC\Permit Identifier Codes\Current CFEC codes 2023.csv"
//// Zip-level demographic data: 
//// --- "Zipcodes.dta"

// Set directory here 
global path "C:/Users/gboud/Dropbox/Reimer GSR/CFEC_permits/CFEC Data Work"
cd "$path"

***********************************************************************************
** Section 0: Preliminaries                                                      **
** This section appends the raw Excel files and converts them to .dta format.    **
***********************************************************************************
{
// four directories where permits live: 

// Raw Data\ErrorCausingFisheries
// Raw Data\FisherySpreadsheets_AthruR\Fishery spreadsheets
// Raw Data\FisherySpreadsheets_SthruZ\Fishery spreadsheets
// Raw Data\Errors\Errors

// looping through the first three directories and saving all files as .dta files

local subfolders `""ErrorCausingFisheries" "FisherySpreadsheetsGB_AthruR\Fishery spreadsheets" "FisherySpreadsheetsJR_SthruZ\Fishery spreadsheets""'

foreach folder of local subfolders {
	
	cd "$path/Raw Data/`folder'"

	local files: dir . files "*.xls"
	foreach file in `files' {
		clear 
		import excel "`file'", sheet("Permits") firstrow clear
		// drop in 1
		local year = Year[2]
		local fishery = Fishery[2]
		di `year'
		di "`fishery'"
		
		save "$path/FinalFisheries/`fishery'_`year'.dta", replace
}
}


// looping through the errors fishery-year files and saving as .dta files, appending all .dta files, dropping duplicates, and saving to FinalFisheries folder.

cd "$path/Raw Data/Errors/Errors"

local files: dir . files "*.xls"
foreach file in `files' {
	clear 
	import excel "`file'", sheet("Permits") firstrow clear
	local year = Year[2]
	local fishery = Fishery[2]
	di `year'
	di "`fishery'"
	
	save "`file'.dta", replace
}

local files: dir . files "*.dta"
clear
append using `files', force
duplicates drop // just checking
drop if Year == ""
save "$path/FinalFisheries/Error_Fishery_Yrs.dta", replace

// appending all .dta files, getting rid of blank first rows from CFEC query tool

cd "$path/FinalFisheries"
local files: dir . files "*.dta"
clear
append using `files', force
duplicates drop 
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

// Saving full data
save "$path/FullPermitData.dta", replace 

// keeping only permanent permits 
keep if PermitType == "Permanent"
codebook Fishery, compact
tab Fishery

// saving permanent permit data
save "$path/PermanentPermitData.dta", replace  
}

***********************************************************************************
** Section 1: Cleaning, making descriptive variables, and saving permit panel.   **
** Saved as PermanentPermitData.dta                                              **
***********************************************************************************
{
**********************************************************************
******* Section 1a. Some exploratory analysis and further cleaning. **
**********************************************************************
{
	
cd "$path"

// Starting from permanent permit data.
use "$path/PermanentPermitData.dta", clear
sort PermitNumber Year Seq 
order PermitNumber Year Seq, first

// generating duplicates to get a good grasp on how many multiple-year permits I have

duplicates tag PermitNumber, generate(dup)
gen dup2 = dup+1
drop dup
rename dup2 dup
label var dup "Number of times permit appears in panel"
replace Name = strtrim(Name) // removing trailing spaces

// Replacing ForeignAddress variable to better organize countries in the data

{
replace ForeignAddress = "USA" if ustrpos(ForeignAddress, "AK")>0
replace ForeignAddress = "USA" if ustrpos(ForeignAddress, "ALASKA")>0
replace ForeignAddress = "USA" if ustrpos(ForeignAddress, "FISHERMANS TERMINAL")>0 // WA
replace ForeignAddress = "CANADA" if ustrpos(ForeignAddress, "CANADA")>0
replace ForeignAddress = "CANADA" if ustrpos(ForeignAddress, "BC")>0
replace ForeignAddress = "CANADA" if ustrpos(ForeignAddress, "B.C.")>0
replace ForeignAddress = "CANADA" if ustrpos(ForeignAddress, "ONTARIO")>0
replace ForeignAddress = "CANADA" if ustrpos(ForeignAddress, "ALBERTA")>0
replace ForeignAddress = "CANADA" if ustrpos(ForeignAddress, "AB")>0
replace ForeignAddress = "CANADA" if ustrpos(ForeignAddress, "PT HARDY")>0
replace ForeignAddress = "ENGLAND" if ustrpos(ForeignAddress, "ENGLAND")>0
replace ForeignAddress = "ENGLAND" if ustrpos(ForeignAddress, "LONDON")>0
replace ForeignAddress = "SWITZERLAND" if ustrpos(ForeignAddress, "SWITZERLAND")>0
replace ForeignAddress = "VIRGIN ISLANDS" if ustrpos(ForeignAddress, "VIRGIN ISLANDS")>0
replace ForeignAddress = "VIRGIN ISLANDS" if ustrpos(ForeignAddress, "SAINT JOHN")>0
replace ForeignAddress = "VIRGIN ISLANDS" if ustrpos(ForeignAddress, "VI")>0
replace ForeignAddress = "ISRAEL" if ustrpos(ForeignAddress, "ISRAEL")>0
replace ForeignAddress = "GERMANY" if ustrpos(ForeignAddress, "GERMANY")>0
replace ForeignAddress = "NORWAY" if ustrpos(ForeignAddress, "NORWAY")>0
replace ForeignAddress = "NEW ZEALAND" if ustrpos(ForeignAddress, "NEW ZEALAND")>0
replace ForeignAddress = "SWEDEN" if ustrpos(ForeignAddress, "SWEDEN")>0
replace ForeignAddress = "AUSTRALIA" if ustrpos(ForeignAddress, "AUSTRAILA")>0
replace ForeignAddress = "AUSTRALIA" if ustrpos(ForeignAddress, "NSW")>0
replace ForeignAddress = "PANAMA" if ustrpos(ForeignAddress, "PANAMA")>0
replace ForeignAddress = "GUAM" if ustrpos(ForeignAddress, "GUAM")>0
replace ForeignAddress = "MILITARY BASE" if ustrpos(ForeignAddress, "APO")>0
replace ForeignAddress = "MILITARY BASE" if ustrpos(ForeignAddress, "FPO")>0
replace ForeignAddress = "MILITARY BASE" if ustrpos(ForeignAddress, "AE")>0
replace ForeignAddress = "PHILIPPINES" if ustrpos(ForeignAddress, "PHILLIPPINES")>0
replace ForeignAddress = "ITALY" if ustrpos(ForeignAddress, "ITALY")>0
replace ForeignAddress = "MEXICO" if ustrpos(ForeignAddress, "PUERTO VALLARTA")>0
replace ForeignAddress = "UK" if ustrpos(ForeignAddress, "UK")>0
replace ForeignAddress = "UK" if ustrpos(ForeignAddress, "UNITED KINGDOM")>0
replace ForeignAddress = "UK" if ForeignAddress =="ENGLAND"
replace ForeignAddress = "GREECE" if ustrpos(ForeignAddress, "GREECE")>0
replace ForeignAddress = "COSTA RICA" if ustrpos(ForeignAddress, "COSTA RICA")>0
replace ForeignAddress = "IRELAND" if ustrpos(ForeignAddress, "IRELAND")>0
replace ForeignAddress = "JAPAN" if ustrpos(ForeignAddress, "JAPAN")>0
tab state if ForeignAddress ==""
replace ForeignAddress = "GUAM" if state == "GU"
replace ForeignAddress = "USA" if ForeignAddress ==" "
tab ForeignAddress

}


save "$path/PermanentPermitData.dta", replace

// Merging on current and historical fishery descriptions from CFEC.
// These merge on by fishery-year.

// First, opening CFEC historical fisheries codes and cleaning.

import delimited "$path/Misc Permit Data from CFEC/Permit Identifier Codes/Current and Hist CFEC codes 2023.csv",varnames(1) clear 
replace fishery = subinstr(fishery, " ", "", .)
split years, parse(" - ") gen(yr) destring
gen `c(obs_t)' obs_no = _n
expand yr2-yr1+1
by obs_no (yr1), sort: gen year = yr1[1] + _n - 1, after(years)
drop yr*
drop obs_no years
save "$path/Misc Permit Data from CFEC/Permit Identifier Codes/CleanedHistoricalCurrentFisheries.dta", replace

// Opening permit data and merging historical fishery identifiers on.

use "$path/PermanentPermitData.dta", clear
rename (Year Fishery) (year fishery)
merge m:1 year fishery using "$path\Misc Permit Data from CFEC\Permit Identifier Codes\CleanedHistoricalCurrentFisheries.dta"
drop if _merge ==2
save "$path/PermanentPermitData.dta", replace

// Opening the current fisheries identifiers from CFEC, and cleaning. 
 
import delimited "$path/Misc Permit Data from CFEC/Permit Identifier Codes/Current CFEC codes 2023.csv",varnames(1) clear
replace fishery = subinstr(fishery, " ", "", .)
drop status
save "$path/Misc Permit Data from CFEC/Permit Identifier Codes/CleanedCurrentFisheries.dta", replace

// Opening permit data and merging current fishery identifiers on.

use "$path/PermanentPermitData.dta", clear

rename _merge orig_merge
merge m:1 fishery using "$path\Misc Permit Data from CFEC\Permit Identifier Codes\CleanedCurrentFisheries.dta"
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
save "$path/PermanentPermitData.dta", replace

// The fishery identifiers are one string, for example "SALMON, DRIFT GILLNET, SE"
// Here, I split fishery identifiers to be able to sort by catch/gear/region.

use "$path/PermanentPermitData.dta", clear


// Starting with the native description to the permit data.

split descrip, gen(descrip) parse(", ")
tab descrip1
rename descrip1 catch_descrip
label var catch_descrip "Catch description from permit data"
tab catch_descrip
tab descrip2
rename descrip2 gear_descrip 
label var gear_descrip "Gear description from permit data"
tab descrip3 // there are a few entries that are still gear
// remaking variables that have gear in the location variable 
replace gear_descrip = gear_descrip + ", " + descrip3 if descrip3 == "FIXED VL LENGTH TO 60 FEET" | descrip3 == "FIXED VL LENGTH TO 70 FEET" | descrip3 == "FIXED VL LENGTH TO 75 FEET" 
// cleaning and renaming location variable
tab descrip3
replace descrip3 = descrip4 if descrip3 =="FIXED VL LENGTH TO 60 FEET"
replace descrip3 = descrip4 if descrip3 =="FIXED VL LENGTH TO 70 FEET"
replace descrip3 = descrip4 if descrip3 =="FIXED VL LENGTH TO 75 FEET"
rename descrip3 location_descrip
label var location_descrip "Location from permit data"
drop descrip4

// Now, moving to the current description from the CFEC site.

split current_descrip, gen(current_descrip) parse(", ")
tab current_descrip1
tab current_descrip2
tab current_descrip3
tab current_descrip4 // kodiak
replace current_descrip2 = current_descrip2 + ", " + current_descrip3 if current_descrip4 == "KODIAK"
replace current_descrip3 = current_descrip4 if current_descrip4 == "KODIAK"
replace current_descrip4 = "" if current_descrip4 == "KODIAK"
rename (current_descrip1 current_descrip2 current_descrip3) (catch_current_descrip gear_current_descrip location_current_descrip) 
replace catch_current_descrip = trim(catch_current_descrip)
label var catch_current_descrip "Current catch description from CFEC site"
label var gear_current_descrip "Current gear description from CFEC site"
label var location_current_descrip "Current location from CFEC site"
drop current_descrip4

// Finally, the historical description from the CFEC site.

split hist_descrip, gen(hist_descrip) parse(", ")
tab hist_descrip4 // KODIAK 
replace hist_descrip2 = hist_descrip2 + ", " + hist_descrip3 if hist_descrip4 == "KODIAK"
replace hist_descrip3 = hist_descrip4 if hist_descrip4 == "KODIAK"
replace hist_descrip4 = "" if hist_descrip4 == "KODIAK"
rename (hist_descrip1 hist_descrip2 hist_descrip3 /*hist_descrip4*/) (catch_hist_descrip gear_hist_descrip location_hist_descrip /*misc_hist_descrip*/) 
drop hist_descrip4
replace catch_hist_descrip = trim(catch_hist_descrip)
label var catch_hist_descrip "Hist catch description from CFEC site"
label var gear_hist_descrip "Hist gear description from CFEC site"
label var location_hist_descrip "Hist location from CFEC site"

save "$path/PermanentPermitData.dta", replace

}

**********************************************************************
******* Section 1b. Making descriptive variables, saving panel.     **
**********************************************************************
{

frames reset
use "$path/PermanentPermitData.dta", clear

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

// generating descriptive yearly variables 

// variable which records permit records per year (unique within year)
bysort PermitNumber year: egen yearly_count = count(year), // tagging years in which permits shows up multiple times
label var yearly_count "Permit Entries Per Year"

// variable which records range of time permit is in database (unique to permit)
bysort PermitNumber: egen max = max(year)
bysort PermitNumber: egen min = min(year)
gen years_range = max-min+1
order years_range, after(year)
label var years_range "Range of time permit is in database"
drop max min

// number of years in which permit is explicitly observed
gen tag = 0
bysort PermitNumber year: replace tag = 1 if _n==1
bysort PermitNumber: egen years_observed = sum(tag)
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

// tagging and tracking changes in ownership across and within years. 

// variable tracking # of times owner shows up in each year (unique by owner-year)
bysort PermitNumber year: egen owner_count = count(Name)
duplicates tag PermitNumber year Name, generate(within_yr_dup_owners)
sort PermitNumber year Name
order within_yr_dup_owners, after(yearly_count)
rename within_yr_dup_owners temp
gen within_yr_dup_owners = temp+1
order within_yr_dup_owners, after(Name)
label var within_yr_dup_owners "Times owner shows up within year"
drop temp

// variable tracking # of unique owners in each year (unique by year)
duplicates tag PermitNumber year Name, generate(temp)
bysort PermitNumber year Name: replace temp = 1 if _n==1
bysort PermitNumber year Name: replace temp = 0 if _n!=1
order temp, after( within_yr_dup_owners)
bysort PermitNumber year: egen yr_owners = sum (temp)
order yr_owners, after(temp)
label var yr_owners "Number of owners in the year"
drop temp

// binary variable indicating the presence of intra year transfers w/i that year
gen intra_xfers = 0
replace intra_xfers = 1 if yr_owners > 1
order intra_xfers, after(Transferable)
label var intra_xfers "Dummy for transfers within the year"

// binary variable indicating this is the first time this person owns this permit
bysort PermitNumber Name: egen max_yr = max(year)
bysort PermitNumber Name: egen min_yr = min(year)
order min_yr max_yr, after(year)
sort PermitNumber year Name
gen ft_owner = 0
replace ft_owner = 1 if min_yr == year
label var ft_owner "First time owner of this permit"
drop min_yr max_yr
drop owner_count
order ft_owner, after(yr_owners)

// binary variable indicating this is the last time this person owns this permit
bysort PermitNumber Name: egen max_yr = max(year)
bysort PermitNumber Name: egen min_yr = min(year)
order min_yr max_yr, after(year)
sort PermitNumber year Name
gen lt_owner = 0
replace lt_owner = 1 if max_yr == year
label var lt_owner "Last time owner of this permit"
drop min_yr max_yr
order lt_owner, after(ft_owner)
order years*, after(obs)
order year, after(PermitNumber)


// making variable cataloguing number of years straight the person has had the permit (inclusive), and another for total number of years person has had permit in the past (inclusive)
sort PermitNumber Name
frame put PermitNumber year Name, into(working)
frame change working
duplicates drop
by PermitNumber Name (year), sort: gen yrs_past_inclusive = _n
by PermitNumber Name (year): gen run = sum(year != year[_n-1] + 1)
by PermitNumber Name run (year), sort: gen yrs_straight = _n

frame change default
frlink m:1 PermitNumber year Name, frame(working)
assert `r(unmatched)' == 0
frget yrs_straight yrs_past_inclusive, from(working)
drop working

label var yrs_straight "Consecutive years person has had permit"
label var yrs_past_inclusive "Number of past years person has had permit"
sort PermitNumber year Name
rename (yrs_straight yrs_past_inclusive) (person_yrs_straight person_yrs_past)

// next step: tracking ownership across geography

// variables which give the total number of states and countries the permit goes to
gen dummy = 0
bysort PermitNumber State: replace dummy = 1 if _n ==1
bysort PermitNumber: egen states = sum(dummy)
label var states "Total states where permit is observed"
drop dummy

gen dummy = 0
bysort PermitNumber ForeignAddress: replace dummy = 1 if _n ==1
bysort PermitNumber: egen countries = sum(dummy)
label var countries "Total countries where permit is observed"
drop dummy

//// first, making variables to mark consecutive number of years permit has been has been in state(inclusive), and total number of years permit has been in state (inclusive). Then, doing same thing for zips. Use these together to make next batch of variables. 

frame drop working
sort PermitNumber State
frame put year PermitNumber State, into(working)
frame change working
duplicates drop
by PermitNumber State (year), sort: gen state_yrs_past = _n
by PermitNumber State (year): gen run = sum(year != year[_n-1] + 1)
by PermitNumber State run (year), sort: gen state_yrs_straight = _n

frame change default
frlink m:1 year PermitNumber State, frame(working)
assert `r(unmatched)' == 0
frget state_yrs_straight state_yrs_past, from(working)
frame drop working

label var state_yrs_straight "Consecutive years permit has been in state"
label var state_yrs_past "Number of past years permit has been in state"
sort PermitNumber year State

sort PermitNumber ZipCode
frame put year PermitNumber ZipCode, into(working)
frame change working
duplicates drop
by PermitNumber ZipCode (year), sort: gen zip_yrs_past = _n
by PermitNumber ZipCode (year): gen run = sum(year != year[_n-1] + 1)
by PermitNumber ZipCode run (year), sort: gen zip_yrs_straight = _n

frame change default
drop working
frlink m:1 year PermitNumber ZipCode, frame(working)
assert `r(unmatched)' == 0
frget zip_yrs_straight zip_yrs_past, from(working)
frame drop working
drop working

label var zip_yrs_straight "Consecutive years permit has been in zip"
label var zip_yrs_past "Number of past years permit has been in zip"
sort PermitNumber year ZipCode

// making var indicating that permit was not in the current state in the last yr
// Note- it is the case that in the last period, there could have been intra-state transfers and so the permit could have gone elsewhere. So this variable does not capture that.
sort PermitNumber year Seq
gen inter_state_move = 0
bysort PermitNumber: egen min = min(year)
replace inter_state_move = 1 if state_yrs_straight ==1 & year != min
label var inter_state_move "Dummy - permit was not in the current state last yr"

// making variable to indicate that permit was in the same state, but in a different zip code in the last period. Denoting this an "intra-state" move.
drop intra_state_move
gen intra_state_move = 0
replace intra_state_move = 1 if zip_yrs_straight ==1 & inter_state_move == 0 & year != min
label var intra_state_move "Dummy - permit was in current state but different zip last yr"

// making variable which explain whether, conditional on a move, the permit is with the same person. ie is the geographical move due to the person moving or the permit being transferred.
gen temp = inter_state_move + intra_state_move
gen person_move = 0
replace person_move = 1 if temp ==1 & person_yrs_straight >1
label var person_move "Dummy - move was due to previous holder re-sorting"
drop temp

}

// Saving Permit Panel.
save "$path/PermanentPermitData.dta", replace

}

***********************************************************************************
** Section 2: Making a dataset of all moves, by year and start-end zip combos.   **
** This organizes moves temporally (intra- or inter year) and by type (sorting/  **
** temporary, permanent etc). This can be used to make migration maps in R.      **
** Saved as YearlyMoves.dta                                                      **
***********************************************************************************
{
	
cd "$path"

// Starting from permit panel
use "$path/PermanentPermitData.dta", clear


// bookkeeping
sort PermitNumber year Seq
order PermitNumber year Seq, first
order descrip, before(catch_descrip)
order current_descrip, before(catch_current_descrip)
order hist_descrip, before(catch_hist_descrip)
order Name, before(Street)
order FirstName LastName Middle Suffix Transferable SeqCheckDigit, last
order Name ZipCode PermitStatus, after(Seq)
replace ZipCode = substr(ZipCode, 1,5) // replacing zip+4 codes


// exploratory analysis of cancelled permits.

// Checking how many permits come back online after cancellation.
frames put *, into(cancelled)
frame change cancelled
gen cancel = 0
replace cancel = 1 if PermitStatus == "Permit cancelled"
bysort PermitNumber: egen sum = sum(cancel)
keep if sum > 0
sort PermitNumber year Seq
drop sum
codebook PermitNumber, compact // 3186 unique permits were cancelled.

// Seeing how many cancelled permits come back online, and returning to data.
// Summary: 337 of 3186 cancelled permits come back online 
gen ind = 1
sort PermitNumber PermitStatus year
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0
sort PermitNumber year Seq
bysort PermitNumber: egen Max = max(year)
count if PermitStatus == "Permit cancelled" & year != Max 
codebook PermitNumber if PermitStatus == "Permit cancelled" & year != Max // 337
frame change default
frames drop cancelled

// Dropping all entries for cancelled permits after they are cancelled (and in a few cases, before they are re-activated)
gen ind = 1
sort PermitNumber PermitStatus year
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0

// This code tells us which permits are missing years. 247 permits are missing years. all of these are ones which were cancelled. 
// Summary: 3186 permits cancelled. 337 came back online. Of these, 247 took more than a year. 90 came back online the next year. 
bysort PermitNumber: egen max = max(year)
bysort PermitNumber: egen min = min(year)
gen range = max -min + 1
gen ind2 = 1
bysort PermitNumber year: replace ind2 = 0 if _n !=1
bysort PermitNumber: egen sum = sum(ind2)
gen cancelled = 0
replace cancelled = 1 if PermitStatus == "Permit cancelled"
bysort PermitNumber: egen sumcan = sum(cancelled)
codebook PermitNumber if range !=sum // 247 permits are missing years.
codebook PermitNumber if sumcan > 0 // 3186 permits were cancelled.
codebook PermitNumber if range !=sum & sumcan > 0 // 247 permits took > 1 yr to return after cancellation.
drop range ind2 sum cancelled sumcan max min


// making countmax variable- maximum number of yearly transfers per permit
// Summary: 95% of permits have less than or equal to 4 maximum yearly entries. 
egen countmax = max(Seq), by(PermitNumber)
order countmax, after(PermitNumber)
preserve
duplicates drop PermitNumber, force
tab countmax
restore

// dropping entries with missing zip codes.
count if ZipCode == " " // 709
drop if ZipCode == " "

// checking how this affected the number of permits missing years
bysort PermitNumber: egen max = max(year)
bysort PermitNumber: egen min = min(year)
gen range = max -min + 1
gen ind2 = 1
bysort PermitNumber year: replace ind2 = 0 if _n !=1
bysort PermitNumber: egen sum = sum(ind2)
codebook PermitNumber if range !=sum // 303. So this added 303 - 247 = 56 permits.

// Now, preparing data for mapping. 

// making lag and lead zip code and year variables
sort PermitNumber year Seq
gen lagZip = ZipCode[_n-1]
order lagZip, after(ZipCode)
replace lagZip = "" if PermitNumber[_n-1] != PermitNumber
gen nextZip = ZipCode[_n+1]
replace nextZip = "" if PermitNumber[_n+1] != PermitNumber
order nextZip, after(lagZip)
order lagZip, before(ZipCode)
gen nextyear = year[_n+1]
replace nextyear = . if PermitNumber[_n+1] != PermitNumber
order nextyear, after(year)

// Analyzing patterns in the data from these created lags.
count if nextyear != year+1 & nextyear !=year // 16,985
codebook PermitNumber if year+1 != nextyear & nextyear !=year & nextyear !=. // 303. So this is totally due to permits which are missing zip codes and permits with cancellations. Good.


// Now, I begin assigning transfers to one of five mutually exclusive categories: 1) Re-sorts (owner moving with permit), 2) permanent transfers, 3) temporary transfers, 4) transfers back post-temporary trasfer, and 5) undetermined. Decision rules for assigning transfer categories are as follows:

// If an entry's PermitStatus is coded as "Permit holder; permanently transferred permit away" and the next entry is another person in another zip code, code this as a permanent transfer.

// If the NEXT entry's PermitStatus is coded as "Temporary holder through emergency transfer" and the next entry is another person in another zip code, code this entry as a temporary transfer. 

// If the entry and its next entry have the same name but different zip codes, this is coded as a re-sort. Some of these may be natively coded as permament or temporary transfers in the data from CFEC, but I am making the executive decision to give owner names precedence.

// making note of likely re-sorts natively labelled as permanent transfers by CFEC
count if PermitStatus == "Permit holder; permanently transferred permit away" & Name[_n] == Name[_n+1] & ZipCode != nextZip & ZipCode != " " & nextZip != " " & PermitNumber[_n] == PermitNumber[_n+1] // 158 observations

// making note of likely re-sorts natively labelled as temporary transfers by CFEC
count if PermitStatus[_n+1] == "Temporary holder through emergency transfer" & Name[_n] == Name[_n+1] & ZipCode != nextZip & ZipCode != " " & nextZip != " " & PermitNumber[_n] == PermitNumber[_n+1] // 140 observations

// making general move indicator, capturing whether a permit moves in a given entry
gen move = 0
order move, after(nextZip)
replace move = 1 if nextZip !=ZipCode & PermitNumber[_n+1] == PermitNumber  & ( nextyear == year+1 | nextyear == year) // accounts for missing year

// making re-sort indicator, which catalogs if a move was due to owner re-sorting
gen re_sort = 0
order re_sort, after(move)
replace re_sort = 1 if move == 1 & Name[_n+1] ==Name

// making indicator for moves that can be attributed to a permanent transfer
gen perm_trans = 0
order perm_trans, after(nextZip)
replace perm_trans = 1 if move == 1 & nextZip != ZipCode & PermitStatus == "Permit holder; permanently transferred permit away" & re_sort == 0

// making indicator for moves that can be attributed to a temporary transfer
gen temp_trans = 0
order temp_trans, after(nextZip)
replace temp_trans = 1 if move == 1 & nextZip != ZipCode & PermitStatus[_n+1] == "Temporary holder through emergency transfer" & re_sort == 0

// there are a few entries that are denoted both temporary and permanent transfers, because the entry's PermitStatus is PermTrans but the next status is TempTrans
count if temp_trans == 1 & perm_trans == 1 // 325
count if temp_trans == 1 & perm_trans == 1 & Name[_n+1] == Name[_n+2] // 231. These are likely mislabelled permanent transfers. That's what I'm deciding
replace temp_trans = 0 if temp_trans == 1 & perm_trans == 1 & Name[_n+1] == Name[_n+2]
count if temp_trans == 1 & perm_trans == 1 & Name[_n+1] == Name // None. This is good.

// this leaves the 94 observations which are still denoted as both permanent and temporary. 
// Examining. I will make 5 leads and see if the lag name occurs in these. If so, code as temporary transfer.
drop ind
forvalues x = 1/5 {
	gen name_lead_`x' = Name[_n+`x']
}
gen name_lag = Name[_n-1]
count if temp_trans == 1 & perm_trans == 1 & ( name_lag == name_lead_1 | name_lag == name_lead_2 | name_lag == name_lead_3 | name_lag == name_lead_4 | name_lag == name_lead_5 ) // 12

// recoding these as temporary transfers, and coding the remaining transfers as "undetermined".
replace perm_trans = 0 if temp_trans == 1 & perm_trans == 1 & ( name_lag == name_lead_1 | name_lag == name_lead_2 | name_lag == name_lead_3 | name_lag == name_lead_4 | name_lag == name_lead_5 )
count if temp_trans == 1 & perm_trans == 1 // 82. recoding as "undetermined"
gen undetermined = 0
replace undetermined = 1 if temp_trans == 1 & perm_trans == 1
replace temp_trans = 0 if undetermined == 1
replace perm_trans = 0 if undetermined == 1

// defining a "transfer back" variable
tab PermitStatus if move == 1 & re_sort == 0 & temp_trans == 0 & perm_trans == 0
gen trans_back = 0
order trans_back, after(temp_trans)
replace trans_back = 1 if move == 1 & re_sort == 0 & temp_trans == 0 & perm_trans == 0 & undetermined == 0 & PermitStatus == "Temporary holder through emergency transfer" & Name[_n-1] == Name[_n+1] & Name[_n] != Name[_n+1]  & PermitNumber[_n] == PermitNumber[_n+1]

// inter-year move indicator ( = 1 if the move occurs between years)
gen inter_year = 0
order inter_year, after(move)
replace inter_year = 1 if move == 1 & year[_n+1] != year

// intra-year move indicator ( = 1 if the move occurs within a year)
gen intra_year = 0
order intra_year, after(inter_year)
replace intra_year = 1 if move == 1 & year[_n+1] == year
count if move == 1 & inter_year == 0 & intra_year == 0 // none. great

// which moves are left unaccounted for/ not explained so far?
count if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 & undetermined == 0 // 355 obs
codebook PermitNumber if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 & undetermined == 0 // 336 permits.

tab PermitStatus
replace PermitStatus = "Canc" if PermitStatus == "Permit cancelled"
replace PermitStatus = "Holder" if PermitStatus == "Permit holder"
replace PermitStatus = "Perm" if PermitStatus == "Permit holder; permanently transferred permit away"
replace PermitStatus = "Temp" if PermitStatus == "Temporary holder through emergency transfer"
tab PermitStatus

gen statuslead = PermitStatus[_n+1]
tab PermitStatus statuslead if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 & undetermined == 0 
count if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 & undetermined == 0 & PermitStatus == "Holder" & statuslead == "Holder" & Name == name_lead_1

// Denoting these moves as undetermined. 
replace undetermined = 1 if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 & undetermined == 0

// Making variables denoting cancellations and reinstatements

// Exploring the data a bit.
sort PermitNumber year Seq
codebook PermitNumber if PermitStatus == "Canc" // 3177 permits left.
count if PermitStatus == "Canc" & PermitNumber[_n+1] == PermitNumber // 334 permits were reinstated.
count if PermitStatus == "Canc" & PermitNumber[_n+1] == PermitNumber & year[_n+1] == year[_n]+1 // 90 of the reinstated permits were reinstated the next year

// making an indicator for a permit's reinstatement, plus a variable capturing how long it was cancelled
gen year_reinstated = 0
order year_reinstated, after(perm_trans)
replace year_reinstated = 1 if PermitStatus[_n-1] == "Canc" & PermitNumber[_n-1] == PermitNumber
gen years_cancelled = 0
order years_cancelled, after(year_reinstated)
replace years_cancelled = year - year[_n-1] if year_reinstated == 1

// Exploring. *USE FOR SUM STATS*
tab years_cancelled
sum years_cancelled if years_cancelled > 0

// Organizing data
sort PermitNumber year Seq
keep if move == 1
keep PermitNumber year Seq ZipCode nextZip move inter_year intra_year re_sort temp_trans trans_back perm_trans undetermined year_reinstated years_cancelled
rename (ZipCode nextZip) (start_zip end_zip)
sort year start_zip end_zip
count if start_zip == end_zip // Equals 0, which it should. good.

// Making new variables which catalog the combinations between the time- (intra-inter) and agent-specific transfer types.
foreach x in intra inter {
	foreach y in re_sort temp_trans trans_back perm_trans undetermined {
		gen `x'_`y' = 0
		replace `x'_`y' = 1 if `x'_year == 1 & `y' == 1
	}
}

// creating year-(zip combination) specific counts of transfer types.
foreach x in move re_sort intra_year inter_year temp_trans perm_trans trans_back undetermined year_reinstated intra_re_sort intra_temp_trans intra_trans_back intra_perm_trans intra_undetermined inter_re_sort inter_temp_trans inter_trans_back inter_perm_trans inter_undetermined {
	bysort year start_zip end_zip: egen sum = sum(`x')
	rename sum number_`x'
}

// Summing number of permits which moved in each year-(zip combination) 
gen ind = 1
bysort PermitNumber year start_zip end_zip: replace ind = 0 if _n >1
bysort year start_zip end_zip: egen sum = sum(ind)
drop ind
rename sum number_permits

// Keeping one entry for each year-(zip combination) 
bysort year start_zip end_zip: keep if _n ==1
drop PermitNumber Seq move intra_year inter_year re_sort temp_trans perm_trans trans_back year_reinstated years_cancelled number_year_reinstated intra_re_sort intra_temp_trans intra_trans_back intra_perm_trans intra_undetermined inter_re_sort inter_temp_trans inter_trans_back inter_perm_trans inter_undetermined undetermined

// making summary variables
order number_re_sort, before(number_temp_trans)
//checking whether intra and inter sum to the total number of moves (they do)
gen sum = number_move - number_intra_year - number_inter_year
tab sum
drop sum
//checking whether move types sum to the total number of moves (they do)
gen sum2 = number_move - number_re_sort - number_temp_trans - number_perm_trans - number_trans_back - number_undetermined
tab sum2
drop sum2

// Labelling variables
label var number_move "Total moves"
label var number_intra_year "Intra-year moves"
label var number_inter_year "Inter-year moves"
label var number_re_sort "Re-sorts"
label var number_perm_trans "Permanent Transfers"
label var number_temp_trans "Temporary transfers"
label var number_trans_back "Back-transfers"
label var number_undetermined "Undetermined"
label var number_intra_re_sort "Intra-year Re-sorts"
label var number_intra_temp_trans "Intra-year Temporary transfers"
label var number_intra_trans_back "Intra-year Back-transfers"
label var number_intra_perm_trans "Intra-year Permanent Transfers"
label var number_intra_undetermined "Intra-year Undetermined"
label var number_inter_re_sort "Inter-year Re-sorts"
label var number_inter_temp_trans "Inter-year Temporary transfers"
label var number_inter_trans_back "Inter-year Back-transfers"
label var number_inter_perm_trans "Inter-year Permanent Transfers"
label var number_inter_undetermined "Inter-year Undetermined"
label var start_zip "Beginning Zip"
label var end_zip "End Zip"
label var number_permits "Number of Permits in Year-Zip Combination"


// Saving data.
save "$path/YearlyMoves.dta", replace

}

***********************************************************************************
** Section 3: Making import, export, and net permit migration dataset by zip.    **
** Saved as Permanent_net.dta                                                    **
***********************************************************************************
{
	
cd "$path"
	
// start from YearlyMoves.dta
use "$path/YearlyMoves.dta", clear
drop if start_zip ==" " | end_zip == " "
count if start_zip == end_zip // 0
destring start_zip end_zip, replace force
drop if start_zip == .
drop if end_zip == .

// merging with ZipcodeR data, which  has demographic information on each zip

// Merging starting zip codes
rename start_zip zipcode
merge m:1 zipcode using "$path\Zip Code Data\Zipcodes.dta"
drop if _merge == 2
drop _merge common_city_list timezone area_code_list water_area_in_sqmi bounds_west bounds_east bounds_north bounds_south
rename (zipcode lat lng) (start_zip start_lat start_lgt)
foreach x in zipcode_type major_city post_office_city county state radius_in_miles population population_density land_area_in_sqmi housing_units occupied_housing_units median_home_value median_household_income {
	rename `x' start_`x'
}

// Merging ending zip codes
rename end_zip zipcode
merge m:1 zipcode using "$path/Zip Code Data/Zipcodes.dta"
drop if _merge == 2
drop _merge common_city_list timezone area_code_list water_area_in_sqmi bounds_west bounds_east bounds_north bounds_south
rename (zipcode lat lng) (end_zip end_lat end_lgt)
foreach x in zipcode_type major_city post_office_city county state radius_in_miles population population_density land_area_in_sqmi housing_units occupied_housing_units median_home_value median_household_income {
	rename `x' end_`x'
}
sort year

// Dropping non-matched transfers. 
// Summary: 608 entries out of 73227. Roughly 0.08% of the total data.
count if start_lat == "" | end_lat == "" | start_lgt == "" | end_lgt == "" // 608 out of 73227
tab year if start_lat == "" | end_lat == "" | start_lgt == "" | end_lgt == "" // pretty even distribution of non-matched zips over time. 
drop if start_lat == "" | end_lat == "" | start_lgt == "" | end_lgt == "" 
sort year

// Making zip-specific outflows dataset to use in the final net flows data.
preserve
egen outflow = sum(number_permits), by(start_zip)
collapse (mean) outflow, by(start_zip)
rename start_zip zip
save "$path/Permanent_outflows.dta", replace
restore

// Making zip-specific inflows dataset to use in the final net flows data.
preserve
egen inflow = sum(number_permits), by(end_zip)
collapse (mean) inflow, by(end_zip)
rename end_zip zip
save "$path/Permanent_inflows.dta", replace
restore

// Now, using the inflow and outflow data to create net flow data.

// Merging
use "$path/Permanent_outflows.dta", clear
merge m:m zip using "$path/Permanent_inflows.dta"

// making net flow variable
replace outflow = 0 if outflow == .
replace inflow = 0 if inflow == .
drop _merge
gen net = inflow- outflow
egen test = sum(net) 
tab test // Net flows should be 0, and they are. good.
drop test

// making variables that will be useful if we decide to map these flows later.
gen sign = ""
replace sign = "Neg" if net < 0
replace sign = "Pos" if net > 0
replace sign = "Zero" if net == 0
gen absval_net = abs(net)

// Merging on demographic info, and saving.
rename zip zipcode
merge 1:1 zipcode using "$path\Zip Code Data\Zipcodes.dta"
drop if _merge == 2
rename zipcode zip
drop _merge common_city_list timezone area_code_list water_area_in_sqmi bounds_west bounds_east bounds_north bounds_south post_office_city
rename (lat lng) (latit longit)

// Quick check to see how net flows relate to median HH income by zip.
destring median_household_income, replace force
twoway scatter median_household_income net // no clear relationship, but come back to this.

// Labelling variables
label var zip "Zip code"
label var outflow "Outflows, 1975 to 2023"
label var inflow "Outflows, 1975 to 2023"
label var net "Net flows, 1975 to 2023"
label var sign "Sign of net flows"
label var absval_net "Absolute value of net flows"
label var zipcode_type "Zip type"
label var major_city "City associated with zip"
label var county "County"
label var state "State"
label var latit "Latitude"
label var longit "Longitude"
label var radius_in_miles "Zip code radius (miles)"
label var population "Population"
label var population_density "Population Density"
label var land_area_in_sqmi "Land Area"
label var housing_units "Housing Units"
label var occupied_housing_units "Occupied Housing Units"
label var median_home_value "Median Home Value"
label var median_household_income "Median HH Income"

// Saving.
save "$path/Permanent_net.dta", replace

}

***********************************************************************************
** Section 4: Making permit-level origin-dest dataset for entire 1975-23 period  **
** This Section is useful for summary statistics.                                **
** Saved as OriginDestination.dta                                                **
***********************************************************************************
{

// Start this from full panel of permits, PermanentPermitData.dta
use "$path/PermanentPermitData.dta", clear
sort PermitNumber PermitStatus year Seq

// Dropping all entries for permits after they are cancelled 
gen ind = 1
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0

// dropping blank zipcodes
drop if ZipCode == " " // 709. 9 of these are cancelled entries. 

// Making variables which tell me the first and last years to permit shows up
egen Min = min(year), by(PermitNumber)
egen Max = max(year), by(PermitNumber)
order Min Max, after(year)
order ZipCode, after(fishery)
sort fishery PermitNumber year Seq
order fishery PermitNumber year Min Max ZipCode PermitType PermitStatus Seq Name, first

// Track each permit's # of owners and number of zips visited before collapsing
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

// Dropping all entries not in first and last years. 
keep if year == Min | year == Max
sort fishery PermitNumber year Seq

// Denoting permits only present for one year
gen ind = 1
bysort PermitNumber year: replace ind = 0 if _n !=1
bysort PermitNumber: egen firstlast = sum(ind)
tab firstlast
codebook PermitNumber // if firstlast ==1 // 43 permits out of 16,659
drop ind

// Exploring: seeing how many zip codes we have within the first and last year of each permit
gen ind = 1
order ind, after(ZipCode)
bysort PermitNumber ZipCode: replace ind = 0 if _n !=1
egen zips_firstlast = sum(ind), by(PermitNumber)
order zips_firstlast, after(ZipCode)
drop ind
preserve
bysort PermitNumber: keep if _n ==1
tab zips_firstlast
restore // takeaway: 99 percent of permits have <= 3 zipcodes in their first and last years. 0.05% have >3
sort PermitNumber year Seq

// Getting rid of first-year obs not associated with the first holder in that year
drop if year == Min & Seq > 1

// Getting rid of last-year obs not associated with the last holder in that year
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
tab sum if year == Min // None are zero. Great.
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

// Dropping unnecessary vars and cleaning up
drop year ZipCode Seq Name PermitStatus SeqCheckDigit StartDate EndDate LastName FirstName Middle Suffix Street City State ForeignAddress Residency sum
rename (Min Max) (first_yr last_yr)
codebook PermitNumber, compact
bysort PermitNumber: egen fz = sum(first_zip)
bysort PermitNumber: egen lz = sum(last_zip)
order fz lz, after(last_zip)
duplicates drop PermitNumber fz lz, force // 0 are duplicates. Good.
drop first_zip last_zip
rename (fz lz) (first_zip last_zip)
gen nomove = 0
replace nomove = 1 if first_zip == last_zip
order nomove, after(last_zip)
sort fishery

// Merging on zip-level demographics with ZipcodeR data

// Merging for first zip code. 
destring first_zip last_zip, replace
rename first_zip zipcode
merge m:1 zipcode using "$path/Zip Code Data/Zipcodes.dta"
drop if _merge == 2
sort _merge // 38 permits not matched. dropping 
drop if _merge == 1

// Cleaning up
drop _merge common_city_list timezone area_code_list water_area_in_sqmi bounds_west bounds_east bounds_north bounds_south
rename (zipcode lat lng) (first_zip first_lat first_lgt)
foreach x in zipcode_type major_city post_office_city county state radius_in_miles population population_density land_area_in_sqmi housing_units occupied_housing_units median_home_value median_household_income {
	rename `x' first_`x'
}

// Merging for last zip code. 
rename last_zip zipcode
merge m:1 zipcode using "$path/Zip Code Data/Zipcodes.dta"
drop if _merge == 2
sort _merge // 16 permits not matched. dropping 
drop if _merge == 1

// Cleaning up.
drop _merge common_city_list timezone area_code_list water_area_in_sqmi bounds_west bounds_east bounds_north bounds_south
rename (zipcode lat lng) (last_zip last_lat last_lgt)
foreach x in zipcode_type major_city post_office_city county state radius_in_miles population population_density land_area_in_sqmi housing_units occupied_housing_units median_home_value median_household_income {
	rename `x' last_`x'
}

// Cleaning, and creating a binary variable "net_move" which indicates whether the permit ended up back where it started.
sort fishery
order first_lgt first_lat last_lgt last_lat, after(last_zip)
gen net_move = 1 - nomove
drop nomove


// Creating final set of variables, indicators which tell us whether the permit was "stationary" along the dimensions of zip, owner, or both
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

// Cleaning
drop person_yrs_straight person_yrs_past state_yrs_straight state_yrs_past zip_yrs_straight zip_yrs_past inter_state_move intra_state_move person_move Transferable intra_xfers yearly_count within_yr_dup_owners yr_owners ft_owner lt_owner descrip hist_descrip current_descrip CFECID ADFG catch_current_descrip gear_current_descrip location_current_descrip catch_hist_descrip gear_hist_descrip location_hist_descrip last_post_office_city first_post_office_city years_range

// Labelling
label var fishery "Fishery"
label var PermitNumber "Permit Number"
label var first_yr "First year permit is in the data"
label var last_yr "Last year permit is in the data"
label var range "Range of time the permit is in the data (yrs)"
label var first_zip "First zip code permit is observed"
label var last_zip "Last zip code permit is observed"
label var first_lgt "Longitude - first zip"
label var first_lat "Latitude - first zip"
label var last_lgt "Longitude - last zip"
label var last_lat "latitude - last zip"
label var zips_firstlast "Number of zips seen within first and last years"
label var number_zips "Number of zips the permit visits"
label var stat_zips "Dummy, =1 if the permit stays in the same place"
label var number_owners "Number of owners the permit has"
label var stat_owners "Dummy, =1 if the permit stays with the same person"
label var stat_all "Dummy, =1 if the permit stays with the same person and in the same place"
label var PermitType "Permit Type (all are permanent)"
label var years_observed "Number of years permit is observed in the data"
label var years_missing "Number of years permit is missing in the data"
label var states "Number of states the permit visits"
label var countries "Number of countries the permit visits"
label var catch_descrip "Fishery catch description from CFEC permit data"
label var gear_descrip "Fishery gear description from CFEC permit data"
label var location_descrip "Fishery location description from CFEC permit data"
label var firstlast "Dummy, =1 if the permit is only in the data for one year"
label var first_zipcode_type "First zipcode type"
label var first_major_city "Major city associated with first zip code"
label var first_county "County associated with first zip code"
label var first_state "State of first zip code"
label var first_radius_in_miles "Radius of first zip code"
label var first_population "Population of first zip code"
label var first_population_density "Pop density of first zip code"
label var first_land_area_in_sqmi "Land area of first zip code"
label var first_housing_units "Total housing units in first zip code"
label var first_occupied_housing_units "Occupied housing units in first zip code"
label var first_median_home_value "Median home value of first zip code"
label var first_median_household_income "Median hh income of first zip code"
label var last_zipcode_type "Last zipcode type"
label var last_major_city "Major city associated with last zip code"
label var last_county "County associated with last zip code"
label var last_state "State of last zip code"
label var last_radius_in_miles "Radius of last zip code"
label var last_population "Popualtion of last zip code"
label var last_population_density "Pop density of last zip code"
label var last_land_area_in_sqmi "Land area of last zip code"
label var last_housing_units "Total housing units in last zip code"
label var last_occupied_housing_units "Occupied housing units in last zip code"
label var last_median_home_value "Median home value of last zip code"
label var last_median_household_income "Median home value of last zip code"
label var net_move "Dummy, =1 if the permit ends up in a different zip code than it started in"

// Saving.
save "$path/OriginDestination.dta"

}

***********************************************************************************
** Section 5: Figures and Summary Statistics.                                    **
** Section 5.1: Creates figures and sumstats related to the permit panel.        **
** Section 5.2: Creates an area chart of moves from the yearly moves data.       **
** Section 5.3: Creates bar charts of imports, exports, net permit flows by zip  **
**              Also does this for SRFCs (small remote fishing communities) a la **
**              Caothers et al 2010.                                             **
***********************************************************************************
{

*********************************************************************************
*** 5.1 Figures and sumstats from the permit panel (PermanentPermitData.dta)  ***
*********************************************************************************
{
**********************************************************
** Area chart which shows how many permits exist in the **
** system at any give time, disaggregated by catch.     **
**********************************************************
{
// Starting from Permanent permit panel.
use "$path/PermanentPermitData.dta", clear

// Dropping all entries for permits after they are cancelled, renaming catches for graph
drop if PermitStatus == "Permit cancelled"
duplicates drop PermitNumber year, force
drop if year > 2022
replace catch_descrip = "KING AND TANNER CRAB" if ustrpos(catch_descrip, "KING")>0
replace catch_descrip = "KING AND TANNER CRAB" if ustrpos(catch_descrip, "TANNER")>0
replace catch_descrip = "HERRING" if ustrpos(catch_descrip, "HERRING")>0


// Making area map counts by year 
bysort year catch_descrip: egen Permits_in_Yr_Catch = count(_n)
duplicates drop year catch_descrip, force

keep year catch_descrip Permits_in_Yr_Catch
encode catch_descrip, generate(encode)
drop catch_descrip
// dung 1, geoduck 2, herring 3, king tanner 4, sablefish 5, salmon 6, cucumber 7, urch 8, shrimp 9
reshape wide Permits_in_Yr_Catch, i(year) j(encode)

rename (Permits_in_Yr_Catch1 Permits_in_Yr_Catch2 Permits_in_Yr_Catch3 Permits_in_Yr_Catch4 Permits_in_Yr_Catch5 Permits_in_Yr_Catch6 Permits_in_Yr_Catch7 Permits_in_Yr_Catch8 Permits_in_Yr_Catch9) (DungenessCrab GeoduckClams Herring KingTannerCrab Sablefish Salmon SeaCucumber SeaUrchin Shrimp)

foreach x in DungenessCrab GeoduckClams Herring KingTannerCrab Sablefish Salmon SeaCucumber SeaUrchin Shrimp {
	replace `x' = 0 if `x' ==.
	label var `x' "`x'"
}

gen Total = DungenessCrab + GeoduckClams + Herring + KingTannerCrab + Sablefish + Salmon +SeaCucumber + SeaUrchin + Shrimp

line DungenessCrab GeoduckClams Herring KingTannerCrab Sablefish SeaCucumber SeaUrchin Shrimp year, legend(size(medsmall)) name(graph1, replace)

line Total Salmon year, legend(size(medsmall)) name(graph2, replace)

graph combine graph1 graph2, row(2) title("Total permits over time")

}

**********************************************************
** Permanent Permit Panel Summary statistics, by catch  **
**********************************************************
{
use "$path/PermanentPermitData.dta", clear

// Permit-level summary stats for range of years, # of states, # of countries 

// Dropping all entries for permits after they are cancelled 
gen ind = 1
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0

duplicates drop PermitNumber year, force
drop if year > 2022
replace catch_descrip = "KING AND TANNER CRAB" if ustrpos(catch_descrip, "KING")>0
replace catch_descrip = "KING AND TANNER CRAB" if ustrpos(catch_descrip, "TANNER")>0
replace catch_descrip = "HERRING" if ustrpos(catch_descrip, "HERRING")>0
replace catch_descrip = "OTHER" if catch_descrip != "SALMON" & catch_descrip != "HERRING"
duplicates drop PermitNumber, force
eststo clear
bysort catch_descrip: eststo: quietly estpost summarize years_range years_observed states countries
esttab, cells("mean sd") label nodepvar

// Permit-level summary stats for number of owners, both raw and time-normalized

use "$path/PermanentPermitData.dta", clear
// Dropping all entries for permits after they are cancelled 
gen ind = 1
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0

drop if year > 2022
replace catch_descrip = "KING AND TANNER CRAB" if ustrpos(catch_descrip, "KING")>0
replace catch_descrip = "KING AND TANNER CRAB" if ustrpos(catch_descrip, "TANNER")>0
replace catch_descrip = "HERRING" if ustrpos(catch_descrip, "HERRING")>0
replace catch_descrip = "OTHER" if catch_descrip != "SALMON" & catch_descrip != "HERRING"
duplicates drop PermitNumber Name, force
bysort PermitNumber: egen count = count(_n)
duplicates drop PermitNumber count, force
label var count "Number of total owners"
gen count_yr = count/years_observed
label var count_yr "Time-normalized total owners"
sum count count_yr // all data
// broken out by catch
eststo clear
bysort catch_descrip: eststo: quietly estpost summarize count count_yr
esttab, cells("mean sd") label nodepvar

// Assorted other summary statistics.

use "$path/PermanentPermitData.dta", clear

// bookkeeping
sort PermitNumber year Seq
order PermitNumber year Seq, first
order descrip, before(catch_descrip)
order current_descrip, before(catch_current_descrip)
order hist_descrip, before(catch_hist_descrip)
order Name, before(Street)
order FirstName LastName Middle Suffix Transferable SeqCheckDigit, last
order Name ZipCode PermitStatus, after(Seq)
replace ZipCode = substr(ZipCode, 1,5) // replacing zip+4 codes
bysort PermitNumber: egen Min = min(year)

replace catch_descrip = "KING AND TANNER CRAB" if ustrpos(catch_descrip, "KING")>0
replace catch_descrip = "KING AND TANNER CRAB" if ustrpos(catch_descrip, "TANNER")>0
replace catch_descrip = "HERRING" if ustrpos(catch_descrip, "HERRING")>0
replace catch_descrip = "OTHER" if catch_descrip != "SALMON" & catch_descrip != "HERRING"

preserve // baseline tab of permits in dataset
duplicates drop PermitNumber, force
tab catch_descrip
restore

// exploratory analysis of cancelled permits.
// Here, I am seeing how many permits come back online after cancellation.
frame drop cancelled
frames put *, into(cancelled)
frame change cancelled
gen cancel = 0
replace cancel = 1 if PermitStatus == "Permit cancelled"
bysort PermitNumber: egen sum = sum(cancel)
keep if sum > 0
sort PermitNumber year Seq
drop sum
codebook PermitNumber, compact // 3186 unique permits were cancelled.

preserve // tabbing out number of cancelled permits by catch
duplicates drop PermitNumber, force
tab catch_descrip
restore


tab catch_descrip
//dropping post-cancellation entries for cancelled permits
gen ind = 1
sort PermitNumber PermitStatus year
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0
sort PermitNumber year Seq
bysort PermitNumber: egen Max = max(year)
count if PermitStatus == "Permit cancelled" & year != Max 
codebook PermitNumber if PermitStatus == "Permit cancelled" & year != Max // 337 of 3186 cancelled permits come back online **PUT THIS IN SUMSTATS**
tab PermitNumber if PermitStatus == "Permit cancelled" & year != Max // 1 entry per permit
tab catch_descrip if PermitStatus == "Permit cancelled" & year != Max // disproportionately high salmon


frame change default
frames drop cancelled



// Dropping all entries for cancelled permits after they are cancelled (and in a few cases, before they are re-activated)
gen ind = 1
sort PermitNumber PermitStatus year
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0


// this code tells us which permits are missing years. 247 permits are missing years. all of these are ones which were cancelled. 
// summary: 3186 permits cancelled. 337 came back online. Of these, 247 took more than a year. 90 came back online the next year. 

bysort PermitNumber: egen max = max(year)
bysort PermitNumber: egen min = min(year)
gen range = max -min + 1
gen ind2 = 1
bysort PermitNumber year: replace ind2 = 0 if _n !=1
bysort PermitNumber: egen sum = sum(ind2)
codebook PermitNumber if range !=sum
gen cancelled = 0
replace cancelled = 1 if PermitStatus == "Permit cancelled"
bysort PermitNumber: egen sumcan = sum(cancelled)
codebook PermitNumber if range !=sum // 247
codebook PermitNumber if sumcan > 0 // 3186
codebook PermitNumber if range !=sum & sumcan > 0 // 247! 

gen years_til_cancel = 0
replace years_til_cancel = year - min if cancelled == 1

preserve
keep if cancelled == 1 
codebook PermitNumber 
sum years_til_cancel
hist years_til_cancel
codebook PermitNumber if range !=sum 
sum years_til_cancel if range !=sum 
hist years_til_cancel if range !=sum 
tab catch_descrip if range !=sum // Of those which took more than a year (247), 82% salmon
tab catch_descrip if range ==sum & year!= max // Of those which immediately returned (90), 72% salmon
restore


// Avg time to cancellation, normalized by time in the sample. 
preserve
keep if cancelled == 1

sum years_til_cancel
bysort catch_descrip: sum years_til_cancel

gen norm_years_til_cancel = years_til_cancel/years_observed
sum norm_years_til_cancel
bysort catch_descrip: sum norm_years_til_cancel

restore

}
}

*********************************************************************************
*** 5.2 Area chart of moves from the yearly moves dataset (YearlyMoves.dta)   ***
*********************************************************************************
{

use "$path/YearlyMoves.dta", clear

collapse (sum) number_move number_intra_year number_re_sort number_inter_year number_temp_trans number_perm_trans number_trans_back number_undetermined number_permits number_intra_re_sort number_intra_temp_trans number_intra_trans_back number_intra_perm_trans number_intra_undetermined number_inter_re_sort number_inter_temp_trans number_inter_trans_back number_inter_perm_trans number_inter_undetermined, by(year)

twoway line number_move number_intra_year number_inter_year year
twoway line  number_move number_inter_year number_inter_temp_trans number_inter_trans_back number_intra_year number_intra_temp_trans number_intra_trans_back year

twoway line number_move number_re_sort number_perm_trans number_temp_trans number_trans_back number_undetermined year
}

*********************************************************************************
*** 5.3 Bar Charts using zip-level net permit flow data (Permanent_net.dta)   ***
*********************************************************************************
{
	
**********************************************************
** Bar charts of net permit flows by Alaskan census     **
** areas and boroughs.                                  **
**********************************************************
{
use "$path/Permanent_net.dta", clear
destring median_household_income, replace force
bysort county state: egen avg_income = mean(median_household_income)
bysort county state: egen county_outflow = sum(outflow)
bysort county state: egen county_inflow = sum(inflow)
order county_outflow county_inflow, after(inflow)
bysort county state: egen county_net = sum(net)
order county_net, after(county_inflow)
collapse (mean) county_outflow county_inflow county_net avg_income, by(county state)
sort state
egen sum = sum(county_net)
tab sum // should be zero
keep if state == "AK"
drop if county == ""
sort county_net
label var county_inflow "Inflows"
label var county_outflow "Outflows"
label var county_net "Net"

// Net Permit flows by Census Area and Borough
graph bar county_outflow county_inflow county_net, over(county, lab(angle(320))) scale(*.5) title(Net Permit flows by Census Area and Borough) sort(county_net)


// top 5 net importer and exporter counties
drop in 6/27
graph bar county_outflow county_inflow county_net, over(county, lab(angle(320))) scale(*.5) title(Net Permit flows by Census Area and Borough) 
}

**********************************************************
** Bar charts of net permit flows by Alaskan SRFCs      **
** (small remote fishing communities), as defined by    **
** Carothers et al 2010                                 **
**********************************************************
{
use "$path/Permanent_net.dta", clear
destring median_household_income, replace force
bysort major_city state: egen avg_income = mean(median_household_income)
bysort major_city state: egen city_outflow = sum(outflow)
bysort major_city state: egen city_inflow = sum(inflow)
order city_outflow city_inflow, after(inflow)
bysort major_city state: egen city_net = sum(net)
order city_net, after(city_inflow)
collapse (mean) city_outflow city_inflow city_net avg_income, by(major_city state)
sort state
egen sum = sum(city_net)
tab sum // should be zero

rename major_city first_major_city
rename state first_state

// Relabeling cities and SRFC variables
replace first_major_city = first_major_city + ", " + first_state
gen SRFC = "."


// 58 small SRFCs were identified by Carothers et al. Denoting them here. 
// As seen below, only 41 of these appear in the data. 
replace SRFC = "S" if first_major_city == "Akhiok, AK"
replace SRFC = "S" if first_major_city == "Akutan, AK"
replace SRFC = "S" if first_major_city == "Atka, AK"
replace SRFC = "S" if first_major_city == "Angoon, AK"
replace SRFC = "S" if first_major_city == "Chenega Bay, AK"
replace SRFC = "S" if first_major_city == "Chignik, AK"
replace SRFC = "S" if first_major_city == "Chignik Lagoon, AK"
replace SRFC = "S" if first_major_city == "Coffman Cove, AK"
replace SRFC = "S" if first_major_city == "Craig, AK"
replace SRFC = "S" if first_major_city == "Edna Bay, AK"
replace SRFC = "S" if first_major_city == "Elfin Cove, AK"
replace SRFC = "S" if first_major_city == "False Pass, AK"
replace SRFC = "S" if first_major_city == "Gustavus, AK"
replace SRFC = "S" if first_major_city == "Halibut Cove, AK"
replace SRFC = "S" if first_major_city == "Hoonah, AK"
replace SRFC = "S" if first_major_city == "Hydaburg, AK"
replace SRFC = "S" if first_major_city == "Hyder, AK"
replace SRFC = "S" if first_major_city == "Ivanof Bay, AK"
replace SRFC = "S" if first_major_city == "Kake, AK"
replace SRFC = "S" if first_major_city == "Kasilof, AK"
replace SRFC = "S" if first_major_city == "King Cove, AK"
replace SRFC = "S" if first_major_city == "Klawock, AK"
replace SRFC = "S" if first_major_city == "Larsen Bay, AK"
replace SRFC = "S" if first_major_city == "Mekoryuk, AK"
replace SRFC = "S" if first_major_city == "Metlakatla, AK"
replace SRFC = "S" if first_major_city == "Meyers Chuck, AK"
replace SRFC = "S" if first_major_city == "Naknek, AK"
replace SRFC = "S" if first_major_city == "Nanwalek, AK"
replace SRFC = "S" if first_major_city == "Naukati Bay, AK"
replace SRFC = "S" if first_major_city == "Nikolaevsk, AK"
replace SRFC = "S" if first_major_city == "Ninilchik, AK"
replace SRFC = "S" if first_major_city == "Old Harbor, AK"
replace SRFC = "S" if first_major_city == "Ouzinkie, AK"
replace SRFC = "S" if first_major_city == "Pelican, AK"
replace SRFC = "S" if first_major_city == "Perryville, AK"
replace SRFC = "S" if first_major_city == "Point Baker, AK"
replace SRFC = "S" if first_major_city == "Port Alexander, AK"
replace SRFC = "S" if first_major_city == "Port Graham, AK"
replace SRFC = "S" if first_major_city == "Port Lions, AK"
replace SRFC = "S" if first_major_city == "Port Protection, AK"
replace SRFC = "S" if first_major_city == "Saint George Island, AK"
replace SRFC = "S" if first_major_city == "Saint Paul Island, AK"
replace SRFC = "S" if first_major_city == "Sand Point, AK"
replace SRFC = "S" if first_major_city == "Seldovia, AK"
replace SRFC = "S" if first_major_city == "Skagway, AK"
replace SRFC = "S" if first_major_city == "South Naknek, AK"
replace SRFC = "S" if first_major_city == "Tatitlek, AK"
replace SRFC = "S" if first_major_city == "Tenakee Springs, AK"
replace SRFC = "S" if first_major_city == "Thorne Bay, AK"
replace SRFC = "S" if first_major_city == "Toksook Bay, AK"
replace SRFC = "S" if first_major_city == "Tununak, AK"
replace SRFC = "S" if first_major_city == "Whale Pass, AK"
replace SRFC = "S" if first_major_city == "Whittier, AK"
replace SRFC = "S" if first_major_city == "Yakutat, AK"
codebook first_major_city if SRFC == "S" // 41 in the data

// 4 medium SRFCs were identified by Carothers et al. Denoting them here. 
// All 4 appear in the data.
replace SRFC = "M" if first_major_city == "Cordova, AK"
replace SRFC = "M" if first_major_city == "Dillingham, AK"
replace SRFC = "M" if first_major_city == "Haines, AK"
replace SRFC = "M" if first_major_city == "Wrangell, AK" // all here

// 3 large SRFCs were identified by Carothers et al. Denoting them here. 
// All 3 appear in the data.
replace SRFC = "L" if first_major_city == "Kodiak, AK"
replace SRFC = "L" if first_major_city == "Petersburg, AK"
replace SRFC = "L" if first_major_city == "Unalaska, AK"

// keeping only Alaskan data
keep if first_state == "AK"
sort SRFC
sum city_inflow city_outflow city_net 
sum city_inflow city_outflow city_net if SRFC !="."

// Graphing small SRFC flows.
preserve
keep if SRFC == "S"
graph bar city_outflow city_inflow city_net, over(first_major_city, lab(angle(320))) scale(*.5) title(Net Permit flows in small SRFCs (2010 pop. <1500)) 
restore
// Graphing medium SRFC flows.
preserve
keep if SRFC == "M"
graph bar city_outflow city_inflow city_net, over(first_major_city, lab(angle(320))) scale(*.5) title(Net Permit flows in medium SRFCs (2010 pop. 1500-2500)) 
restore
// Graphing large SRFC flows.
preserve
keep if SRFC == "L"
graph bar city_outflow city_inflow city_net, over(first_major_city, lab(angle(320))) scale(*.5) title(Net Permit flows in large SRFCs (2010 pop. 2500-7000)) 
restore
}

}

}






















