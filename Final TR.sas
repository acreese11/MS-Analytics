ods graphics on;
ods pdf file="C:\Users\reese-a\Google Drive\MS Analytics\Spring 2018\STAT 647\TR3.pdf";
libname STAT647 "C:\Users\reese-a\Google Drive\MS Analytics\Spring 2018\STAT 647";
title 'Random Sampling of Training Data';

proc surveyselect data=stat647.training_data method=srs n=500 out=training_data_sampled seed=642821001;
run;

title 'Exponential (REML) - Parameter Estimation';

proc mixed covtest data=training_data_sampled method=REML scoring=5;
	model log_median_house_value=longitude latitude median_income near_ocean near_bay one_hour /solution outp=outp;
	parms (0.04568) (0.05239) (0.02729);
	repeated / subject=intercept  local type=sp(exp)(longitude latitude);
run;

quit;

data training_data_predictions;
	set stat647.training_data;
	pred = 2.41130 + -0.10590*longitude + -0.09860*latitude + 0.13660*median_income + 0.14550*near_ocean + 0.04345*near_bay + 0.03644*one_hour;
	Resid = pred - log_median_house_value;
run;

data validation_data_predictions;
	set stat647.training_data;
	pred = 2.41130 + -0.10590*longitude + -0.09860*latitude + 0.13660*median_income + 0.14550*near_ocean + 0.04345*near_bay + 0.03644*one_hour;
run;

title 'Exponential (REML) - Kriging';

proc krige2d data=training_data_predictions outest=krig_resid;
	coord xc=longitude yc=latitude;
	grid gdata=stat647.validation_data xc=longitude yc=latitude;
	pred var=Resid;
	model scale=0.06228 range=0.11260 nugget=0.02224 form=exp;
run;

title 'Exponential (REML) - Results';

data results;
	set validation_data_predictions;
	set krig_resid;
	final = pred + estimate;
	resid = final - log_median_house_value;
	abs = abs(resid);
	sq_err = resid**2;
	abs_pct_err = abs / final;
run;

proc means data=results noprint;
	output out=means;
run;

data means;
	set means(where=(_STAT_='MEAN'));
	keep _STAT_ abs rmse abs_pct_err;
	rmse = sqrt(sq_err);
run;

/*title 'Exponential (REML) - Variogram';
proc variogram data=training_data_predictions plots=semivariogram;
coordinates xc=longitude yc=latitude;
compute lagd=0.03 maxlag=30;
var resid;
model scale=0.06228 range=0.11260 nugget=0.02224 form=exp;
run;*/
ods pdf close;