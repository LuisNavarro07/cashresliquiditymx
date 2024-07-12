************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu
** Script: Descriptive Statistics and Graphs 
************************************************************************

/// Instrumental Variable: Budget Error
use "${bt}\budget_error_monthly.dta", clear 
/// Quarter data 
gen qofd = qofd(mdy(month,1,year))


global line1 lcolor(black) lpatter(solid) lwidth(medium) mcolor(black) msize(small) msymbol(circle)
global line2 lcolor(cranberry) lpattern(dash) lwidth(medium) mcolor(cranberry) msize(small) msymbol(triangle)
global line3 lcolor(ebblue) lpattern(solid) lwidth(medium) mcolor(ebblue) msize(small) msymbol(square)
global gr_opts ylabel(#10, labsize(small) angle(0) nogrid) xlabel(#36, labsize(small) angle(90) nogrid) xtitle("", size(small)) ytitle("", size(small)) title(, size(medium) pos(11)) legend(row(1) size(small) ring(0) position(11) bmargin(small))
 
/// Monthly Graph 
gcollapse (sum) fgp_paid fgp_budget (mean) budget_error budget_diff, by(date)
gen budget_diff_cum = fgp_paid - fgp_budget
gen budget_error_cum = fgp_paid/fgp_budget - 1 
gen year = year(dofm(date))
gen month = month(dofm(date))

tabstat budget_error, by(year) stat(mean min max) format(%12.4fc)

table month year, content(mean budget_error) format(%12.4fc)

twoway (line fgp_paid date, $line1) (line fgp_budget date, $line2), legend(on order(1 "Paid" 2 "Budget")) title("FGP: General Participations Fund (millions of pesos)") name(gr1, replace) $gr_opts 

twoway (line budget_error date, $line1), $gr_opts name(gr2, replace) title("FGP Budget Error: Paid - Budgeted (% Percentage)") yline(0,  lcolor(black) lpatter(dot) lwidth(medthin)) 

graph combine gr1 gr2, rows(1) cols(2) xcommon name(gr_combined, replace) xsize(16) ysize(8)
graph export "${ao}\BudgetError.pdf", replace 

***********************************************

use "${bt}\clean_fin_pub.dta", clear
/// Replace year to restore the real values for graphs 
replace year = year - 1 


/* 
** current_exp = gas_servicios_personales + gas_servicios_generales + gas_materiales_sumi + gas_transferencias 
** cap_outlays = gas_bienes_inmuebles + gas_inversion 
** exp_tot = current_exp + gas_participaciones_munis + cap_outlays + gas_deuda 
*/
local bar1 fcolor(ebblue) lcolor(ebblue) lwidth(none)
local bar2 fcolor(cranberry) lcolor(navy) lwidth(none)
local bar3 fcolor(gray) lcolor(gray) lwidth(none)
local bar4 fcolor(green) lcolor(green) lwidth(none)

graph bar (mean) ing_aportaciones ing_participaciones ing_locales, over(year) percentages stack bar(1, `bar1') bar(2, `bar2') bar(3, `bar3') ytitle("")  title("Revenues Composition (% Total Revenues)", size(medium) pos(11)) name(revenue_comp, replace) legend(on order(1 "Earmarked Transfers" 2 "FGP: Discretionary Transfers" 3 "Own Source Revenue") rows(2) size(small) pos(6))

graph bar (mean) current_exp gas_participaciones_munis gas_deuda cap_outlays, over(year) percentages stack bar(1, `bar1') bar(2, `bar2') bar(3, `bar4') bar(4, `bar3') ytitle("")  title("Expenditures Composition (% Total Expenditures)", size(medium) pos(11)) name(exp_comp, replace) legend(on order(1 "Current Expenditure" 2 "IG Transfers" 3 "Debt Service" 4 "Capital Outlays") rows(2) size(small) pos(6))

graph combine revenue_comp exp_comp, ycommon name(comp_combined, replace) xsize(16) ysize(8) rows(1) cols(2)
graph export "${ao}\Revenues_Expenditures.pdf", replace 

********************************************************************************
/// Short Term Borrowing Graph 
use "${ai}\panel_mexico_governments_clean.dta", clear 
gcollapse (mean) corto_plazo* cash* budget_error*, by(date)

twoway (line corto_plazo_ild date, $line1) (line budget_error_ild date, $line2) (line cash_ild date, $line3), legend(on order(1 "Short Term Debt" 2 "Budget Error" 3 "Cash Reserves")) title("Short Term Borrowing and FGP Budget Error (\% of DR)") name(gr0, replace) $gr_opts xlabel(#21)


*********************************************************************************

/// Descriptive Statistics 
***** Table 1: Descriptive Statistics 

use "${ai}\panel_mexico_governments_clean.dta", clear 
global texopts autonumber varlabels nofix replace frag 
xtset id date 
global controls balance rating_group part_aff_st share_current share_ild share_ltdebt
global outcome corto_plazo_ild
global independent cash_ild 
global instrument budget_error_ild
global variables $outcome $independent $instrument $controls

***** Table 2: Descriptive Statistics
***** Rows: Variables in the Regression: Outcome, indep, instrument, controls. 
***** Columns: Statistics: Mean, Std Dev, 25th Pctile, Median, 75th Pctile, N" 
sum $variables 
matrix define S = J(9,7,.)
matrix rownames S =  "outcome" "indep" "instrument" "balance" "rating" "part_aff" "current_exp" "share_ild" "share_ltdebt"
matrix colnames S = "Mean" "SD" "P25" "Median" "P75" "Max" "N"
local i = 1
local varlist $variables
foreach var of local varlist {
/// Summarize the Variable using the same conditional as in the model. 
qui sum `var' , detail 
matrix S[`i',1] = r(mean)
matrix S[`i',2] = r(sd)
matrix S[`i',3] = r(p25)
matrix S[`i',4] = r(p50)
matrix S[`i',5] = r(p75)
matrix S[`i',6] = r(max)
matrix S[`i',7] = r(N)
local i = `i' + 1
}

esttab mat(S, fmt(4))

**** Export the Results in Tables 

**** Table 1. Descriptive Statistics 

clear 
svmat S
gen var = ""
order var 
        
replace var = "Short-Term Debt (\% DR)" if _n == 1
replace var = "Cash Reserves (\% DR)" if _n == 2
replace var = "FGP Budget Error (\% DR)" if _n == 3
replace var = "Net Operating Balance (\% DR)" if _n == 4
replace var = "Credit Rating" if _n == 5
replace var = "\% FGP Securing LT debt" if _n == 6
replace var = "Current Expenditure (\% Total Expenditure)" if _n == 7
replace var =  "Discretionary Revenue (\% Total Revenue)" if _n == 8
replace var = "Long Term Debt (\% Total Debt)" if _n == 9
**** 


/// Label Variables 
label variable S1 "Mean"
label variable S2 "SD"
label variable S3 "P25"
label variable S4 "P50"
label variable S5 "P75"
label variable S6 "Max"
label variable S7 "N"
format S1 S2 S3 S4 S5 S6 %12.3fc
format S7 %12.0fc


qui tostring S1 S2 S3 S4 S5 S6, replace force
local varlist S1 S2 S3 S4 S5 S6
foreach var of local varlist {
qui gen point_pos = strpos(`var',".")
qui replace `var' = substr(`var',1,point_pos + 4) 
qui replace `var' = "0" + `var' if strpos(`var',".") == 1
qui replace `var' = `var' + ".0000" if strpos(`var',".") == 0
qui replace `var' = `var' + "000" if length(`var') == 3
qui drop point_pos
}

drop S6
list


*** Export the Table qui label define rating_group 1 "AAA,AA" 2 "A" 3 "BBB,BB,NR"
local title "Descriptive Statistics"
local fn "Notes: This panel show the descriptive statistics of the main variables used for the analysis. The first two columns show the sample mean and standard deviation. P25, P50 and P75 show the 25, 50 and 75 percentiles, respectively. Credit rating is coded such that a higher number is associated with a higher credit rating. Considering the distribution of ratings I grouped them in 3 categories AAA,AA = 1, A = 2, and BBB,BB,NR = 3. Short-Term borrowing, cash reserves, FGP budget error, and Net Operating Balance are expressed as a percentage of the average discretionary revenues (DR) observed between 2009 and 2016. That is, outside the analysis period to avoid endogeneity concerns. Net operating balance, current expenditures, and discretionary revenues correspond to one year lagged measures. "
texsave using "${ao}\table1_descriptivestats.tex", marker(tab:table1_descriptivestats) title("`title'") footnote("`fn'") $texopts hlines(0)


*******************************************************************************

*** Table 2. Balance Table 

clear 
svmat M
gen var = ""
order var 
replace var = "TIC Spread" if _n == 1
replace var = "Bond Issues (Log)" if _n == 2
replace var = "Amount Issued (Log)" if _n == 3
replace var = "Unemployment Rate" if _n == 4
replace var = "Call Provision" if _n == 5
replace var = "Credit Rating" if _n == 6
replace var = "Cuopon Rate" if _n == 7
replace var = "Years to Maturity" if _n == 8
replace var = "Sales Tax" if _n == 9
replace var = "Property Tax" if _n == 10
replace var = "Current Expenditure" if _n == 11
replace var = "Population Threshold" if _n == 12
replace var = "N" if _n == 13
**** 


/// Label Variables 
label variable M1 "Mean"
label variable M2 "S.E."
label variable M3 "Mean"
label variable M4 "S.E."
label variable M5 "Pvalue T-test"
format M1 M2 M3 M4 M5 %12.4fc


/// Stars on Tables 
gen stars = 0 
replace stars = 1 if inrange(M5,0.05,0.10) 
replace stars = 2 if inrange(M5,0.01,0.049)
replace stars = 3 if inrange(M5,0,0.009)   


qui tostring M1 M2 M3 M4 M5, replace force
foreach var of varlist M1 M2 M3 M4 M5 {
qui gen point_pos = strpos(`var',".")
qui replace `var' = substr(`var',1,point_pos + 4) 
qui replace `var' = "0" + `var' if strpos(`var',".") == 1
qui replace `var' = `var' + ".0000" if strpos(`var',".") == 0
qui replace `var' = `var' + "000" if length(`var') == 3
qui drop point_pos 
}


