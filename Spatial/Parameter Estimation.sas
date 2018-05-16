ods graphics on;
libname STAT647 "C:\Users\reese-a\Google Drive\MS Analytics\Spring 2018\STAT 647";

%let method=ML;
%let training=stat647.training_data;
%let form=sph;

%macro parameter_estimation;

	%if &method=REML or &method=ML %then %do;
		title 'Parameter Estimation';
		proc mixed covtest data=&training method=&method scoring=5;
			model log_median_house_value=longitude latitude median_income near_ocean near_bay one_hour/solution outp=outp;
			repeated / subject=intercept  local type=sp(&form)(longitude latitude);
		run;
		%end;
	%else %do;
		proc reg data=&training;
			model log_median_house_value=longitude latitude median_income near_ocean near_bay one_hour;
			output out=regouttest residual=resid predicted=pred;
			run;

			title 'Variogram for OLS with Nuggget';
			proc variogram data= regouttest;
				store out=reg_store;
				compute lagd=0.02 maxlag=15;
				coordinates xc=longitude yc=latitude;
				model form=&form method=&method;
				var resid;
			run;	
		%end;
%mend parameter_estimation;

%parameter_estimation;