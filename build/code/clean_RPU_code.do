*** Clean RPU - SHCP 
*** Luis Navarro 
clear all 
cd "C:\Users\luise\OneDrive - Indiana University\Research\Mexico_Debt\RPU_SHCP\"

forvalues i = 0(1)46 {
quietly import excel "registro_deuda (`i').xlsx", sheet("SHCP") case(lower) clear
quietly keep A B C D E F G H I J K L M N P Q R
quietly drop if _n <= 2
quietly drop if B == ""
quietly rename (A B C D E F G H I J K L M N P Q R) (state issuer bank type issue_date inscription_date amount outstanding_last mat_moths mat_days ref_rate spread mat_date tasa_efectiva payment_source payment_affected use_proceeds)
quietly tempfile rpu`i'
quietly save `rpu`i'', replace 
}

use `rpu0', clear 
forvalues i = 1(1)46 {
quietly append using `rpu`i'' 
}

destring issue_date inscription_date amount spread mat_date mat_days mat_moths tasa_efectiva, replace 
sort state issuer issue_date
save "rpu_raw_all.dta", replace 

*** Generate Unique Identifiers 
use "rpu_raw_all.dta", clear

**** 
replace type = strtrim(type)
replace type = upper(type)
replace type = "CREDITO SIMPLE" if type == "CRÉDITO SIMPLE"
replace type = "CREDITO SIMPLE" if type == "CRéDITO SIMPLE"
replace type = "EMISION BURSATIL" if type == "CRÉDITO SIMPLE/EMISIÓN BURSÁTIL"
replace type = "EMISION BURSATIL" if type == "EMISIÓN BURSÁTIL"
replace type = "EMISION BURSATIL" if type == "EMISIóN BURSáTIL"
replace type = "CREDITO EN CUENTA CORRIENTE" if type == "CRÉDITO EN CUENTA CORRIENTE"
replace type = "CREDITO EN CUENTA CORRIENTE" if type == "CRéDITO EN CUENTA CORRIENTE"
replace type = "CREDITO EN CUENTA CORRIENTE" if type == "CRéDITO EN CUENTA CORRIENTE IRREVOCABLE Y CONTINGENTE"
replace type = "ASOCIACION PUBLICO PRIVADA" if type == "ASOCIACIÓN PÚBLICO-PRIVADA"
replace type = "ASOCIACION PUBLICO PRIVADA" if type == "PROYECTO DE PRESTACIÓN DE SERVICIOS"
replace type = "ASOCIACION PUBLICO PRIVADA" if type == "OBLIGACIóN ASOCIACION PUBLICO PRIVADA"
replace type = "ASOCIACION PUBLICO PRIVADA" if type == "OBLIGACIóN RELACIONADA CON ASOCIACIONES PúBLICO - PRIVADAS"
replace type = "CREDITO CORTO PLAZO" if type == "OBLIGACIÓN A CORTO PLAZO"
replace type = "CREDITO CORTO PLAZO" if type == "OBLIGACIóN A CORTO PLAZO"
replace type = "FACTORAJE" if type == "FACTORAJE FINANCIERO"

****
replace type = "CREDITO CORTO PLAZO" if type == "CREDITO SIMPLE" & mat_days <= 365
tab type
egen credit_id = group(state issuer bank type issue_date amount mat_moths)
sort credit_id
duplicates drop credit_id, force 
mdesc
/// Only state
gen govt = 0 
replace govt = 1  if issuer == "GOBIERNO DEL ESTADO"
gen corto = 0 
replace corto = 1 if type == "CREDITO CORTO PLAZO"

save "C:\Users\luise\OneDrive - Indiana University\Research\Mexico_Debt\clean_data\rpu_clean.dta", replace 