replace M5 = M5 + "\sym{*}"   if stars == 1
replace M5 = M5 + "\sym{**}"  if stars == 2
replace M5 = M5 + "\sym{***}" if stars == 3
replace M2 = "(" + M2 + ")" 
replace M4 = "(" + M4 + ")" 

drop stars

replace M2 = "" if var == "N"
replace M4 = "" if var == "N"
replace M5 = "" if var == "N"
list

*** Export the Table 
local title "Outcomes and Covariates Balance across CRF status"
local fn "Notes: This table shows the comparison of the sample mean (along with its standard errors) of the main dependent and independent variables used for the empirical analysis. Column (5) reporst the p-value from a t-test on the mean difference on the variable across treatment status (i.e. being a CRF recipient county). Credit rating is coded such that a higher number is associated with a lower credit rating. AAA = 1, AA = 2, A = 3, and BBB = 4. Sales tax, property tax, and current expenditure are expressed as percentage of total revenues (for the first two) and expenditures (for the latter one). Population thershold is expressed in thousands of people."
local headerlines "{}&\multicolumn{2}{c}{Non-Recipient Counties} & \multicolumn{2}{c}{CRF Recipients}" "\cmidrule(cr){2-3} \cmidrule(cr){4-5}"
texsave using "${ao}\table2_balance_primary.tex",  marker(tab:table2_balance_primary) title("`title'") footnote("`fn'") headerlines("`headerlines'") $texopts hlines(-1)



exit 

