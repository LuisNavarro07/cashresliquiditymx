************************************************************************ 
** Title: Liquidity Management and Budgetary Shocks: Uncovering the Role of Cash Reserves in Short-Term Borrowing.
** Author: Luis Navarro (Indiana University, Bloomington)
** Contact: lunavarr@iu.edu

** Script: Clean Public Finance Mexico 
************************************************************************
clear all
// Set Work Environment 
global finpub "\efipem_estatal_csv\conjunto_de_datos"

/// Nombres Estados 
import delimited "${bi}\efipem_estatal_csv\catalogos\tc_entidad.csv", clear varnames(1) 
rename (ïid_entidad nom_ent) (id_entidad estado)
replace estado = "Ciudad de México" if id_entidad == 9 
replace estado = "México" if id_entidad == 15
replace estado = "Michoacán" if id_entidad == 16
replace estado = "Nuevo León" if id_entidad == 19 
replace estado = "Querétaro" if id_entidad == 22
replace estado = "San Luis Potosí" if id_entidad == 24
replace estado = "Yucatán" if id_entidad == 31  
replace estado = "Veracruz" if id_entidad == 30 
replace estado = "Coahuila" if id_entidad == 5 
gen state = lower(estado)

replace state = "ciudad de mexico" if state == "ciudad de méxico"
replace state = "michoacan" if state == "michoacán"
replace state = "mexico" if state == "méxico"
replace state = "nuevo leon" if state == "nuevo león"
replace state = "queretaro" if state == "querétaro"
replace state = "san luis potosi" if state == "san luis potosí"
replace state = "yucatan" if state == "yucatán"

save "${bt}\NombresEstados.dta", replace 


/// Import Public Finance Data 
forvalues i=2008(1)2021{
    quietly import delimited "${bi}\${finpub}\efipem_estatal_anual_tr_cifra_`i'.csv", clear varnames(1) 
	tempfile finpub`i'
	qui save `finpub`i'', replace 
}

use `finpub2008', clear 
/// Append the Data 
forvalues i=2009(1)2021{
	quietly append using `finpub`i''
}

qui drop ïprod_est estatus cobertura 

//Rename Variables 
rename anio year 
replace categoria = "Capitulo" if categoria == "CapÃ­tulo"
replace categoria = "Partida Generica" if categoria == "Partida GenÃ©rica"
replace categoria = "Subpartida Generica" if categoria == "Subpartida GenÃ©rica"
replace descripcion_categoria = "Deuda Publica" if descripcion_categoria == "Deuda pÃºblica"
replace descripcion_categoria = "Inversion Publica" if descripcion_categoria == "InversiÃ³n pÃºblica"

// Subset Capitulos 
keep if categoria == "Capitulo"

keep id_entidad year descripcion_categoria valor 
sort id_entidad year descripcion_categoria 

encode descripcion_categoria, gen(cat)
drop descripcion_categoria
reshape wide valor, i(id_entidad year) j(cat) 
forvalues i=1(1)22{
    qui replace valor`i' = 0 if valor`i' == . 
}

qui rename valor1 ing_aportaciones
qui rename valor2 ing_aprovechamientos
qui rename valor3 gas_bienes_inmuebles
qui rename valor4 ing_contribuciones
qui rename valor5 ing_cuotas
qui rename valor6 ing_derechos
qui rename valor7 gas_deuda
qui rename valor8 disp_ini
qui rename valor9 disp_fin
qui rename valor10 ing_financiamiento
qui rename valor11 ing_impuestos
qui rename valor12 gas_inversion
qui rename valor13 ing_invsersionesfin
qui rename valor14 gas_materiales_sumi
qui rename valor15 gas_otros
qui rename valor16 ing_otros
qui rename valor17 ing_participaciones
qui rename valor18 ing_productos
qui rename valor19 gas_participaciones_munis
qui rename valor20 gas_servicios_generales
qui rename valor21 gas_servicios_personales
qui rename valor22 gas_transferencias

/// Expressed in Millions of Pesos for Consistency with the other data 
foreach var of varlist ing_aportaciones ing_aprovechamientos gas_bienes_inmuebles ing_contribuciones ing_cuotas ing_derechos gas_deuda disp_ini disp_fin ing_financiamiento ing_impuestos gas_inversion ing_invsersionesfin gas_materiales_sumi gas_otros ing_otros ing_participaciones ing_productos gas_participaciones_munis gas_servicios_generales gas_servicios_personales gas_transferencias {
    qui replace `var' = `var'/1000000
	qui label variable `var' "`var' (mdp)"
	format `var' %12.2fc
}


/// Variables de Ingresos 
qui gen ing_locales = ing_impuestos + ing_derechos + ing_aprovechamientos + ing_contribuciones + ing_cuotas + ing_productos 
qui gen ilds = ing_locales + ing_participaciones
qui gen ing_tot = ing_locales + ing_participaciones + ing_aportaciones  
/// Variables de Gasto 
qui gen current_exp = gas_servicios_personales + gas_servicios_generales + gas_materiales_sumi + gas_transferencias 
qui gen current_exp_no_transf = current_exp - gas_transferencias
qui gen cap_outlays = gas_bienes_inmuebles + gas_inversion 
qui gen exp_tot = current_exp + gas_participaciones_munis + cap_outlays + gas_deuda 
qui gen generales_suministros = gas_servicios_generales + gas_materiales_sumi
qui gen exp_all_transfers = gas_participaciones_munis + gas_transferencias
/// Variable de Balance 
qui gen balance = (ing_tot - exp_tot)/ing_tot

/// Shares
qui gen share_local = ing_locales/ing_tot 
qui gen share_r28 = ing_participaciones/ing_tot
qui gen share_r33 = ing_aportaciones/ing_tot 

qui gen share_current = current_exp/exp_tot 
qui gen share_ig = gas_participaciones_munis/exp_tot 
qui gen share_interest = gas_deuda/exp_tot
qui gen share_cap = cap_outlays/exp_tot
qui gen share_ild = (ing_locales + ing_participaciones)/ing_tot

/// Shares 


/// Mean of Total Revenues Historic (2009 2016)
bysort id_entidad: egen mean_ild = mean(ilds) if year < 2017
bysort id_entidad: carryforward mean_ild, replace 
bysort id_entidad: egen mean_current = mean(current_exp) if year < 2017 
bysort id_entidad: carryforward mean_current, replace 

/// Restrict Sample 
drop if year < 2016

global variables ing_aportaciones ing_participaciones ing_locales ing_tot share_local share_r28 share_r33 current_exp cap_outlays exp_tot share_current share_interest share_ig share_cap balance share_ild gas_participaciones_munis gas_deuda gas_servicios_personales gas_servicios_generales gas_materiales_sumi gas_transferencias generales_suministros exp_all_transfers current_exp_no_transf mean_ild mean_current 
keep id_entidad year $variables 

global nominal ing_aportaciones ing_participaciones ing_locales ing_tot current_exp cap_outlays exp_tot balance gas_participaciones_munis gas_deuda gas_servicios_personales gas_servicios_generales gas_materiales_sumi gas_transferencias generales_suministros exp_all_transfers current_exp_no_transf mean_ild



merge m:1 id_entidad using "${bt}\NombresEstados.dta", keep(match master) nogen 

xtset id year
sort id_entidad year 


// ASSUMPTION: 1 YEAR LAG. 
// The year in this data set will be one year forward so when I match it with contemporaneous data it will be already lagged  
replace year = year + 1 

foreach var of varlist $variables {
    label variable `var' "`var' (1 year lag, millions of pesos)"
}

sum $variables 

save "${bt}\clean_fin_pub.dta", replace  

