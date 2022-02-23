proc sort data=sashelp.heart out=heart; by Weight_Status; run;

data heart; set heart;
	where ^missing(Weight_Status);	
	* create artificially statistically significant comparisons;
	if Weight_Status = "Overweight" and Smoking_Status = "Very Heavy (> 25)" then Cholesterol = Cholesterol + 5.4;
run;

ods output Diffs=d;
proc mixed data=heart;
	by Weight_Status;
	class Sex Smoking_Status BP_Status;
	model Cholesterol = Sex Smoking_Status;
	lsmeans Smoking_Status / diff cl alpha = 0.05;
run;

%procBH(d, Weight_Status, Probt, FDR=0.05);
