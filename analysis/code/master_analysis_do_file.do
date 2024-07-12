************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu
** Script: Master Analysis Do File
************************************************************************ 

/// Model Parameters 
/// Baseline: out corto_plazo_ild// independent cash_ild // instrument = budget_error_ild
/// Parameters of the Model
global regsaveopts  detail(all) replace pval
global controls ib3.rating_group part_aff_st share_current balance share_ild share_ltdebt
global outcome corto_plazo_ild
global independent cash_ild 
global instrument budget_error_ild

********************************************************************************
/// Model Estimation 
/// Model Definiton
// OLS - Time FE
global model1 ,cluster(id_entidad) absorb(date)
global model2 $controls, cluster(id_entidad) absorb(date)
global model3 ,cluster(id_entidad) absorb(date id_entidad)
global model4 $controls, cluster(id_entidad) absorb(date id_entidad)
// IV Model 
global ivmodel1 ,cluster(id_entidad) absorb(date)
global ivmodel2 $controls, cluster(id_entidad) absorb(date)
global ivmodel3 ,cluster(id_entidad) absorb(date id_entidad)
global ivmodel4 $controls, cluster(id_entidad) absorb(date id_entidad)

/// Coefficient Plot Options
global legendcoef legend(on order (2 "Time FE" 4 "Time FE + Controls" 6 "Time FE + State FE" 8 "Time FE + State FE + Controls") rows(2) size(medsmall) pos(6))

/// Baseline Model Decision to Issue Short Term Debt 
use "${ai}\panel_mexico_governments_clean.dta", clear 
global model baseline
do "${ac}\regression_analysis.do"


/// Robustness Check 1: Remove Governments that did not issued debt
use "${ai}\panel_mexico_governments_clean.dta", clear 
keep if active_short_term == 1
global model rc1
do "${ac}\regression_analysis.do"

/// Robustness Check 2: Su and Hildreth (2018) = Heckman Selection Models
/// To avoid problems of not concavity and convergence on the estimation, without losing generality a simplify the control variable for credit rating to be a big rating group.  
global legendcoef legend(on order (2 "Time FE" 4 "Time FE + Controls" 6 "Time FE + State FE" 8 "Time FE + State FE + Controls" 10 "Su & Hildreth (2018)") rows(2) size(medsmall) pos(6))
use "${ai}\panel_mexico_governments_clean.dta", clear 
global model rc2
do "${ac}\rc_heckman_models.do"

/// Robustness Check 3: Heterogeneity by Credit Rating 
/// Analysis by Credit Rating: AAA and AA 
global legendcoef legend(on order (2 "Time FE" 4 "Time FE + Controls" 6 "Time FE + State FE" 8 "Time FE + State FE + Controls") rows(2) size(medsmall) pos(6))
use "${ai}\panel_mexico_governments_clean.dta", clear 
tabstat $outcome $independent, by(rating_cont) stat(mean) format(%12.4fc)
global model rc3 
do "${ac}\rc_analysis_credit_rating.do"

/// Robustness Check 4: Binary Outcome Model 
global outcome delta_corto
use "${ai}\panel_mexico_governments_clean.dta", clear 
global model lpm
do "${ac}\regression_analysis.do"

/// Alternative Outcome: All Liabilities
use "${ai}\panel_mexico_governments_clean.dta", clear 
replace corto_plazo_ild = share_corto_pasivos
global model stliab
do "${ac}\regression_analysis.do"


********************************************************************************

/// Model Parameters 
global outcomes tasa_efectiva
global independent cash_ild 
global instrument budget_error


// OLS - Time FE
global model1 ,vce(robust) absorb(date)
global model2 $controls, vce(robust) absorb(date)
global model3 , vce(robust) absorb(date id_entidad)
global model4 $controls, vce(robust) absorb(date id_entidad)
// IV Model 
global ivmodel1 , robust absorb(date)
global ivmodel2 $controls, robust absorb(date)
global ivmodel3 , robust absorb(date id_entidad)
global ivmodel4 $controls, robust absorb(date id_entidad)


/// Analysis on Loan Level Data 
do "${ac}\rpu_analysis.do"
