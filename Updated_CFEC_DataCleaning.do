// Do-file to transform scraped spreadsheets from CFEC into .dta files
// Author: Greg Boudreaux
// Date: January 2024

*******************************************************************************
** Preliminaries: Make sure that all .xls files are in the same directory    **
*******************************************************************************
{
// changing the name of each file in the directory
cd "C:\Users\gboud\Desktop\Example Fisheries"
local files: dir . files "*.xls"
di `files'

foreach file in `files' {
	
	clear
	import excel "`file'", sheet("Permits") firstrow clear
	drop in 1
	local year = Year[1]
	local fishery = Fishery[1]
	di `year'
	di "`fishery'"
	
	!rename "`file'" "`fishery'_`year'.xls"

}

// looping through and saving as .dta files
local files: dir . files "*.xls"
foreach file in `files' {
	clear 
	import excel "`file'", sheet("Permits") firstrow clear
	drop in 1
	local year = Year[1]
	local fishery = Fishery[1]
	di `year'
	di "`fishery'"
	
	save "Stata/`fishery'_`year'.dta", replace
}

// appending all .dta files
cd "C:\Users\gboud\Desktop\Example Fisheries\Stata"
local files: dir . files "*.dta"
clear
append using `files'
duplicates drop // just checking

// data cleaning work
replace Seq = substr(Seq, 2, 1) if substr(Seq, 1, 1) =="0"
gen PermitNumber = PermitSerial + PermitSerialCheckDigit
gen Name = FirstName + " " + LastName
order PermitNumber, after(PermitSerial)
drop PermitSerial PermitSerialCheckDigit
destring Year Seq, replace
drop if PermitType != "Permanent"
sort PermitNumber Year Seq

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", replace  // GB - sub in whatever path you are going to use. 
}

***********************************************************************************
** Section 1: Making permit-level origin-dest dataset for entire 1975-24 period  **
***********************************************************************************
{
	
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear


sort PermitNumber PermitStatus Year

// Dropping all entries for permits after they are cancelled 
gen ind = 1
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0

egen Min = min(Year), by(PermitNumber)
egen Max = max(Year), by(PermitNumber)
order Min Max, after(Year)
order ZipCode, after(Fishery)
sort Fishery PermitNumber Year Seq
order Fishery PermitNumber Year Min Max ZipCode PermitType PermitStatus Seq Name, first

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

keep if Year == Min | Year == Max
sort Fishery PermitNumber Year Seq

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
sort PermitNumber Year Seq

// Getting rid of first-year observations not associated with the first holder in that year
drop if Year == Min & Seq > 1

// Getting rid of last-year observations not associated with the last holder in that year
bysort PermitNumber Year: egen max_seq = max(Seq)
drop if Year == Max & Seq != max_seq 
drop max_seq
sort PermitNumber Year

// Assigning first observed zip to each permit
gen first_zip = .
order first_zip, after(ZipCode)
destring ZipCode first_zip, replace
replace first_zip = ZipCode if Year == Min 
replace first_zip = 0 if first_zip == .
egen sum = sum(first_zip), by(PermitNumber)
tab sum if Year == Min // None are zero. Great!
sort PermitNumber Year
bysort PermitNumber: egen fz_max = max(first_zip)
order fz_max, after(first_zip)
drop first_zip
rename fz_max first_zip

// Assigning last observed zip to each permit
gen last_zip = .
order last_zip, after(ZipCode)
replace last_zip = ZipCode if Year == Max 
replace last_zip = 0 if last_zip == .
drop sum
egen sum = sum(last_zip), by(PermitNumber)
tab sum if Year == Max // None are zero. Great!
sort PermitNumber Year
order last_zip, after(first_zip)
bysort PermitNumber: egen lz_max = max(last_zip)
order lz_max, after(last_zip)
drop last_zip
rename lz_max last_zip
sort PermitNumber Year
duplicates drop PermitNumber, force

// dropping unnecessary vars and cleaning up
drop Year ZipCode Seq Name PermitStatus SeqCheckDigit StartDate EndDate LastName FirstName Middle Suffix Street City State ForeignAddress Residency sum
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
sort Fishery
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
** Section 2: Making the inputs for an area map which shows how many permits     **
** exist in the system at any give time.                                         **
***********************************************************************************
{
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Test_215B", clear

// Dropping all entries for permits after they are cancelled 
drop if PermitStatus == "Permit cancelled"
duplicates drop PermitNumber Year, force

// Making area map counts by year (break this up by catch/region/etc in final version)
bysort Year: egen Permits_in_Yr = count(_n)
duplicates drop Year, force

twoway line Permits_in_Yr Year
}
