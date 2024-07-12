************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu

** Script: Loan Level Data Regression Analysis 
************************************************************************
local coef1 mcolor(black) msymbol(circle) msize(medium) ciopts(recast(rcap) fcolor(black) fintensity(inten10) lcolor(black))
local coef2 mcolor(cranberry) msymbol(square) msize(medium) ciopts(recast(rcap) fcolor(cranberry) fintensity(inten10) lcolor(cranberry))
local coef3 mcolor(navy) msymbol(triangle) msize(medium) ciopts(recast(rcap) fcolor(navy) fintensity(inten10) lcolor(navy))
local coef4 mcolor(dkgreen) msymbol(diamond) msize(medium) ciopts(recast(rcap) fcolor(dkgreen) fintensity(inten10) lcolor(dkgreen))
global coefopts ylabel(, labsize(medsmall) angle(0) nogrid) xlabel(,angle(0) labsize(medsmall)) xline(0,lcolor(black) lpattern(solid) lwidth(vthin))


********************************************************************************


/// Types of Models 

local title1 "Effect of Cash Reserves on Borrowing Costs (Only Short-Term)"
local title2 "Effect of Cash Reserves on Borrowing Costs (Only Refinancings)"
local title3 "Effect of Cash Reserves on Borrowing Costs (Both)"

local conditional1 payment_source == "QUIROGRAFARIO" &  type == "CREDITO CORTO PLAZO" 
local conditional2 payment_source == "FGP" & use_proceeds == "REFINANCIAMIENTO"
local conditional3 `conditional1' | `conditional2'

local file1 "Regression_ShortTermLoans"
local file2 "Regression_Refinancings"
local file3 "Regression_ShortTermAndRefinancings"


local fn "Notes: Panel A shows the results of the linear regression model across several specifications. Panel B displays the results of the 2SLS regression where the budget error instruments cash reserves. All the dependent, independent, and instrumental variables are expressed as a percentage of each state's average discretionary revenues (DR) from 2009-2016. Standard errors clustered at the state level. A */**/*** indicates significance at the 10/5/1\% levels."

forvalues j=1(1)1{
/// Short Term Sample of State issued Bonds 
use "${ai}\loan_data_clean.dta", clear 

keep if `conditional`j'' 
/// Destring variables 
cap replace tasa_efectiva = "" if tasa_efectiva == "N/A"
destring tasa_efectiva, replace 
cap replace tasa_efectiva = spread if tasa_efectiva == . 


********************************************************************************

/// Estimate the Model 
forvalues i = 1/4 {	
qui tempfile m`i'
qui tempfile iv`i'
qui tempfile fs`i'
if `i' == 1 {
	local controls = "No"
	local statefe = "No"
	local timefe = "Yes"
}
else if `i' == 2 {
	local controls = "Yes"
	local statefe = "No"
	local timefe = "Yes"
}
else if `i' == 3 {
	local controls = "No"
	local statefe = "Yes"
	local timefe = "Yes"
}
else if `i' == 4 {
	local controls = "Yes"
	local statefe = "Yes"
	local timefe = "Yes"
}

// First Regression Model 
// OLS 
qui sum $outcome
/// OLS Regression Model
qui eststo m`i': reghdfe $outcome $independent ${model`i'} 
local pval = string(2 * ttail(e(df_r), abs(_b[$independent] / _se[$independent])), "%8.4f")
qui estadd local pval_str `pval'
qui estadd local `controls'
qui estadd local `statefe'
qui estadd local `timefe'
qui estadd ysumm, replace

