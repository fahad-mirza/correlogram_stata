	* Correlogram
		* Correlogram let’s you examine the corellation of multiple continuous 
		* variables present in the data. 
		
		* One time installations:
		*ssc install schemepack, replace
		*ssc install colrspace, replace
		*ssc install palettes, replace
		*ssc install labutil, replace
		
	* Load Dataset
	sysuse auto, clear	
	
	* Only change names of variable in local var_corr. 
	* The code will hopefully do the rest of the work without any hitch
	local var_corr price mpg trunk weight length turn foreign
	local countn : word count `var_corr'
	
	* Use correlation command
	quietly correlate `var_corr'
	matrix C = r(C)
	local rnames : rownames C
	
	* Now to generate a dataset from the Correlation Matrix
	clear
		
		* For no diagonal and total count
		local tot_rows : display `countn' * `countn'
		set obs `tot_rows'
		
		generate corrname1 = ""
		generate corrname2 = ""
		generate y = .
		generate x = .
		generate corr = .
		generate abs_corr = .
		
		local row = 1
		local y = 1
		local rowname = 2
			
		foreach name of local var_corr {
			forvalues i = `rowname'/`countn' { 
				local a : word `i' of `var_corr'
				replace corrname1 = "`name'" in `row'
				replace corrname2 = "`a'" in `row'
				replace y = `y' in `row'
				replace x = `i' in `row'
				replace corr = round(C[`i',`y'], .01) in `row'
				replace abs_corr = abs(C[`i',`y']) in `row'
				
				local ++row
				
			}
			
			local rowname = `rowname' + 1
			local y = `y' + 1
		
		}
		
	drop if missing(corrname1)
	replace abs_corr = 0.1 if abs_corr < 0.1 & abs_corr > 0.04
	
	*colorpalette HCL pinkgreen, n(10) nograph intensity(0.65)
	colorpalette CET CBD1, n(10) nograph //Color Blind Friendly option
	generate colorname = ""
	local col = 1
	forvalues colrange = -1(0.2)0.8 {
		replace colorname = "`r(p`col')'" if corr >= `colrange' & corr < `=`colrange' + 0.2'
		replace colorname = "`r(p10)'" if corr == 1
		local ++col
	}	
	
	
	* Plotting
	* Saving the plotting code in a local 
	forvalues i = 1/`=_N' {
	
		local slist "`slist' (scatteri `=y[`i']' `=x[`i']' "`: display %3.2f corr[`i']'", mlabposition(0) msize(`=abs_corr[`i']*15') mcolor("`=colorname[`i']'"))"
	
	}
	
	
	* Gather Y axis labels
	labmask y, val(corrname1)
	labmask x, val(corrname2)
	
	levelsof y, local(yl)
	foreach l of local yl {
		local ylab "`ylab' `l'  `" "`:lab (y) `l''" "'"	
		
	}	

	* Gather X Axis labels
	levelsof x, local(xl)
	foreach l of local xl {
		local xlab "`xlab' `l'  `" "`:lab (x) `l''" "'"	
		
	}		
	
	* Plot all the above saved lolcas
	twoway `slist', title("Correlogram of Auto Dataset Cars", size(3) pos(11)) ///
			note("Dataset Used: Sysuse Auto", size(2) margin(t=5)) ///
			xlabel(`xlab', labsize(2.5)) ylabel(`ylab', labsize(2.5)) ///
			xscale(range(1.75 )) yscale(range(0.75 )) ///
			ytitle("") xtitle("") ///
			legend(off) ///
			aspect(1) ///
			scheme(white_tableau)

	* Export the visual as PNG		
	graph export "~/Desktop/correlogram_stata_cbf.png", as(png) width(1920) replace 
