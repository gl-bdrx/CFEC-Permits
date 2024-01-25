// Do file to transform scraped spreadsheets from CFEC into .dta files
// Author: Greg Boudreaux
// Date: January 2024

// Preliminaries: Make sure that all .xls files are in the same directory

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
order PermitNumber, after(PermitSerial)
drop PermitSerial PermitSerialCheckDigit
destring Year Seq, replace
drop if PermitType != "Permanent"
sort PermitNumber Year Seq