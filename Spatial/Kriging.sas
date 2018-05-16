ods graphics on;
options nomprint mlogic symbolgen;
libname STAT647 "C:\Users\reese-a\Google Drive\MS Analytics\Spring 2018\STAT 647";

data _null_;
	set stat647.scratchpad;
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_intercept'), intercept);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_long'), longitude);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_lat'), latitude);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_median_income'), median_income);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_near_ocean'), near_ocean);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_near_bay'), near_bay);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_one_hour'), one_hour);

	call symput(cats(est_method,'_',cov_model,'_',cluster,'_variance'), variance);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_spatial_range'), spatial_range);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_smoothness'), smoothness);
	call symput(cats(est_method,'_',cov_model,'_',cluster,'_nugget'), nugget);
run;

%let training=stat647.training_data;
%let validation=stat647.validation_data;
%let method=reml;
%let form=sph;
%let cluster=ALL;
%let suffix= &method._&form._&cluster;


%let intercept= &&&suffix._INTERCEPT;
%let long= &&&suffix._LONG;
%let lat= &&&suffix._LAT;
%let median_income= &&&suffix._MEDIAN_INCOME;
%let near_ocean= &&&suffix._NEAR_OCEAN;
%let near_bay= &&&suffix._NEAR_BAY;
%let one_hour= &&&suffix._ONE_HOUR;

%let variance= &&&suffix._VARIANCE;
%let spat_range= &&&suffix._SPATIAL_RANGE;
%let smoothness= &&&suffix._SMOOTHNESS;
%let nugget= &&&suffix._NUGGET;

%macro has_smoothness;
	%if &form =mat %then smooth=&smoothness;
%mend has_smoothness;

%macro filter_cluster;
	%if &cluster ne ALL %then where cluster = &cluster;
%mend filter_cluster;

data training_data_predictions;
	set &training;
	%filter_cluster;
	pred = &intercept + &long*longitude + &lat*latitude + &median_income*median_income + &near_ocean*near_ocean + &near_bay*near_bay + &one_hour*one_hour;
	Resid = log_median_house_value - pred;
run;

data validation_data_predictions;
	set &validation;
	%filter_cluster;
	pred = &intercept + &long*longitude + &lat*latitude + &median_income*median_income + &near_ocean*near_ocean + &near_bay*near_bay + &one_hour*one_hour;
run;

title 'Kriging';
proc krige2d data=training_data_predictions outest=krig_resid plots=all;
	coord xc=longitude yc=latitude;
	grid gdata=validation_data_predictions xc=longitude yc=latitude;
	pred var=Resid;
	model scale=&variance range=&spat_range nugget=&nugget %has_smoothness form=&form;
run;

proc sql;
	create table stat647.results_&suffix as
	select * 
	from validation_data_predictions as vp
	left join krig_resid as kr
	on (vp.longitude = kr.gxc AND vp.latitude = kr.gyc);
run;

title 'Matern (REML) - Results';
data stat647.results_&suffix;
	set stat647.results_&suffix;
	final = pred + estimate;
	resid = log_median_house_value - final;
	resid_trans = exp(log_median_house_value) - exp(final);
	abs = abs(resid);
	abs_trans = abs(resid_trans);
	sq_err = resid**2;
	abs_pct_err = abs / log_median_house_value;
	abs_pct_err_trans = abs_trans / exp(log_median_house_value);
run;

proc means data=stat647.results_&suffix noprint;
	output out=means;
run;

data stat647.means_&suffix;
	set means(where=(_STAT_='MEAN'));
	keep _STAT_ rmse abs abs_pct_err abs_trans abs_pct_err_trans;
	rmse = sqrt(sq_err);
run;

data stat647.means_&suffix;
	retain _STAT_ rmse abs abs_pct_err abs_trans abs_pct_err_trans;
	set stat647.means_&suffix;
run;