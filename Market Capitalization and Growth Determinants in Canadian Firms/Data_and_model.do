capture log close
use "PANEL.dta", clear
log using "Final_sub", text replace


***Preliminary Analysis using 2023 data
**Transform Market Cap using ln
gen ln_mar_cap = ln(mar_cap)

**Duplicate check
egen comp_num = group(company)
duplicates tag comp_num year, gen(isdup)
drop if isdup
drop isdup comp_num
egen comp_num = group(company)

**Correlations and summary data
sum rv_gw ln_mar_cap roa cr dta rd_ns, detail
corr rv_gw ln_mar_cap roa cr dta rd_ns

hist mar_cap

**Simple Linear Regression
reg rv_gw ln_mar_cap, robust


***Panel data Analysis
**Define panel
xtset comp_num year

**Include company fixed effects
xtreg rv_gw ln_mar_cap, fe cluster(comp_num)

**Include time fixed effects
gen y18 = (year==2018)
gen y19 = (year==2019)
gen y20 = (year==2020)
gen y21 = (year==2021)
gen y22 = (year==2022)
gen y23 = (year==2023)
global yeardum "y18 y19 y20 y21 y22 y23"

xtreg rv_gw ln_mar_cap $yeardum, fe vce(cluster comp_num)
test $yeardum

*Graph year effects
xtreg rv_gw ln_mar_cap i.year, fe vce(cluster comp_num)
margins year, coeflegend post
local y17 = _b[2017bn.year]
marginsplot, ytitle(Revenue Growth) yline(`y17', lcolor(red)) xlabel(, labsize(vsmall)) xtitle(Years) title(Estimated effects of time on Revenue Growth (with 95% CIs) n=3143)

*Include Interaction variable
xtreg rv_gw ln_mar_cap $yeardum c.ln_mar_cap#i.year, fe vce(cluster comp_num)
test $yeardum

**Include control variables
xtreg rv_gw ln_mar_cap roa cr dta rd_ns $yeardum, vce(cluster comp_num)
test $yeardum

xtreg rv_gw ln_mar_cap roa cr dta rd_ns $yeardum, fe vce(cluster comp_num)
test $yeardum

**Analysis by sector
encode sector, gen(sect_num)
xtreg rv_gw ln_mar_cap roa cr dta rd_ns i.sect_num $yeardum, vce(cluster comp_num)
test $yeardum

*Graph Sector Effects
margins sect_num, coeflegend post
local s1 = _b[1bn.sect_num]
marginsplot, ytitle(Revenue Growth) yline(`s1', lcolor(red)) xlabel(, angle(45) labsize(vsmall)) xtitle(Sector) title(Estimated effects of sector on Revenue Growth (with 95% CIs) n=3143)
**(Less readable regression for testing purposes)
tab sector, gen(s)
global sectdum "s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12"
xtreg rv_gw ln_mar_cap roa cr dta rd_ns $sectdum $yeardum, vce(cluster comp_num)
test $sectdum


***Estimate Adjusted R2 for regressions
reg rv_gw ln_mar_cap
reg rv_gw ln_mar_cap i.comp_num
reg rv_gw ln_mar_cap i.comp_num i.year
reg rv_gw ln_mar_cap i.comp_num $yeardum c.ln_mar_cap#i.year
reg rv_gw ln_mar_cap roa cr dta rd_ns i.year
reg rv_gw ln_mar_cap roa cr dta rd_ns i.comp_num i.year
reg rv_gw ln_mar_cap roa cr dta rd_ns i.sect_num $yeardum

log close
