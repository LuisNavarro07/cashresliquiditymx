************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu

** Script: Master Do File
************************************************************************
clear all 

/// Calendar of Participaciones
import delimited "${bi}\calendar_fgp.csv", varnames(1) case(lower) clear encoding()
drop anual 
rename ïstate state
reshape long m , i(state year) j(month) 
replace state = "ciudad de mexico" if state == "ciudad de mÃ©xico"
replace state = "michoacan" if state == "michoacÃ¡n"
replace state = "mexico" if state == "mÃ©xico"
replace state = "nuevo leon" if state == "nuevo leÃ³n"
replace state = "queretaro" if state == "querÃ©taro"
replace state = "san luis potosi" if state == "san luis potosÃ­"
replace state = "yucatan" if state == "yucatÃ¡n"
rename m fgp_budget
replace fgp_budget = lower(subinstr(fgp_budget, ",", "", .))
destring fgp_budget, replace 
tempfile fgp_budget
save `fgp_budget', replace 

/// Paid Participaciones
import delimited "${bi}\transferencias_entidades_fed.csv", varnames(1) case(lower) clear
/// Only Fondo General de Participaciones 
gen fgpdum = regexm(nombre, "Fondo General de Participaciones")
keep if fgpdum == 1 
/// After 2017 
keep if ciclo >= 2017 & ciclo <= 2022
qui gen month = 0 
qui replace month = 1 if mes == "Enero"
qui replace month = 2 if mes == "Febrero"
qui replace month = 3 if mes == "Marzo"
qui replace month = 4 if mes == "Abril"
qui replace month = 5 if mes == "Mayo"
qui replace month = 6 if mes == "Junio"
qui replace month = 7 if mes == "Julio"
qui replace month = 8 if mes == "Agosto"
qui replace month = 9 if mes == "Septiembre"
qui replace month = 10 if mes == "Octubre"
qui replace month = 11 if mes == "Noviembre"
qui replace month = 12 if mes == "Diciembre"

gen state = lower(subinstr(nombre, ": Fondo General de Participaciones", "", .))
drop if state == "total"
rename (ciclo monto) (year fgp_paid)
keep state year month fgp_paid
replace state = "ciudad de mexico" if state == "distrito federal"
replace state = "michoacan" if state == "michoac?n"
replace state = "mexico" if state == "m?xico"
replace state = "nuevo leon" if state == "nuevo le?n"
replace state = "queretaro" if state == "quer?taro"
replace state = "san luis potosi" if state == "san luis potos?"
replace state = "yucatan" if state == "yucat?n"
drop if state == "no distribuible"
//// Merge both 
merge 1:1 state month year using `fgp_budget', keep(match master) nogen
mdesc 
/// Millions of Pesos 
replace fgp_paid = fgp_paid/1000
replace fgp_budget = fgp_budget/1000000
/// Budget Error 
gen budget_diff = fgp_paid - fgp_budget
gen budget_error = fgp_paid/fgp_budget - 1

gen date = mofd(mdy(month,1,year))
format date %tmMon_CCYY
save "${bt}\budget_error_monthly.dta", replace 

drop budget_diff budget_error


/// Quarter data 
gen qofd = qofd(mdy(month,1,year))

gcollapse (sum) fgp_budget fgp_paid, by(state qofd)
format qofd %tq
/// Budget Error 
gen budget_diff = fgp_paid - fgp_budget
gen budget_error = fgp_paid/fgp_budget - 1

save "${bt}\budget_error_quarterly.dta", replace 
/// Graph 1: 