quietly regsave using `m`i'',  $regsaveopts table(m`i', parentheses(stderr) brackets(pval) format(%8.4fc) asterisk(10 5 1)) addlabel(controls,`controls', statefe, `statefe', timefe, `timefe')

/// Auxiliary Estimate First Stage Regression 
qui eststo fs`i': reghdfe $independent $instrument ${model`i'}
quietly regsave using `fs`i'',  $regsaveopts table(fs`i', parentheses(stderr) brackets(pval) format(%8.4fc) asterisk(10 5 1))

/// Reduced Form Regression 
qui sum $outcome
qui eststo iv`i': ivreghdfe $outcome ($independent = $instrument) ${ivmodel`i'}
local pval = string(2 * ttail(e(Fdf2), abs(_b[$independent] / _se[$independent])), "%8.4f")
qui estadd local pval_str `pvals'
qui estadd local pval_fs `pval_fs'
qui estadd local `controls'
qui estadd local `statefe'
qui estadd local `timefe'
quietly estadd ysumm, replace
quietly regsave using `iv`i'' , $regsaveopts table(iv`i', parentheses(stderr) brackets(pval) format(%8.4fc) asterisk(10 5 1)) addlabel(controls,`controls', statefe, `statefe', timefe, `timefe')
}
cap label variable $independent " "
/// Coefficient Plot 
coefplot (m1, `coef1') (m2, `coef2') (m3, `coef3') (m4, `coef4') , keep($independent) labels $legendcoef title("OLS Results", pos(11)) name(ols_coef`j', replace) $coefopts
coefplot (iv1, `coef1') (iv2, `coef2') (iv3, `coef3') (iv4, `coef4') , keep($independent) labels $legendcoef title("IV Results", pos(11)) name(iv_coef`j', replace) $coefopts

*********************************************************************************


qui use `m1', clear
forvalues i=2/4 {
qui merge 1:1 var using `m`i'', keep(match master) nogen
}
qui keep if var == "cash_ild_coef" | var == "cash_ild_stderr" 
qui tempfile ols_results
qui save `ols_results', replace 

qui use `fs1', clear 
forvalues i=2/4 {
qui merge 1:1 var using `fs`i'', keep(match master) nogen
}
cap replace var = "budget_error_coef" if var ==  "budget_error_ild_coef" 
cap replace var = "budget_error_stderr" if var == "budget_error_ild_stderr" 
qui keep if var == "budget_error_coef" | var == "budget_error_stderr" 
qui rename (fs1 fs2 fs3 fs4) (m1 m2 m3 m4)
qui tempfile fs_results
qui save `fs_results', replace 


qui use `iv1', clear
forvalues i=2/4 {
qui merge 1:1 var using `iv`i'', keep(match master) nogen
}
qui keep if var == "cash_ild_coef" | var == "cash_ild_stderr" | ///
		var == "ymean" | var == "N" | var == "widstat" | /// 
		var == "betafs_coef" | var == "betafs_stderr" | ///
		var == "controls" | var == "statefe" | var == "timefe"
		
qui replace var = "iv_cash_ild_coef" if var == "cash_ild_coef"
qui replace var = "iv_cash_ild_stderr" if var == "cash_ild_stderr"
qui rename (iv1 iv2 iv3 iv4) (m1 m2 m3 m4)
qui tempfile iv_results
qui save `iv_results', replace 

qui clear
qui set obs 1 
qui gen var = "\textbf{Panel A: OLS Estimates}" 
qui gen m1 = ""
qui gen m2 = ""
qui gen m3 = ""
qui gen m4 = ""
qui append using  `ols_results'
qui tempfile ols_results
qui save `ols_results'

qui clear
qui set obs 1 
qui gen var = "\textbf{Panel B: 2SLS IV Estimates}"
qui gen m1 = ""
qui gen m2 = ""
qui gen m3 = ""
qui gen m4 = ""
qui append using  `iv_results'
qui append using `fs_results'
qui tempfile iv_results
qui save `iv_results'

qui use `ols_results'
qui append using `iv_results'

qui gen order = . 
qui replace order = 1 if var == "\textbf{Panel A: OLS Estimates}"
qui replace order = 2 if var == "cash_ild_coef"
qui replace order = 3 if var == "cash_ild_stderr"
qui replace order = 4 if var == "\textbf{Panel B: 2SLS IV Estimates}" 
qui replace order = 5 if var == "iv_cash_ild_coef"
qui replace order = 6 if var == "iv_cash_ild_stderr"
qui replace order = 7 if var == "budget_error_coef"
qui replace order = 8 if var == "budget_error_stderr"
qui replace order = 9 if var == "widstat"
qui replace order = 10 if var == "ymean"
qui replace order = 11 if var == "N"
qui replace order = 12 if var == "controls"
qui replace order = 13 if var == "statefe"
qui replace order = 14 if var == "timefe"
qui sort order

qui replace var = subinstr(var,"_coef","",1)
qui replace var = "" if strpos(var,"_stderr")
qui replace var = "Cash Reserves (\% DR)" if var == "cash_ild" | var == "iv_cash_ild"
qui replace var = "First Stage: Budget Error $\hat{\beta}$" if var == "budget_error"
qui replace var = "Cragg-Donald Wald F statistic" if var == "widstat"
qui replace var = "Mean of Dep Var" if var == "ymean"
qui replace var = "Observations" if var == "N"
qui replace var = "Controls" if var == "controls"
qui replace var = "Time FE" if var == "timefe"
qui replace var = "State FE" if var == "statefe"
qui drop order

/// Export Full Table 
dis "`title`j''"
list
texsave using "${ao}\`file`j''.tex", autonumber hlines(1 4 9) nofix replace marker(tab:`file`j'') title("`title`j''") footnote("`fn'") varlabels 

grc1leg ols_coef`j' iv_coef`j', legendfrom(ols_coef`j') rows(2) cols(1) ysize(16) xsize(8) name(coef_combined`j', replace) xcommon ycommon title("`title`j''", pos(11) size(medsmall))
graph export  "${ao}\`file`j''.pdf", replace 

}

exit 