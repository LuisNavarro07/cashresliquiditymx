************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu

** Script: Master Do File
************************************************************************
clear 
set obs 100
gen id = mod(_n - 1, 31) + 1
gen qofd = _n + 154
fillin id qofd 
format qofd %tq
xtset id qofd
drop _fillin
tempfile ratings_template
save `ratings_template'
** import data 

import excel "${bi}\ratings_hr.xlsx", sheet("Sheet1") firstrow clear allstring
destring quarter year, replace 
tempfile hr_ratings 
save `hr_ratings', replace 

import delimited "${bi}\fitch_ratings_clean_ind.csv", varnames(1) clear 
/// data import for guanajuato was wrong 
drop if state == "guanajuato"
append using `hr_ratings'
keep date rating action state quarter year
gen qofd = qofd(mdy(quarter*3,1,year))
format qofd %tq
gen edate = date(date, "DMY", 2050)
format edate %td
drop date 
rename edate date 
sort state date 
egen id = group(state)
sort state date
/// Assumption Last Rating on the Quarter 
collapse (first) rating action (mean) date year quarter, by(id state qofd)
tempfile ratings
save `ratings', replace 

use `ratings_template', clear
merge 1:1 id qofd using `ratings', keep(match master) nogen
xtset id qofd
sort id qofd
xfill state
drop quarter year date 
gen quarter = quarter(dofq(qofd))
gen year = year(dofq(qofd))

bysort id: carryforward rating action, replace 
keep if year >= 2017 & year <= 2022
/// Nayarit Assumption: I dont have data for 2017. So I assume it has the rating it observed in 2018. 
replace rating = "A-(mex)" if state == "nayarit" & rating == ""
tab state
tab rating
save "${bt}\ratings_mexico_clean.dta", replace 

