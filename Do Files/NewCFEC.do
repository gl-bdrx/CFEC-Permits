*******************************************************
// Section 2: Recreated only using permanent permits **
*******************************************************

cd "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website"
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\PermanentPermitData.dta", clear


{
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
// Here, I am seeing how many permits come back online after cancellation.
frames put *, into(cancelled)
frame change cancelled
gen cancel = 0
replace cancel = 1 if PermitStatus == "Permit cancelled"
bysort PermitNumber: egen sum = sum(cancel)
keep if sum > 0
sort PermitNumber year Seq
drop sum
codebook PermitNumber, compact // 3186 unique permits were cancelled.
//dropping post-cancellation entries for cancelled permits
gen ind = 1
sort PermitNumber PermitStatus year
bysort PermitNumber PermitStatus: replace ind = 0 if _n !=1
drop if PermitStatus == "Permit cancelled" & ind == 0
sort PermitNumber year Seq
bysort PermitNumber: egen Max = max(year)
count if PermitStatus == "Permit cancelled" & year != Max 
codebook PermitNumber if PermitStatus == "Permit cancelled" & year != Max // 337 of 3186 cancelled permits come back online **PUT THIS IN SUMSTATS**
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
drop range ind2 sum cancelled sumcan max min


// making countmax variable- maximum number of yearly transfers per permit
egen countmax = max(Seq), by(PermitNumber)
order countmax, after(PermitNumber)
preserve
duplicates drop PermitNumber, force
tab countmax // 95% of permits have less than or equal to 4 maximum yearly entries. 
restore

// dropping entries with missing zip codes.
count if ZipCode == " " // 709
count if ZipCode == " " & ZipCode[_n-1] == ZipCode[_n+1] & ZipCode[_n-1] != " "
count if ZipCode == " " & Name[_n-1] == Name[_n+1] &  Name[_n+1] == Name & PermitNumber[_n-1] == PermitNumber[_n+1] &  PermitNumber[_n+1] == PermitNumber & ZipCode[_n-1] == ZipCode[_n+1] & ZipCode[_n-1] != " " // only 3
drop if ZipCode == " " // 709

// checking how this affects the number of permits missing years
bysort PermitNumber: egen max = max(year)
bysort PermitNumber: egen min = min(year)
gen range = max -min + 1
gen ind2 = 1
bysort PermitNumber year: replace ind2 = 0 if _n !=1
bysort PermitNumber: egen sum = sum(ind2)
codebook PermitNumber if range !=sum // 303. So this added 303 - 247 = 56 permits.

// when making the move category, also make an "indeterminate" option which corresponds to if the next entry is the same permit but not the next year.

// Now, preparing data for mapping. 
sort PermitNumber year Seq

// making lag and lead zip code variables 
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

count if nextyear != year+1 & nextyear !=year // 16,985
count if year+1 != nextyear & nextyear !=year & nextyear !=. // 326
codebook PermitNumber if year+1 != nextyear & nextyear !=year & nextyear !=. // 303. So this is totally due to permits which are missing zip codes and permits with cancellations. Nice!!!

// Decision rules: 
// If the entry and its next entry have the same name but different zip codes, this is coded as a re-sort. Some of these may be coded as permament or temporary transfers in the data, but I am making the executive decision to give owner names precedence.
// If an entry's PermitStatus is coded as "Permit holder; permanently transferred permit away" and the next entry is another person in another zip code, code this as a permanent transfer.
// If the NEXT entry's PermitStatus is coded as "Temporary holder through emergency transfer" and the next entry is another person in another zip code, code this as a temporary transfer. 

// making note of likely re-sorts labelled as permanent transfers
count if PermitStatus == "Permit holder; permanently transferred permit away" & Name[_n] == Name[_n+1] & ZipCode != nextZip & ZipCode != " " & nextZip != " " & PermitNumber[_n] == PermitNumber[_n+1] // 158 observations

// making note of likely re-sorts labelled as temporary transfers
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
count if temp_trans == 1 & perm_trans == 1 & Name[_n+1] == Name // None. This is good.

// this leaves the 94 observations which are still denoted as both permanent and temporary. 
// Examining. Idea: make 5 leads and see if they the lag name is there. If so, code as temp.
drop ind
forvalues x = 1/5 {
	gen name_lead_`x' = Name[_n+`x']
}
gen name_lag = Name[_n-1]
count if temp_trans == 1 & perm_trans == 1 & ( name_lag == name_lead_1 | name_lag == name_lead_2 | name_lag == name_lead_3 | name_lag == name_lead_4 | name_lag == name_lead_5 )

// recoding these as temporary.
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

// for now, just make these undetermined. 
replace undetermined = 1 if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 & undetermined == 0



drop sum
gen sum = re_sort + temp_trans + perm_trans + trans_back + undetermined
tab sum // all are 0 (no move) or 1 (move)


// dealing with cancellations
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

*SUM STATS*
tab years_cancelled
sum years_cancelled if years_cancelled > 0


sort PermitNumber year Seq
keep if move == 1
keep PermitNumber year Seq ZipCode nextZip move inter_year intra_year re_sort temp_trans trans_back perm_trans undetermined year_reinstated years_cancelled
rename (ZipCode nextZip) (start_zip end_zip)
sort year start_zip end_zip
count if start_zip == end_zip // should be 0. good.

foreach x in intra inter {
	foreach y in re_sort temp_trans trans_back perm_trans undetermined {
		gen `x'_`y' = 0
		replace `x'_`y' = 1 if `x'_year == 1 & `y' == 1
	}
}

// Keeping only if the move is a permanent transfer or a re sort. 
keep if perm_trans == 1 | re_sort == 1

// dropping unnecessary counter variables which correspond to moves no longer in the data. 
drop temp_trans trans_back year_reinstated years_cancelled undetermined intra_temp_trans intra_trans_back inter_temp_trans inter_trans_back inter_undetermined intra_undetermined

foreach x in move re_sort perm_trans intra_year inter_year intra_re_sort intra_perm_trans inter_re_sort inter_perm_trans {
	bysort year start_zip end_zip: egen sum = sum(`x')
	rename sum number_`x'
}

gen ind = 1
bysort PermitNumber year start_zip end_zip: replace ind = 0 if _n >1
bysort year start_zip end_zip: egen sum = sum(ind)
drop ind
rename sum number_permits

bysort year start_zip end_zip: keep if _n ==1

drop PermitNumber Seq PermitNumber Seq perm_trans move inter_year intra_year re_sort intra_re_sort intra_perm_trans inter_re_sort inter_perm_trans

// making summary variables
//checking whether intra and inter sum to the total number of moves (they do)
gen sum = number_move - number_intra_year - number_inter_year
tab sum
drop sum
//checking whether move types sum to the total number of moves (they mostly do but 461 do not due to the above issues which I am goign to rectify)
gen sum2 = number_move - number_re_sort - number_perm_trans 
tab sum2
drop sum2

save temp.dta, replace
use temp.dta, clear

** MAKE AREA CHART OF MOVES HERE **
collapse (sum) number_move number_re_sort number_perm_trans number_intra_year number_inter_year number_intra_re_sort number_intra_perm_trans number_inter_re_sort number_inter_perm_trans number_permits, by(year)

label var number_move "Total moves"
label var number_intra_year "Intra-year moves"
label var number_inter_year "Inter-year moves"
label var number_re_sort "Re-sorts"
label var number_perm_trans "Permanent Transfers"
label var number_intra_re_sort "Intra-year Re-sorts"
label var number_intra_perm_trans "Intra-year Permanent Transfers"
label var number_inter_re_sort "Inter-year Re-sorts"
label var number_inter_perm_trans "Inter-year Permanent Transfers"
}

******************************************************************
// area chart of moves broken out by intra- and inter-year
twoway line number_move number_intra_year number_inter_year year
// area chart of moves broken out by permanent vs re-sorts.
twoway line number_move number_re_sort number_perm_trans year
******************************************************************


cd "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website"
// making a permit-to-fishery crosswalk to merge on later.
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\PermanentPermitData.dta", clear

keep PermitNumber fishery descrip catch_descrip gear_descrip location_descrip descrip
duplicates drop PermitNumber, force
save PermitToFisheryCrosswalk.dta, replace

use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\PermanentPermitData.dta", clear


{
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
drop range ind2 sum cancelled sumcan max min


// dropping entries with missing zip codes.
count if ZipCode == " " // 709
count if ZipCode == " " & ZipCode[_n-1] == ZipCode[_n+1] & ZipCode[_n-1] != " "
count if ZipCode == " " & Name[_n-1] == Name[_n+1] &  Name[_n+1] == Name & PermitNumber[_n-1] == PermitNumber[_n+1] &  PermitNumber[_n+1] == PermitNumber & ZipCode[_n-1] == ZipCode[_n+1] & ZipCode[_n-1] != " " // only 3
drop if ZipCode == " " // 709

// checking how this affects the number of permits missing years
bysort PermitNumber: egen max = max(year)
bysort PermitNumber: egen min = min(year)
gen range = max -min + 1
gen ind2 = 1
bysort PermitNumber year: replace ind2 = 0 if _n !=1
bysort PermitNumber: egen sum = sum(ind2)
codebook PermitNumber if range !=sum // 303. So this added 303 - 247 = 56 permits.


// Now, preparing data for mapping. 
sort PermitNumber year Seq

// making lag and lead zip code variables 
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

count if nextyear != year+1 & nextyear !=year // 16,985
count if year+1 != nextyear & nextyear !=year & nextyear !=. // 326
codebook PermitNumber if year+1 != nextyear & nextyear !=year & nextyear !=. // 303. So this is totally due to permits which are missing zip codes and permits with cancellations. Nice!!!

// Decision rules: 
// If the entry and its next entry have the same name but different zip codes, this is coded as a re-sort. Some of these may be coded as permament or temporary transfers in the data, but I am making the executive decision to give owner names precedence.
// If an entry's PermitStatus is coded as "Permit holder; permanently transferred permit away" and the next entry is another person in another zip code, code this as a permanent transfer.
// If the NEXT entry's PermitStatus is coded as "Temporary holder through emergency transfer" and the next entry is another person in another zip code, code this as a temporary transfer. 

// making note of likely re-sorts labelled as permanent transfers
count if PermitStatus == "Permit holder; permanently transferred permit away" & Name[_n] == Name[_n+1] & ZipCode != nextZip & ZipCode != " " & nextZip != " " & PermitNumber[_n] == PermitNumber[_n+1] // 158 observations

// making note of likely re-sorts labelled as temporary transfers
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
count if temp_trans == 1 & perm_trans == 1 & Name[_n+1] == Name // None. This is good.

// this leaves the 94 observations which are still denoted as both permanent and temporary. 
// Examining. Idea: make 5 leads and see if they the lag name is there. If so, code as temp.
drop ind
forvalues x = 1/5 {
	gen name_lead_`x' = Name[_n+`x']
}
gen name_lag = Name[_n-1]
count if temp_trans == 1 & perm_trans == 1 & ( name_lag == name_lead_1 | name_lag == name_lead_2 | name_lag == name_lead_3 | name_lag == name_lead_4 | name_lag == name_lead_5 )

// recoding these as temporary.
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

// for now, just make these undetermined. 
replace undetermined = 1 if move == 1 & re_sort == 0 & temp_trans == 0 & trans_back == 0 & perm_trans == 0 & undetermined == 0



drop sum
gen sum = re_sort + temp_trans + perm_trans + trans_back + undetermined
tab sum // all are 0 (no move) or 1 (move)


// dealing with cancellations
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

*SUM STATS*
tab years_cancelled
sum years_cancelled if years_cancelled > 0


sort PermitNumber year Seq
keep if move == 1
keep PermitNumber year Seq ZipCode nextZip move inter_year intra_year re_sort temp_trans trans_back perm_trans undetermined year_reinstated years_cancelled
rename (ZipCode nextZip) (start_zip end_zip)
sort year start_zip end_zip
count if start_zip == end_zip // should be 0. good.

foreach x in intra inter {
	foreach y in re_sort temp_trans trans_back perm_trans undetermined {
		gen `x'_`y' = 0
		replace `x'_`y' = 1 if `x'_year == 1 & `y' == 1
	}
}

// Keeping only if the move is a permanent transfer or a re sort. 
keep if perm_trans == 1 | re_sort == 1

// dropping unnecessary counter variables which correspond to moves no longer in the data. 
drop temp_trans trans_back year_reinstated years_cancelled undetermined intra_temp_trans intra_trans_back inter_temp_trans inter_trans_back inter_undetermined intra_undetermined inter_year intra_year intra_re_sort intra_perm_trans inter_re_sort inter_perm_trans

merge m:1 PermitNumber using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\PermitToFisheryCrosswalk.dta"
drop if _merge == 2
drop _merge

// fishery-year
foreach x in move re_sort perm_trans {
	bysort year fishery: egen sum = sum(`x')
	rename sum fishery_yr_`x'
}

// catch-year
// first, redefining catch
replace catch_descrip = "HERRING" if ustrpos(catch_descrip, "HERRING")>0
replace catch_descrip = "OTHER" if catch_descrip != "SALMON" & catch_descrip != "HERRING"
foreach x in move re_sort perm_trans {
	bysort year catch_descrip: egen sum = sum(`x')
	rename sum catch_yr_`x'
}


// location-year
// redefining location
replace location_descrip = "SOUTHEAST" if ustrpos(location_descrip, "SOUTHEAST") > 0

foreach x in move re_sort perm_trans {
	bysort year location_descrip: egen sum = sum(`x')
	rename sum location_yr_`x'
}


gen ind = 1
bysort PermitNumber year start_zip end_zip: replace ind = 0 if _n >1
bysort year start_zip end_zip: egen sum = sum(ind)
drop ind
rename sum number_permits

drop PermitNumber Seq start_zip end_zip perm_trans re_sort move 
}

save temp.dta, replace
use temp.dta, clear

*************************************************************************************
// area charts of moves by fishery

use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\PermanentPermitData.dta", clear
duplicates drop fishery, force
keep fishery current_descrip
save fisherycrosswalk.dta

use temp.dta, clear
collapse(mean) fishery_yr_move fishery_yr_re_sort fishery_yr_perm_trans, by(fishery year)
bysort fishery: egen total_moves = sum(fishery_yr_move)
sort total_moves fishery year
frames put *, into(new)
frame change new
collapse (mean) total_moves, by(fishery)
gsort -total_moves
gen order = _n

frame change default
frlink m:1 fishery, frame(new)
frget order, from(new)
keep if order <=10 // keeping only 10 most transfer-prevalent fisheries (on avg)
frame drop new
label var fishery_yr_move "Total moves"
label var fishery_yr_perm_trans "Permanent transfers"
label var fishery_yr_re_sort "Re-sorts"

twoway line fishery_yr_move fishery_yr_re_sort fishery_yr_perm_trans year, by(fishery, title(Yearly moves among 10 highest-volume fisheries))


// area charts of moves by catch 
use temp.dta, clear
collapse(mean) catch_yr_move catch_yr_re_sort catch_yr_perm_trans, by(catch_descrip year)

label var catch_yr_move "Total moves"
label var catch_yr_perm_trans "Permanent transfers"
label var catch_yr_re_sort "Re-sorts"

twoway line catch_yr_move catch_yr_re_sort catch_yr_perm_trans year, by(catch_descrip)

// area charts of moves by location
use temp.dta, clear
collapse(mean) location_yr_move location_yr_re_sort location_yr_perm_trans, by(location_descrip year)
bysort location_descrip: egen total_moves = sum(location_yr_move)
sort total_moves location_descrip year
frames put *, into(new)
frame change new
collapse (mean) total_moves, by(location_descrip)
gsort -total_moves
gen order = _n

frame change default
frlink m:1 location_descrip, frame(new)
frget order, from(new)
keep if order <=6 // keeping only 6 most transfer-prevalent locations (on avg)
frame drop new

label var location_yr_move "Total moves"
label var location_yr_perm_trans "Permanent transfers"
label var location_yr_re_sort "Re-sorts"

twoway line location_yr_move location_yr_re_sort location_yr_perm_trans year, by(location_descrip, title(Yearly moves among 6 highest-volume fishery locations))

************************************************************************************

