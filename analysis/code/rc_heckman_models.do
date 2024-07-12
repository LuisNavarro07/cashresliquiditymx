************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu
** Script: Regression Analysis 
************************************************************************


global heckopts first twostep
/// Su and Hildreth: Heckman Selection Model 
/// No Controls, No Fixed Effects
local heckmod1 $outcome $independent i.date
local heckmod2 $outcome $independent $controls i.date
local heckmod3 $outcome $independent i.date i.id_entidad
local heckmod4 $outcome $independent $controls i.date i.id_entidad 
local heckmod5 $outcome $independent $controls i.date

*local select_mod1 delta_corto = $instrument i.quarter 
*local select_mod2 delta_corto = $instrument $controls i.quarter 
*local select_mod3 delta_corto = $instrument i.quarter i.id_entidad 
*local select_mod4 delta_corto = $instrument $controls i.quarter i.id_entidad
*local select_mod5 delta_corto = $instrument $controls 

// Su Hidlreth Selection Model Improved: Quarter and State Fixed Effects 
local select_mod1 delta_corto = $instrument $controls i.quarter i.id_entidad
local select_mod2 delta_corto = $instrument $controls i.quarter i.id_entidad
local select_mod3 delta_corto = $instrument $controls i.quarter i.id_entidad
local select_mod4 delta_corto = $instrument $controls i.quarter i.id_entidad
local select_mod5 delta_corto = $instrument $controls i.quarter i.id_entidad

//// Assumption: Exclude governments that did not issued debt 
local coef1 mcolor(black) msymbol(circle) msize(medium) ciopts(recast(rcap) fcolor(black) fintensity(inten10) lcolor(black))
local coef2 mcolor(cranberry) msymbol(square) msize(medium) ciopts(recast(rcap) fcolor(cranberry) fintensity(inten10) lcolor(cranberry))
local coef3 mcolor(navy) msymbol(triangle) msize(medium) ciopts(recast(rcap) fcolor(navy) fintensity(inten10) lcolor(navy))
local coef4 mcolor(dkgreen) msymbol(diamond) msize(medium) ciopts(recast(rcap) fcolor(dkgreen) fintensity(inten10) lcolor(dkgreen))
local coef5 mcolor(purple) msymbol(square) msize(medium) ciopts(recast(rcap) fcolor(purple) fintensity(inten10) lcolor(purple))
global coefopts ylabel(, labsize(medsmall) angle(0) nogrid) xlabel(,angle(0) labsize(medsmall)) xline(0,lcolor(black) lpattern(solid) lwidth(vthin))
label variable $independent " "


/// Estimate the Model 
forvalues i = 1/5 {	
qui tempfile h`i'
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
else if `i' == 5 {
	local controls = "Yes"
	local statefe = "No"
	local timefe = "Yes"
}

qui sum $outcome
/// Heckman Selection Model 
eststo h`i': heckman `heckmod`i'', select(`select_mod`i'') $heckopts
local pval = string(2 * ttail(e(df_r), abs(_b[$independent] / _se[$independent])), "%8.4f")
qui estadd local pval_str `pval'
qui estadd local `controls'
qui estadd local `statefe'
qui estadd local `timefe'
qui estadd ysumm, replace

quietly regsave using `h`i'',  $regsaveopts table(h`i', parentheses(stderr) brackets(pval) format(%8.4fc) asterisk(10 5 1)) addlabel(controls,`controls', statefe, `statefe', timefe, `timefe')

}

