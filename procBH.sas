
%macro procBH(data, by, pvalue, FDR=0.05);

* preliminary sorting by P values for each by variable and each contrast;
proc sql;
	create table cop as
	select *, count(*) as m label='Number of tests'
	from &data.
	group by %if &by.^=%str() %then %sysfunc(prxchange(s/%str( )/%str(, )/,-1,&by.)),; Effect
	order by %if &by.^=%str() %then %sysfunc(prxchange(s/%str( )/%str(, )/,-1,&by.)),; Effect, &pvalue.;
quit;

* rank sorted P values;
data cop2; set cop;
	by &by. Effect;
	if first.Effect then rank = 1;
	else rank + 1;
	label rank = "P Value Rank";
run;

data cop2; set cop2;
	Q = &FDR.;
	bh_cval = rank/m*Q;
	label Q = "False Discovery Rate" bh_cval = "Benjamini-Hochberg critical value";
run;

* determine largest P value below critical value;
proc sql;
	create table cop3 as
	select *
	from cop2 as a
	left join (
		select distinct max(rank) as R label='Maximum rank below critical value'
		from cop2 as b
		where &pvalue. <= bh_cval
		group by %if &by.^=%str() %then %sysfunc(prxchange(s/%str( )/%str(, )/,-1,&by.)),; Effect
	) on %if &by.^=%str() %then %sysfunc(prxchange(s/(\w+)/%str(a.)$1%str( = b.)$1%str( and)/,-1,&by.)); a.Effect = b.Effect;
quit;

data cop3; set cop3;
	if missing(R) then R = 1;
	alpha_hat = R * Q/m;
	label alpha_hat = "Adjusted Alpha";
run;

* calculate adjusted confidence intervals and P values;
data &data.; set cop3;
	t_critical_fdr = tinv(1 - (alpha_hat/2), DF);
	P_fdr = min(1, (1 - probt(abs(tValue), DF))*2 * (Alpha/alpha_hat));
	if ^missing(Lower) and ^missing(Upper) then do;
		Lower_fdr = Estimate - t_critical_fdr*StdErr;
		Upper_fdr = Estimate + t_critical_fdr*StdErr;
	end;
	label t_critical_fdr = "Quantile of t Distribution" P_fdr = "FDR adjusted P Value";
	label Lower_fdr = "FDR adjusted Lower Limit of Confidence Interval" Upper_fdr = "FDR adjusted Upper Limit of Confidence Interval";
	format Lower_fdr Upper_fdr d8.4 P_fdr pvalue6.4;
run;

%mend procBH;
