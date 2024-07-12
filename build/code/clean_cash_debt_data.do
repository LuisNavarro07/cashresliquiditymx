************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu

** Script: Clean Cash and Debt Data
************************************************************************

import delimited "${bi}\clean_data_state_governments_mx.csv", varnames(1) case(lower) clear
/// Kepp years 
keep if year >= 2017 & year <= 2022
drop if quarter == 5

gen qofd = qofd(mdy(quarter*3,1,year))
format qofd %tq

/// Date Assumption 
drop if qofd < tq(2017q4)

replace state = "ciudad de mexico" if state == "ciudad de mÃ©xico"
replace state = "michoacan" if state == "michoacÃ¡n"
replace state = "mexico" if state == "estado de mÃ©xico"
replace state = "nuevo leon" if state == "nuevo leÃ³n"
replace state = "queretaro" if state == "querÃ©taro"
replace state = "san luis potosi" if state == "san luis potosÃ­"
replace state = "yucatan" if state == "yucatÃ¡n"


foreach var of varlist cash_eq ocp pc participaciones aportaciones subtotal ingresoslocales cortoplazoquirografario v11 part_aff_st part_aff_mun {
    replace `var' = subinstr(`var', "n.a.","0",.)
    replace `var' = subinstr(`var', ",", "", .)
	replace `var' = subinstr(`var', " ", "", .)
    replace `var' = "0" if  `var' == "-"
	destring `var', replace
}

foreach var of varlist ind1 ind2 ind3 {
    replace `var' = subinstr(`var', "%", "", .)
	destring `var', replace
	replace `var' = `var'/100
}

// ILDs 
replace ild = v11 if ild == . 
drop v11 

/// Exclude Tlaxcala 
drop if state == "tlaxcala"

mdesc

save "${bt}\clean_cash_debt_data.dta", replace 