/// Coefficient Plot 
cap label variable $independent " "
coefplot (h1, `coef1') (h2, `coef2') (h3, `coef3') (h4, `coef4') (h5, `coef5'), keep($independent) labels $legendcoef title("Heckman Selection Model", pos(11)) name(heckman_coef, replace) $coefopts

esttab h1 h2 h3 h4 h5, keep($independent) p(%12.4fc) b(%12.4fc) label
 

*********************************************************************************

qui use `h1', clear
forvalues i=2/5 {
qui merge 1:1 var using `h`i'', keep(match master) nogen
 }
qui keep if var == "corto_plazo_ild:cash_ild_coef" | var == "corto_plazo_ild:cash_ild_stderr" | ///
			var == "delta_corto:budget_error_ild_coef" | var == "delta_corto:budget_error_ild_stderr" | ///
			var == "ymean" | var == "N" | var == "widstat" | /// 
			var == "controls" | var == "statefe" | var == "timefe"
qui rename (h1 h2 h3 h4 h5) (m1 m2 m3 m4 m5)
preserve 
keep if var == "corto_plazo_ild:cash_ild_coef" | var == "corto_plazo_ild:cash_ild_stderr"
qui tempfile heck_results1
qui save `heck_results1', replace 
restore 

preserve 
drop if var == "corto_plazo_ild:cash_ild_coef" | var == "corto_plazo_ild:cash_ild_stderr"
qui tempfile heck_results2
qui save `heck_results2', replace 
restore 

qui clear
qui set obs 1 
qui gen var = "\textbf{Panel A: Second Stage (Outcome Model)}" 
qui gen m1 = ""
qui gen m2 = ""
qui gen m3 = ""
qui gen m4 = ""
qui gen m5 = ""
qui append using  `heck_results1'
qui tempfile heck_results1
qui save `heck_results1'

qui clear
qui set obs 1 
qui gen var = "\textbf{Panel B: First Stage (Selection Model)}" 
qui gen m1 = ""
qui gen m2 = ""
qui gen m3 = ""
qui gen m4 = ""
qui gen m5 = ""
qui append using  `heck_results2'
qui tempfile heck_results2
qui save `heck_results2'

qui use `heck_results1'
qui append using `heck_results2'

qui gen order = . 
qui replace order = 1 if var == "\textbf{Panel A: Second Stage (Outcome Model)}" 
qui replace order = 2 if var == "corto_plazo_ild:cash_ild_coef"
qui replace order = 3 if var == "corto_plazo_ild:cash_ild_stderr"
qui replace order = 4 if var == "\textbf{Panel B: First Stage (Selection Model)}" 
qui replace order = 5 if var == "delta_corto:budget_error_ild_coef"
qui replace order = 6 if var == "delta_corto:budget_error_ild_stderr"
qui replace order = 7 if var == "ymean"
qui replace order = 8 if var == "N"
qui replace order = 9 if var == "controls"
qui replace order = 10 if var == "statefe"
qui replace order = 11 if var == "timefe"
qui sort order

qui replace var = subinstr(var,"_coef","",1)
qui replace var = "" if strpos(var,"_stderr")

qui replace var = "Cash Reserves (\% DR)" if var == "corto_plazo_ild:cash_ild" 
qui replace var = "Budget Error (\% DR)" if var == "delta_corto:budget_error_ild" 
qui replace var = "Mean of Dep Var" if var == "ymean"
qui replace var = "Observations" if var == "N"
qui replace var = "Controls" if var == "controls"
qui replace var = "Time FE" if var == "timefe"
qui replace var = "State FE" if var == "statefe"

qui drop order

local title "Heckman Selection Model: Short Term Borrowing and Cash Reserves"
local fn "Notes: Panel A shows the results from the second stage regression. Panel B shows displays the results of the instrument used for the selection model. Estimation is done using Heckman's (1979) two-step efficient estimates of parameters and standard errors. Results in Column (5) replicate the econometric specification at \citep{suDoesFinancialSlack2018}. All the dependent, independent, and instrumental variables are expressed as a percentage of each state's average discretionary revenues (DR) from 2009-2016. Standard errors clustered at the state level A */**/*** indicate significance at the 10/5/1\% levels."
list
/// Export Full Table 
texsave using "${ao}\RC_Heckman_$model.tex", autonumber hlines(1 3 7) nofix replace marker(tab:Regression_StDebt) title("`title'") footnote("`fn'") varlabels 

exit 
*grc1leg ols_coef iv_coef, legendfrom(ols_coef) rows(2) cols(1) ysize(16) xsize(8) name(coef_combined, replace) xcommon ycommon
*graph export "${ao}\Regression_StDebt_$model.pdf", replace 