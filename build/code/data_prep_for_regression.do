************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu

** Script: Data Prep For Regression
************************************************************************

********************************************************************************
/// Panel of Governments 
qui use "${bt}\clean_cash_debt_data.dta", clear 
qui merge 1:1 state qofd using "${bt}\ratings_mexico_clean.dta", keep(match master) nogen 
qui merge 1:1 state qofd using "${bt}\budget_error_quarterly.dta", keep(match master) nogen 
qui merge m:1 state year using "${bt}\clean_fin_pub.dta", keep(match master) nogen 
qui rename cortoplazoquirografario corto_plazo
qui drop if state == "ciudad de mexico"

// Restrict the sample 
qui drop if qofd < tq(2017q4)
qui mdesc cash_eq ocp pc corto_plazo subtotal budget_error
qui xtset id_entidad qofd
qui gen rating_cont = 0 
qui replace rating_cont = 1 if rating == "AAA(mex)"
qui replace rating_cont = 2 if rating == "AA+(mex)" | rating == "AA(mex)" | rating == "AA-(mex)"  
qui replace rating_cont = 3 if rating == "A+(mex)" | rating == "A(mex)" | rating == "A-(mex)" 
qui replace rating_cont = 4 if rating == "BBB+(mex)" | rating == "BBB(mex)" | rating == "BBB-(mex)" 
qui replace rating_cont = 5 if rating == "BB+(mex)" | rating == "BB(mex)" | rating == "BB-(mex)" 
qui replace rating_cont = 6 if rating == "RD(mex)" | rating == "WD(mex)" 
/// Not received a rate equals to zero. This is assigning Nayarit, Guanajuato, Tabasco y Yucatan as not rated. 
qui replace rating_cont = 6 if rating == "" 
qui label define rating_cont 1 "AAA" 2 "AA" 3 "A" 4 "BBB" 5 "BB" 6 "NR"
qui label values rating_cont rating_cont
/// Big Rating Categories 
qui gen rating_group = 0
/// Tier 1 = AAA and AA 
qui replace rating_group = 1 if rating_cont == 1 | rating_cont == 2 
/// Tier 2 = A 
qui replace rating_group = 2 if rating_cont == 3
/// Tier 3 = BBB or Below
qui replace rating_group = 3 if rating_cont == 4 | rating_cont == 5 | rating_cont == 6 
qui label define rating_group 1 "AAA,AA" 2 "A" 3 "BBB,BB,NR"
qui label values rating_group rating_group
tab rating_group
 /// Generate Outcome Variables 
qui gen corto_plazo_ild = corto_plazo/mean_ild
qui gen corto_plazo_curr = corto_plazo/mean_current
qui gen corto_plazo_it = corto_plazo/ing_tot
qui gen share_corto_pasivos = ocp / (ocp + pc)
qui gen stliab_ild = (corto_plazo + pc)/mean_ild
/// Generate Independent Variables 
qui gen cash_ild = cash_eq/mean_ild
qui gen cash_curr = cash_eq/mean_current 
/// Generate Instruments 
qui gen budget_error_ild = budget_diff/mean_ild
qui gen budget_error_curr = budget_diff/mean_current
*replace budget_error_ild = budget_error
/// Generate Controls 
qui gen share_ltdebt = participaciones / mean_ild
qui rename qofd date 
/// Increase in Short Term Debt 
qui sort state date
qui gen delta_corto_aux = 0 
qui bysort state: replace delta_corto_aux = corto_plazo[_n]/corto_plazo[_n-1] -1
qui bysort state: replace delta_corto_aux = corto_plazo[_n] if  corto_plazo[_n] > 0 & corto_plazo[_n-1] == 0 
/// Variable for increase in short term debt 
qui gen delta_corto = 0 
/// Assumption: delta corto = 1 if government increased debt. 
qui replace delta_corto = 1 if delta_corto_aux >= 0 & delta_corto_aux != . 
// Identify states that did not issue debt at any point 
qui bysort state: egen avg_debt = mean(corto_plazo)  
qui bysort state: gen active_short_term = avg_debt > 0 

*
*drop if rating == ""
save "${ai}\panel_mexico_governments_clean.dta", replace 

********************************************************************************
/// Clean Loan Level Data 

use "${bi}\rpu_clean.dta", clear 

replace state = trim(lower(state))
replace issuer = trim(lower(issuer))
replace state = "ciudad de mexico" if state == "ciudad de mÉxico"
replace state = "ciudad de mexico" if state == "ciudad de méxico"
replace state = "coahuila" if state == "coahuila de zaragoza"
replace state = "michoacan" if state == "michoacÁn"
replace state = "michoacan" if state == "michoacán de ocampo"
replace state = "mexico" if state == "mÉxico"
replace state = "mexico" if state == "méxico"
replace state = "nuevo leon" if state == "nuevo leÓn"
replace state = "nuevo leon" if state == "nuevo león"
replace state = "queretaro" if state == "querÉtaro"
replace state = "queretaro" if state == "querétaro"
replace state = "san luis potosi" if state == "san luis potosÍ"
replace state = "san luis potosi" if state == "san luis potosí"
replace state = "veracruz" if state == "veracruz de ignacio de la llave"
replace state = "yucatan" if state == "yucatÁn"
replace state = "yucatan" if state == "yucatán"

replace spread = "" if spread == "A Determinar"
replace issuer = "gobierno del estado" if strpos(issuer, "estado de") > 0
keep if issuer == "gobierno del estado"



gen date = qofd(date(issue_date, "MDY",2050))
format date %tq
drop if date < tq(2017q4)
merge m:1 state date using "${ai}\panel_mexico_governments_clean.dta", keep(match master) nogen
destring spread outstanding_last, replace 
drop if budget_error_ild == . 

//

/// Remove this. This is just for a test 
*replace corto_plazo_ild = ln(1+corto_plazo)
*replace cash_ild = ln(1+cash_eq)
*replace budget_error_ild = budget_error

save "${ai}\loan_data_clean.dta", replace 