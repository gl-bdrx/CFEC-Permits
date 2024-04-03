// Making zip-to-zip flows dataset, starting from YearlyMoves.dta

// Importing and cleaning. 
use "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Scraping CFEC Website\YearlyMoves.dta", clear
sort start_zip end_zip
collapse (sum) number*, by(start_zip end_zip)
destring start_zip end_zip, replace force
drop if start_zip == .
drop if end_zip == .

// Grouping combinations of zip codes.
gen zipcombo1 = min(start_zip, end_zip) 
gen zipcombo2 = max(start_zip, end_zip) 
egen zip_combo_id = group(zipcombo1 zipcombo2), label 
sort zip_combo_id
egen count = count(_n), by(zip_combo_id)

// Defining Net importer variable, which defines which zip is the net importer.
gen net_importer = 0
replace net_importer = end_zip if count == 1
bysort zip_combo_id: egen max = max(number_permits)
bysort zip_combo_id: egen min = min(number_permits)
replace net_importer = 411 if max == min & count > 1 // identifier for zero net transfers
replace net_importer = end_zip if max == number_permits & net_importer != 411
replace net_importer = start_zip if net_importer == 0

// Defining Net exporter variable, which defines which zip is the net importer.
gen net_exporter = 0
order net_exporter, after(net_importer)
replace net_exporter = net_importer if net_importer == 411
replace net_exporter = start_zip if net_importer == end_zip
replace net_exporter = end_zip if net_exporter == 0

// Defining net transfers
gen net_transfers = max - min
bysort zip_combo_id: egen trading_volume = sum(number_permits)

// here, we can do something with intra, inter, re-sorts later. for now, abstracting away from this. ideas: Look at total re_sorts. Note: find how many unique permits went between each zip combo
collapse (mean) zipcombo1 zipcombo2 count net_importer net_exporter max min net_transfers trading_volume, by(zip_combo_id)
rename (zipcombo1 zipcombo2) (zip1 zip2)
rename (max min) (imports exports)

// Merging zipcode data back on

// First zip in combination.
rename zip1 zipcode
merge m:1 zipcode using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Zipcodes.dta"
drop if _merge == 2
drop _merge common_city_list timezone post_office_city area_code_list water_area_in_sqmi bounds_west bounds_east bounds_north bounds_south
rename (zipcode lat lng) (zip1 start_lat1 start_lgt1)

foreach x in zipcode_type major_city county state radius_in_miles population population_density land_area_in_sqmi housing_units occupied_housing_units median_home_value median_household_income {
	rename `x' `x'1
}

// Second zip in combination.
rename zip2 zipcode
merge m:1 zipcode using "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Permit Tracking Data\Zipcodes.dta"
drop if _merge == 2
drop _merge common_city_list timezone area_code_list water_area_in_sqmi bounds_west bounds_east bounds_north bounds_south post_office_city
rename (zipcode lat lng) (zip2 end_lat2 end_lgt2)

foreach x in zipcode_type major_city county state radius_in_miles population population_density land_area_in_sqmi housing_units occupied_housing_units median_home_value median_household_income {
	rename `x' `x'2
}

// Dropping un-merged combos. 389 of 23,000, or roughly 1% of transactions
sort zip_combo_id
drop if start_lat1 =="" | start_lgt1 == "" | end_lat2 == "" | end_lgt2 == ""

zip_combo_id 
zip1 
zip2 
count 
net_importer 
net_exporter 
imports 
exports 
net_transfers 
trading_volume 
zipcode_type1 
major_city1 
county1 
state1 
start_lat1 
start_lgt1 
radius_in_miles1 
population1 
population_density1 
land_area_in_sqmi1 
housing_units1 
occupied_housing_units1 
median_home_value1 
median_household_income1 
zipcode_type2 
major_city2 
county2 
state2 
end_lat2 
end_lgt2 
radius_in_miles2 
population2 population_density2 land_area_in_sqmi2 housing_units2 occupied_housing_units2 median_home_value2 median_household_income2

save "C:\Users\gboud\Dropbox\Reimer GSR\CFEC_permits\Mapping\Trial Run Migration Flows\Permanent_flows.dta", replace