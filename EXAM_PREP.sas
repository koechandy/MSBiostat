DM "output ’clear’"; *** clear output;
DM "clear log"; *** clear log;
DM "odsresults; clear"; *** clear results;



LIBNAME SP "A:\MSBiostat\SAS\00_Data\01_RawData_SAS";

PROC FORMAT;
	VALUE $trt	"P" = "Placebo"
		"T" = "Verum"
	;
RUN;

/* ---------------------------------------------------------------------- */
/*  Begin of Analysis                                                     */
/* ---------------------------------------------------------------------- */
PROC IMPORT OUT=SP.FEV_OBS
	DATAFILE="A:\MSBiostat\SAS\00_Data\00_RawData\fev_obs.csv"
	DBMS=CSV REPLACE;
	GETNAMES=YES;
	DATAROW=2;
	DELIMITER=";";
RUN;

DATA FEV1;
	SET SP.FEV_OBS;
	FORMAT Treatment $trt.;
RUN;

PROC CONTENTS DATA=FEV1;
	TITLE "Variables in FEV1";
RUN;

/*Present the FEV1 data in suitable tables (by treatment and visit)*/
PROC TABULATE DATA=FEV1;
	CLASS TREATMENT time;
	VAR FEV;

	TABLE TREATMENT*time,	
		FEV*(N*F=4.NMISS*F=4.(MIN MEAN MEDIAN MAX)*F=6.2);
		TITLE "OVERVIEW OF FEV1";
RUN;

/*Present the FEV1 data in a scatter plot (over visits, by treatment)*/
ODS LISTING GPATH="A:\MSBiostat\SAS\02_Output";
ODS LISTING  style=HTMLBlue;
ODS GRAPHICS ON / RESET=ALL 
	WIDTH =12.0 IN
	HEIGHT=8.4 IN
	OUTPUTFMT=PNG
	IMAGEMAP=on
	IMAGENAME="FEV_obs"
	RESET=INDEX
	BORDER=off;

PROC SGPLOT DATA=FEV1;
	SCATTER	X=TIME Y=FEV;
	BY Treatment;
	LABEL time="Time (months)" FEV="Forced Expiratory Vol. in 1 sec.";
	TITLE "FEV1 vs TIME";
RUN;

/*Both Treatments in a single plot*/
PROC SGPLOT DATA=FEV1;
	SCATTER  x=time y=FEV / GROUP=Treatment;
	LABEL time="Time (months)" FEV="Forced Expiratory Vol. in 1 sec.";
	TITLE "FEV1 vs TIME";
RUN;

QUIT;

ODS GRAPHICS OFF;

/*Plot the temporal course of the FEV1 measurements by patient*/
PROC SORT DATA=FEV1;
	BY Treatment PatId time;
RUN;

DATA FEV1;
	SET FEV1;

	IF Treatment="P" THEN
		FEV_P=FEV;
	ELSE FEV_T=FEV;
RUN;

ODS LISTING GPATH="A:\MSBiostat\SAS\02_Output";
ODS LISTING  style=HTMLBlue;
ODS GRAPHICS ON / RESET=ALL 
	WIDTH =10.0 IN
	HEIGHT=7 IN
	OUTPUTFMT=PNG
	IMAGEMAP=on
	IMAGENAME="FEV_obs_course"
	RESET=INDEX
	BORDER=off;

PROC SGPLOT DATA=FEV1;
	SERIES X=time Y=FEV_P/ GROUP=PatId LINEATTRS=(COLOR=BLUE PATTERN=SOLID)
		NAME="1" LEGENDLABEL="Placebo";
	SERIES X=time Y=FEV_T/GROUP=PatId LINEATTRS=(COLOR=RED PATTERN=DASH)
		NAME="2" LEGENDLABEL="Verum";
	KEYLEGEND "1" "2"
		/TITLE="Legend" NOBORDER;
	TITLE "Individual Courses";
RUN;

QUIT;

ODS GRAPHICS OFF;

/*Dirty solution*/
DATA selection;
	SET FEV1;
	BY Treatment PatId;
	selection = FIRST.Treatment & FIRST.PatId;
	KEEP PatId selection;

	IF selection;
RUN;

DATA PatforLegend;
	MERGE FEV1
		selection;
	BY PatId;

	IF FEV_P > . THEN
		FEV_legendP = FEV_P;

	IF FEV_T > . THEN
		FEV_legendT = FEV_T;
	KEEP PatId Treatment FEV_legendP FEV_legendT;

	IF selection;
RUN;

DATA FEV1;
	SET FEV1 PatforLegend;
RUN;

ODS LISTING GPATH="A:\MSBiostat\SAS\02_Output";
ODS LISTING  style=HTMLBlue;
ODS GRAPHICS ON / RESET=ALL 
	WIDTH =12.0 IN
	HEIGHT=8.4 IN
	OUTPUTFMT=PNG
	IMAGEMAP=on
	IMAGENAME="FEV_obs_course2"
	RESET=INDEX
	BORDER=off;

PROC SGPLOT DATA=FEV1;
	SERIES  x=time y=FEV_P / GROUP=PatId LINEATTRS=(COLOR=BLUE PATTERN=SOLID)
		NAME="1" LEGENDLABEL="Placebo";
	SERIES  x=time y=FEV_T / GROUP=PatId LINEATTRS=(COLOR=RED PATTERN=DASH)
		NAME="2" LEGENDLABEL="Verum";
	SERIES  x=time y=FEV_LegendP / LINEATTRS=(COLOR=BLUE PATTERN=SOLID)
		NAME="3" LEGENDLABEL="Placebo";
	SERIES  x=time y=FEV_legendT / LINEATTRS=(COLOR=RED PATTERN=DASH)
		NAME="4" LEGENDLABEL="Verum";
	KEYLEGEND  "3" "4"
		/ TITLE="Treatment" NOBORDER;
	TITLE "Individual courses, 2nd try";
RUN;

QUIT;

ODS GRAPHICS OFF;

/*Add to this plot the mean FEV1 values for each visit and each treatment group*/
PROC SORT DATA=FEV1;
	BY Treatment time;
RUN;

PROC MEANS DATA=FEV1 NOPRINT;
	VAR FEV;
	BY Treatment time;
	OUTPUT OUT=FEV1_M MEAN=FEV_mean STDERR=FEV_se;
RUN;

DATA FEV1;
	SET FEV1 FEV1_M(DROP=_TYPE_ _FREQ_);

	IF  Treatment="P" THEN
		DO;
			FEV_mean_P=FEV_mean;
			FEV_cil_P=FEV_mean-FEV_se;
			FEV_ciu_P=FEV_mean+FEV_se;
		END;

	IF  Treatment="T" THEN
		DO;
			FEV_mean_T=FEV_mean;
			FEV_cil_T=FEV_mean-FEV_se;
			FEV_ciu_T=FEV_mean+FEV_se;
		END;
RUN;

ODS GRAPHICS ON / RESET=ALL 
	WIDTH =12.0 IN
	HEIGHT=8.4 IN
	OUTPUTFMT=PNG
	IMAGEMAP=on
	IMAGENAME="FEV_obs_course3"
	RESET=INDEX
	BORDER=off;

PROC SGPLOT DATA=FEV1;
	LABEL FEV_mean_P="Forced expiratory volume";
	SERIES  x=time y=FEV_P / GROUP=PatId LINEATTRS=(COLOR=BLUE PATTERN=SOLID)
		NAME="1" LEGENDLABEL="Placebo";
	SERIES  x=time y=FEV_T / GROUP=PatId LINEATTRS=(COLOR=RED PATTERN=DASH)
		NAME="2" LEGENDLABEL="Verum";
	SERIES  x=time y=FEV_LegendP / LINEATTRS=(COLOR=BLUE PATTERN=SOLID)
		NAME="3" LEGENDLABEL="Placebo";
	SERIES  x=time y=FEV_legendT / LINEATTRS=(COLOR=RED PATTERN=DASH)
		NAME="4" LEGENDLABEL="Verum";
	SCATTER x=time y=FEV_mean_P / MARKERATTRS=(COLOR=BLUE SYMBOL=CIRCLEFILLED SIZE=10)
		NAME="5" LEGENDLABEL="Mean, Placebo";
	SCATTER x=time y=FEV_mean_T / MARKERATTRS=(COLOR=RED SYMBOL=STARFILLED SIZE=10)
		NAME="6" LEGENDLABEL="Mean, Verum";
	SERIES x=time y=FEV_mean_P / LINEATTRS=(COLOR=BLUE PATTERN=SOLID THICKNESS=3);
	SERIES x=time y=FEV_mean_T / LINEATTRS=(COLOR=RED PATTERN=SOLID THICKNESS=3);
	KEYLEGEND  "3" "4" "5" "6"
		/ TITLE="Treatment" NOBORDER;
	TITLE "Individual courses with mean per treatment";
RUN;

QUIT;

ODS GRAPHICS OFF;
ODS GRAPHICS ON / RESET=ALL 
	WIDTH =12.0 IN
	HEIGHT=8.4 IN
	OUTPUTFMT=PNG
	IMAGEMAP=on
	IMAGENAME="FEV_obs_course4"
	RESET=INDEX
	BORDER=off;

PROC SGPLOT DATA=FEV1;
	LABEL FEV_mean_P="Forced expiratory volume";
	SCATTER x=time y=FEV_mean_P / MARKERATTRS=(COLOR=BLUE SYMBOL=CIRCLEFILLED SIZE=10)
		NAME="5" LEGENDLABEL="Mean, Placebo"
		YERRORLOWER=FEV_cil_P YERRORUPPER=FEV_ciu_P 
		ERRORBARATTRS=(COLOR=BLUE PATTERN=SOLID THICKNESS=1);
	SCATTER x=time y=FEV_mean_T / MARKERATTRS=(COLOR=RED SYMBOL=STARFILLED SIZE=10)
		NAME="6" LEGENDLABEL="Mean, Verum"
		YERRORLOWER=FEV_cil_T YERRORUPPER=FEV_ciu_T
		ERRORBARATTRS=(COLOR=RED PATTERN=DASH THICKNESS=1);
	SERIES x=time y=FEV_mean_P / LINEATTRS=(COLOR=BLUE PATTERN=SOLID THICKNESS=2)  NAME="7" LEGENDLABEL="Placebo";
	SERIES x=time y=FEV_mean_T / LINEATTRS=(COLOR=RED PATTERN=SOLID THICKNESS=2)  NAME="8" LEGENDLABEL="Verum";
	KEYLEGEND  "5" "6" "7" "8" 
		/ TITLE="Treatment" NOBORDER;
	TITLE "Mean FEV_1 over time +/- 1s.e. per Treatment";
RUN;

QUIT;

ODS GRAPHICS OFF;

/* Different approach. Note: X-axis scale!*/
PROC SGPLOT data=FEV1;
	VLINE time/response=FEV group=treatment stat=mean limitstat=stderr;
RUN;

PROC SORT DATA=FEV1;
	BY TIME;
RUN;

ODS GRAPHICS;

PROC TTEST DATA=FEV1 plots(shownull)=interval;
	BY TIME;
	CLASS TREATMENT;
	VAR FEV;
	TITLE "Testing the difference between treatments";
RUN;

/******************************************************************
 *******************************************************************
 *******************************************************************
 ********************MEAN IMPUTATION********************************
 *******************************************************************
 *******************************************************************
 *******************************************************************/

/*Generating means for each treatment group based on visit*/
PROC MEANS DATA=SP.FEV_OBS noprint;
	VAR FEV;
	CLASS Treatment time;
	OUTPUT OUT=FEVMEANS MEAN=fevmean;
RUN;

/*Combine observed+means data using sql*/
PROC SQL NOPRINT;
	CREATE TABLE FEV_imputation AS
		SELECT a.*, b.FEVMEAN
			FROM SP.FEV_OBS AS a
				LEFT JOIN FEVMEANS AS b
					ON a.treatment=b.treatment AND a.time=b.time
				WHERE b._TYPE_=3;
QUIT;

/*Defining the imputed values*/
DATA FEV_Imputation;
	SET FEV_Imputation;
	FEV_Meanimp=FEV;

	IF FEV_Meanimp=. THEN
		FEV_Meanimp=fevmean;
	DROP fevmean;
	LABEL FEV_Meanimp="Forced expiratory volume 1 sec - mean imputed";
RUN;

/*Save Dataset*/
DATA SP.FEV_meanimputed;
	SET FEV_Imputation;
RUN;

/*Alternative (calculating mean in Proc sql)*/
PROC SQL NOPRINT;
	CREATE TABLE FEV_imputation2 AS
		SELECT *, mean(FEV) AS fevmean
			FROM SP.FEV_OBS 
				GROUP BY treatment, time;
QUIT;

/*Define imputed variable and drop means*/
DATA FEV_Imputation2;
	SET FEV_Imputation2;
	FEV_Meanimp=FEV;

	IF FEV_Meanimp=. THEN
		FEV_Meanimp=fevmean;
	DROP fevmean;
	LABEL FEV_Meanimp="Forced expiratory volume 1 sec - mean imputed";
RUN;

/*Compare both data sets*/
PROC SORT DATA=FEV_imputation;
	BY Patid time;
RUN;

PROC SORT DATA=FEV_imputation2;
	BY Patid time;
RUN;

PROC COMPARE BASE=FEV_imputation COMPARE=FEV_imputation2;
RUN;

/******************************************************************
 *******************************************************************
 *******************************************************************
 ********************MEAN IMPUTATION********************************
 *******************WITH RANDOM TERM********************************
 *******************************************************************
 *******************************************************************/
DATA FEV_imputed;
	SET SP.FEV_meanimputed;
	FORMAT Treatment $trt.;
RUN;

/*Calculate mean FEV by treatment and time*/
PROC MEANS DATA=FEV_imputed noprint;
	VAR FEV;
	CLASS Treatment time;
	OUTPUT OUT=FEVMEANS MEAN=fevmean std=fevstd;
RUN;

/*Combine observed+means data using sql*/
PROC SQL NOPRINT;
	CREATE TABLE FEV_imputation AS
		SELECT a.*, b.FEVMEAN,b.FEVSTD
			FROM FEV_imputed AS a
				LEFT JOIN FEVMEANS AS b
					ON a.treatment=b.treatment AND a.time=b.time
				WHERE b._TYPE_=3;
QUIT;

/*Defining the imputed values*/
DATA FEV_Imputation;
	SET FEV_Imputation;
	CALL streaminit(1234);
	FEV_Meanimprand=FEV;

	IF FEV_Meanimprand=. THEN
		FEV_Meanimprand=RAND('NORMAL',fevmean,fevstd);
	DROP FEVMEAN FEVSTD;
	LABEL FEV_Meanimprand="Forced expiratory volume 1 sec - mean imputed with random element";
RUN;

/*Saving the Dataset with Randomly Imputed missing values*/
DATA SP.FEV_meanimputed_rand;
	SET FEV_Imputation;
RUN;

/*************************************************************/
/*Alternative approach: Calculating mean and std in Proc SQL;*/
/*************************************************************/
/*Calculate mean and std of FEV by treatment and time and store it in data set*/
PROC SQL NOPRINT;
	CREATE TABLE FEV_imputation2 AS
		SELECT *, mean(FEV) AS fevmean, std(FEV) AS fevstd
			FROM FEV_imputed GROUP BY treatment, time;
QUIT;

/*Defining imputed variable and drop means*/
DATA FEV_Imputation2;
	SET FEV_Imputation2;
	CALL streaminit(1234);
	FEV_Meanimprand=FEV;

	IF FEV_Meanimprand=. THEN
		FEV_Meanimprand=RAND('NORMAL',fevmean,fevstd);
	DROP FEVMEAN FEVSTD;
	LABEL FEV_Meanimprand="Forced expiratory volume 1 sec - mean imputed with random element";
RUN;

/*Comparing both imputed data sets*/
PROC SORT DATA=FEV_imputation;
	BY Patid time;
RUN;

PROC SORT DATA=FEV_imputation2;
	BY Patid time;
RUN;

PROC COMPARE BASE=FEV_imputation COMPARE=FEV_imputation2;
RUN;

/*An alternative imputation technique for subsequent missing data is the*/
/*"last observation carried forward" (LOCF) method.*/
/*The last observation per subject is used for all subsequent missing values*/
DATA FEV_Imputation;
	SET SP.FEV_meanimputed_rand;
	FORMAT Treatment $trt.;
RUN;

/*Sorting the data*/
PROC SORT DATA=FEV_imputation;
	BY Patid time;
RUN;

/*Implementing the LOCF*/
DATA FEV_imputation2;
	SET FEV_imputation;
	RETAIN FEV_LOCF;
	BY PatId;
	FEV_imputed=FEV;

	IF FIRST.PATID THEN
		DO;
			FEV_LOCF=.;
		END;

	IF FEV NE . THEN
		FEV_LOCF=FEV;
RUN;

/*An alternative imputation technique for leading missing data is the "first*/
/*observation carried backwards" (FOCB) method*/
/*The first observation per subject is used for all leading missing values*/
/*Sorting time in descending order*/
PROC SORT DATA=FEV_Imputation2 OUT=FEV_Imputation3;
	BY PatId descending time;
RUN;

/*Implementing the FOCB WHILE COMBINIG BOTH LOCF/FOCB DATA*/
DATA FEV_imputation3;
	SET FEV_imputation3;

	/*Retaining the last observation and lastobsind is an 
	indicator which is 0 if last non-missing observation has not yet been reached before and 1 if it has been reached before*/
	RETAIN FEV_FOCB lastobsind;
	BY PatId;

	IF FIRST.PATID THEN
		DO;
			lastobsind=0;
			FEV_FOCB=.;
		END;

	IF FEV NE . THEN
		FEV_FOCB=FEV;

	* If last non-missing observation has not yet been reached before:;
	IF lastobsind=0 THEN
		DO;
			* if observation is non-missing, set lastobsind to 1 (meaning that last non-missing observation hast been reached);
			IF FEV_imputed NE . THEN
				lastobsind=1;

			* if observation is missing, replace it with last non-missing value;
			IF FEV_imputed=. THEN
				FEV_imputed=FEV_LOCF;
		END;
RUN;

/*Resorting the data*/
PROC SORT DATA=FEV_Imputation3 OUT=FEV_Imputation4;
	BY PatId time;
RUN;

DATA FEV_Imputation4;
	SET FEV_Imputation4;

	* lastobsind is an indicator which is 0 if first non-missing observation has not yet been reached before and 1 if it has been reached before;
	RETAIN firstobsind;
	BY PatId;

	* "reset" firstobsind for each subject;
	IF first.PatId THEN
		DO;
			firstobsind=0;
		end;

	* If first non-missing observation has not yet been reached before:;
	IF firstobsind=0 THEN
		DO;
			* if observation is non-missing, set firstobsind to 1 (meaning that first non-missing observation hast been reached);
			IF FEV_imputed NE . THEN
				firstobsind=1;

			* if observation is missing, replace it with first non-missing value;
			IF FEV_imputed=. THEN
				FEV_imputed=FEV_FOCB;
		END;
RUN;

/*Saving the dataset with LOCF/FOCB COMBINED*/
DATA SP.FEV_meanimputed_rand_LOCF;
	SET FEV_imputation4(rename=(FEV_imputed=FEV_LOCFFOCB));
	LABEL FEV_LOCFFOCB="Forced expiratory volume 1 sec - LOCF/FOCB imputed";
	DROP firstobsind lastobsind FEV_LOCF FEV_FOCB;
RUN;

/******************************************************************
 *******************************************************************
 *******************************************************************
 ********************LINEAR INTERPOLATION***************************
 *******************************************************************
 *******************************************************************/

/*Reading the dataset from library name SP*/
DATA FEV_Imputation;
	SET SP.FEV_meanimputed_rand_LOCF;
	FORMAT Treatment $trt.;
RUN;

PROC SORT DATA=FEV_imputation;
	BY Patid time;
RUN;

DATA FEV_Imputation2;
	SET FEV_Imputation;
	RETAIN timenonmis_prior fevnonmis_prior;
	BY PatId;

	IF FIRST.PATID THEN
		DO;
			timenonmis_prior=.;
			fevnonmis_prior=.;
		END;

	IF FEV_LOCFFOCB NE . THEN
		DO;
			timenonmis_prior=time;
			fevnonmis_prior=FEV_LOCFFOCB;
		END;
RUN;

PROC SORT DATA=FEV_Imputation2 OUT=FEV_Imputation3;
	BY PatId DESCENDING time;
RUN;

DATA FEV_Imputation3;
	SET FEV_Imputation3;
	RETAIN timenonmis_post fevnonmis_post;
	BY PatId;

	IF FIRST.PATID THEN
		DO;
			timenonmis_post=.;
			fevnonmis_post=.;
		END;

	IF FEV_LOCFFOCB NE . THEN
		DO;
			timenonmis_post=time;
			fevnonmis_post=FEV_LOCFFOCB;
		END;
RUN;

PROC SORT DATA=FEV_Imputation3 OUT=FEV_Imputation4;
	BY PatId time;
RUN;

DATA FEV_Imputation4;
	SET FEV_Imputation4;
	FEV_LOCFFOCB_LINIMP=FEV_LOCFFOCB;

	IF FEV_LOCFFOCB_LINIMP=. THEN
		DO;
			FEV_LOCFFOCB_LINIMP=fevnonmis_prior+(time-timenonmis_prior)*(fevnonmis_post-fevnonmis_prior)/(timenonmis_post-timenonmis_prior);
		END;
RUN;

DATA SP.FEV_meanimputed_rand_LOCF_linimp;
	SET FEV_imputation4;
	LABEL FEV_LOCFFOCB_LINIMP="Forced expiratory volume 1 sec - LOCF/FOCB + linear interpolation imputed";
	DROP fevnonmis_prior timenonmis_prior fevnonmis_post timenonmis_post;
RUN;

/******************************************************************
 *******************************************************************
 *******************************************************************
 ********************ANALYSIS OF IMPUTED DATA***********************
 *******************************************************************
 *******************************************************************/

/*Do you find an association between FEV1 (dependent variable) and age and */
/*sex(independent variables)?Is there an interaction between age and sex in */
/*the prediction of FEV1?*/
DATA FEV_Analysis;
	SET SP.FEV_meanimputed_rand_LOCF_linimp;
	FORMAT Treatment $trt.;
	age2=age*age;
RUN;

/*Presorting the data before analysis*/
PROC SORT DATA=FEV_Analysis;
	BY PatId time;
RUN;

/*Analysis with main effects for age and sex FOR*/
PROC GLM DATA=FEV_Analysis;
	CLASS SEX;
	MODEL  FEV_LOCFFOCB_LINIMP= SEX AGE/SOLUTION clparm;
	TITLE "(1) Model with main effects for Age and Sex";
RUN;

QUIT;

/*Analysis with main effects for Sex and age (reverse order!)*/
PROC GLM DATA=FEV_Analysis;
	CLASS Sex;
	MODEL FEV_LOCFFOCB_LINIMP = sex age;
	TITLE "(2) Model with main effects for Sex and Age";
RUN;

QUIT;

/*Analysis with interaction effect*/
PROC GLM DATA=FEV_Analysis;
	CLASS Sex;
	MODEL FEV_LOCFFOCB_LINIMP = Sex Age Sex * Age / SOLUTION clparm;
	TITLE "(3) Model with Sex, Age and the interaction term";
RUN;

QUIT;

/*Alternative Syntax for same model Sex|age*/
PROC GLM DATA=FEV_Analysis;
	CLASS Sex;
	MODEL FEV_LOCFFOCB_LINIMP = Sex|age / SOLUTION clparm;
	TITLE "(4) Alternative SAS syntax: Model with Sex, Age and the interaction term";
RUN;

QUIT;

/*Model 1: No interactions*/
PROC GLM DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV_LOCFFOCB_LINIMP = Age sex time treatment / SOLUTION;
     TITLE "(1) No interactions";
RUN;  
QUIT;

/*Model 2: Time-treatment-interaction*/
PROC GLM DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV_LOCFFOCB_LINIMP = Age sex time treatment time*treatment / SOLUTION;
     TITLE "(2) Time-treatment-interaction";
RUN;  
QUIT;

/*Model 3: Time-age-interaction*/
PROC GLM DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV_LOCFFOCB_LINIMP = Age sex time treatment time*age / SOLUTION;
     TITLE "(3) Time-age-interaction";
RUN;  
QUIT;

/*Model 4: Time-age-interaction*/
PROC GLM DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV_LOCFFOCB_LINIMP = Age sex time treatment time*sex / SOLUTION;
     TITLE "(4) Time-age-interaction";
RUN;  
QUIT;

/*Model 5: All interaction with time*/
PROC GLM DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV_LOCFFOCB_LINIMP = Age sex time treatment time*sex time*age time*treatment / SOLUTION;
     TITLE "(5) Time-age-interaction";
RUN;  
QUIT;

/*Model 6: With age^2*/
PROC GLM DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV_LOCFFOCB_LINIMP = Age sex time treatment age2/ SOLUTION;
     TITLE "(6) with age^2";
RUN;  
QUIT;

/*Fit model 6 also to unimputed data*/
PROC GLM DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV = Age sex time treatment age2/ SOLUTION;
     TITLE "(7) unimputed data";
RUN;  
QUIT;

PROC GLM DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV_Meanimprand = Age sex time treatment age2/ SOLUTION;
     TITLE "(8) unimputed data";
RUN;  
QUIT;

/*NOTE: Observations are correlated. Proc GLM no valid method. Use random intercept model instead*/
PROC MIXED DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV_LOCFFOCB_LINIMP = Age sex time treatment age2/ SOLUTION;
     RANDOM  Int / SUBJECT=PatId;
     REPEATED    / SUBJECT=PatId TYPE=AR(1);
     TITLE1 "MIXED, LOCF+FOCB+linear interpolation";
     TITLE2 "Fixed:   Sex Age Age^2 time treatment"   ;
     TITLE3 "Random:  Intercept";
     TITLE4 "Correlation within individual: AR(1)";
RUN;

/*Same model to unimputed data*/
PROC MIXED DATA=FEV_Analysis;
     CLASS Sex treatment;
     MODEL FEV = Age sex time treatment age2/ SOLUTION;
     RANDOM  Int / SUBJECT=PatId;
     TITLE1 "MIXED, original data (with missing)";
     TITLE2 "Fixed:   Sex Age Age^2 time treatment"   ;
     TITLE3 "Random:  Intercept";
     TITLE4 "Correlation within individual: AR(1)";
RUN;
TITLE;



/******************************************************************
 *******************************************************************
 *******************************************************************
 ********************MULTIPLE IMPUTATION****************************
 *******************************************************************
 *******************************************************************/

PROC SORT DATA=FEV_Analysis;
	BY PatId time;
RUN;

PROC MI data=FEV_Analysis out=FEV_Analysis_imputed nimpute=50;
	class sex treatment;
	var age age2 time sex treatment FEV;
	monotone reg(FEV = age age2 time sex treatment);
RUN;

/*Analyse the imputed data (using proc glm)*/

PROC GLM DATA=FEV_Analysis_imputed;
	CLASS Sex treatment;
	MODEL FEV = Age sex time treatment age2/ inverse SOLUTION;
	by _imputation_;
	ods output PARAMETERESTIMATES=glmparms InvXPX=glmpxi;
RUN;  
QUIT;

/*Rename some variables for Proc MIANALYZE to work properly;*/

DATA glmparms;
	SET glmparms;
	IF Parameter="Sex       F" THEN Parameter="Sex_F";
	IF Parameter="Sex       M" THEN Parameter="Sex_M";
	IF Parameter="Treatment Placebo" THEN Parameter="Dummy001";
	IF Parameter="Treatment Verum" THEN Parameter="Dummy002";
	IF stderr=. THEN delete;
RUN;

DATA glmpxi;
	SET glmpxi;
	RENAME 
			'Sex F'n=Sex_F
			'Sex M'n=Sex_M;
	IF Parameter="Sex F" THEN Parameter="Sex_F";
	IF Parameter="Sex M" THEN Parameter="Sex_M";
RUN;

/*Combined Analyses*/
PROC MIANALYZE parms=glmparms xpxi=glmpxi;
	MODELEFFECTS intercept age Sex_F time Dummy001 age2;
RUN;

/******************************************************************
 *******************************************************************
 *******************************************************************
 **********************AREA UNDER THE CURVE (AUC)********************
 *******************************************************************
 *******************************************************************/


DATA FEV_Analysis;
	SET SP.FEV_meanimputed_rand_LOCF_linimp;
	FORMAT Treatment $trt.;
	age2=age*age;
RUN;

/*Presorting the data before analysis*/
PROC SORT DATA=FEV_Analysis;
	BY PatId time;
RUN;

DATA FEV_AUC;
	SET FEV_Analysis;
	BY PATID;
	RETAIN AUC xpre ypre;
	IF FIRST.PATID THEN DO;
		AUC=0;
		xpre=time;
		ypre=FEV_LOCFFOCB_LINIMP;
	END;
	AUC=AUC + (time - xpre)*0.5*(FEV_LOCFFOCB_LINIMP+ypre);

	xpre=time;
	ypre=FEV_LOCFFOCB_LINIMP;

	IF LAST.PATID;
	KEEP PatID sex age Treatment AUC age2;
	LABEL AUC="AUC of FEV";
RUN;

/*Building Analysis model*/
PROC GLM DATA=FEV_AUC;
     CLASS Sex treatment;
     MODEL AUC = Age sex treatment / SOLUTION;
RUN;  
QUIT;

/********************************************************************/
/*********************ALTERNATIVE METHOD - LAG***********************/
/********************************************************************/
/*Computing the AUC of the FEV1 interpolated data*/

DATA AUC;
	SET FEV_Analysis;
	prevTime = lag(time);
	prevFEV = lag(FEV_LOCFFOCB_LINIMP);
	timeDiff = time - prevTime;
	BY PATID;
	RETAIN AUC;

	IF time NE 0 THEN	AUC=AUC +timeDiff*0.5*(FEV_LOCFFOCB_LINIMP+prevFEV);
	ELSE AUC=0;
	* Only keep last observation per subject;
	IF last.PatId;
	* Only keep relevant variables;
	KEEP PatID sex age Treatment AUC age2;
	LABEL AUC="AUC of FEV";
RUN;

/*Building Analysis model*/
PROC GLM DATA=AUC;
     CLASS Sex treatment;
     MODEL AUC = Age sex treatment / SOLUTION;
RUN;  
QUIT;

PROC  COMPARE BASE=FEV_AUC COMPARE=AUC;
RUN;

/********************************************************************/
/********************MCMC SIMULATION*********************************/
/********************************************************************/

DATA Glucose;
     INFILE 'A:\MSBiostat\SAS\00_Data\00_RawData\Glucose.csv' FIRSTOBS=2 DLM=";" ;
	 INPUT Id Glucose Treatment;
RUN;

/*key descriptive statistics and histograms*/
PROC TABULATE DATA=Glucose;
	CLASS treatment;
	VAR glucose;
	TABLE treatment="" all="Total",Glucose*(n nmiss mean std min q1 median q3 max)/box=[label="Treatment"];
RUN;

PROC SORT DATA=Glucose;
	BY treatment;
RUN;
/*plot histograms*/

PROC UNIVARIATE DATA=Glucose NOPRINT;
	HISTOGRAM Glucose/vscale=proportion;
	BY treatment;
RUN;

/*Both assumptions of t-test and Wilcoxon test are not met*/
PROC TTEST DATA=Glucose plots(shownull)=interval;
	CLASS TREATMENT;
	VAR Glucose;
	TITLE "Testing the difference of Glucose between treatments";
RUN;
TITLE;
/*Hence we do monte carlo simulations*/

*** Solution via SGPanel;
PROC SGPANEL DATA=glucose;
  panelby treatment/ novarname layout=rowlattice onepanel missing;
  rowaxis label="Proportion";
  HISTOGRAM glucose/scale=proportion;
RUN;

/*MCMC Initialization*/
PROC SORT DATA=Glucose;
	BY treatment Glucose;
RUN;

/*Approach I: Use Proc freq*/

PROC FREQ DATA=glucose;
	TABLE glucose/outcum out=eCDFfreq;
	BY treatment;
RUN;

/*Only keep relevant information;*/
DATA SP.eCDFfreq;
	set eCDFfreq;
	keep treatment glucose CUM_PCT;
	CUM_PCT=CUM_PCT/100;
	rename CUM_PCT=ecdf;
	label CUM_PCT="Empirical CDF";
RUN;

/*Approach II: Use PROC UNIVARIATE*/
ODS SELECT NONE; *do not show plots of ecdfs;
PROC UNIVARIATE DATA=Glucose NOPRINT;
	CDFPLOT glucose / vscale=proportion ;
	BY treatment;
	ODS OUTPUT cdfplot=eCDFuni;
RUN;
ODS SELECT ALL;

/*Only keep and save relevant information*/
DATA SP.eCDFuni;
	SET eCDFuni;
	KEEP treatment ECDFX ECDFY;
	RENAME ECDFY=ecdf ECDFX=glucose;
	LABEL ECDFY="Empirical CDF";
RUN;

/****************************************************/
/**Perform kernel density estimation*****************/
/****************************************************/

PROC SORT DATA=Glucose;
	BY treatment Glucose;
RUN;

PROC KDE DATA=Glucose;
     UNIVAR Glucose / GRIDL=80 GRIDU=125 NGRID=128 OUT=glucose_KDE;
	 BY Treatment;
	 TITLE "Kernel density estimation for glucose, per treatment group";
RUN;
TITLE;

/*Fit kernel density estimators to the data of each treatment group
Integrate using polygon integration*/
DATA ecdf_poly;
     RETAIN cdf0;
     SET glucose_KDE(KEEP=treatment value density);
     BY treatment;
	 lagdensity = LAG(density);
	 lagvalue = LAG(value); 
	 IF FIRST.treatment THEN DO;
       	cdf0 = 0; 
		lagvalue=.;
		lagdensity=.; 
	 END;

	 cdf0 = SUM(cdf0,(value-lagvalue)*(lagdensity + density)/2);  *** Note: This is not the cdf yet. Standardization to max=1 is missing so far;
RUN;

/*Standardize to obtain a maximum value of 1*/

PROC SORT DATA=ecdf_poly;
	BY treatment descending value;
RUN;

DATA ecdf_poly;
	SET ecdf_poly;
	BY treatment;
	RETAIN maxcdf;
	if first.treatment then maxcdf=cdf0;
	cdf0=cdf0/maxcdf;
RUN;

PROC SORT DATA=ecdf_poly;
	BY treatment cdf0;
RUN;

/*Only keep AND SAVE relevant data*/
DATA SP.ecdf_poly;
	set ecdf_poly;
	keep value treatment cdf0;
	rename value=glucose;
	label cdf0="CDF estimated via polygon integration" value="Glucose";
RUN;

/****************************************************/
/************INVERSION METHOD*****************/
/****************************************************/

/*****************/
/* Empirical CDF */
/*****************/

/*Draw random numbers from uniform distribution*/
DATA rand;
	call streaminit(1524);

	do i = 1 to 220;
		treatment=1;
		u=rand("UNIFORM");
		output;
	end;

	do i = 1 to 220;
		treatment=2;
		u=rand("UNIFORM");
		output;
	end;

	drop i;
RUN;

/*Merge all CDF values to each random number*/
PROC SQL NOPRINT;
	CREATE TABLE rand2 AS
	SELECT * FROM rand AS a LEFT JOIN
	SP.eCDFfreq AS b
	ON a.treatment=b.treatment;
QUIT;

PROC SORT DATA=rand2;
	BY treatment u ecdf;
RUN;

/*For each random number, find the inverse of the eCDF;*/
DATA rand3;
	set rand2;
	by treatment u;
	* Shifted value of ecdf;
	lagecdf=lag(ecdf);
	* reset for each random number;
	if first.u then lagecdf=.;
	* Ony keep rows where the random number is between ecdf and lag(ecdf). This corresponds to the glucose value we are searching for;
	if u>lagecdf and u LE ecdf ;
	* only keep relevant information;
	keep treatment glucose;
RUN;

/****************/
/* CDF from KDE */
/****************/

PROC SQL NOPRINT;
	CREATE TABLE rand4 AS
	SELECT * FROM rand AS a LEFT JOIN
	SP.ecdf_poly AS b
	ON a.treatment=b.treatment;
QUIT;

PROC SORT DATA=rand4;
	BY treatment u cdf0;
RUN;


/*For each random number, find the inverse of the eCDF;*/

DATA rand5;
	SET rand4;
	BY treatment u;
	* Shifted value of ecdf and glucose;
	lagcdf0=lag(cdf0);
	lagglucose=lag(glucose);
	* reset for each random number;
	IF first.u THEN lagcdf0=.;
	* Ony keep rows where the random number is between cdf0 and lag(cdf0). This corresponds to the glucose value we are searching for;
	IF u>lagcdf0 AND u LE cdf0 ;
	* Calculate inverse of estimated CDF (linearly interpolated);
	glucose_fit=(u-(lagcdf0-lagglucose*(cdf0-lagcdf0)/(glucose-lagglucose)))/((cdf0-lagcdf0)/(glucose-lagglucose));
	* only keep relevant information;
	KEEP treatment glucose_fit;
	RENAME glucose_fit=glucose;
RUN;

proc sort data=glucose;
by treatment;
run;

Proc means data=glucose;
var glucose;
by treatment;
output out=means mean=mean;
run;


* merge mean to data sets;
Proc sql noprint;
	create table rand3mean as
	select a.*,b.mean from 
	rand3 as a left join
	means as b
	on a.treatment=b.treatment
	;
	create table rand5mean as
	select a.*,b.mean from 
	rand5 as a left join
	means as b
	on a.treatment=b.treatment
	;
quit;


* Substract means from observations;

Data rand3mean;
	set rand3mean;
	glucosenull=glucose-mean;
run;

Data rand5mean;
	set rand5mean;
	glucosenull=glucose-mean;
run;


* Calculate mean difference;
ods select none; *do not show output;
proc ttest data=rand3mean;
	var glucosenull;
	class treatment;
	ods output Statistics=Diffsecdf;
run;
ods select all;

Data diffsecdf;
	set diffsecdf;
	if Class="Diff (1-2)";
	keep mean;
	rename mean=Meandiff;
	label mean="Meandiff";
run;

ods select none; *do not show output;
proc ttest data=rand5mean;
	var glucosenull;
	class treatment;
	ods output Statistics=Diffskde;
run;
ods select all;

Data Diffskde;
	set Diffskde;
	if Class="Diff (1-2)";
	keep mean;
	rename mean=Meandiff;
	label mean="Meandiff";
run;


/*****************/
/* Empirical CDF */
/*****************/

* Draw random numbers from uniform distribution;
Data rand;
	call streaminit(1524);
	do k = 1 to 1000;
		do i = 1 to 220;
		treatment=1;
		u=rand("UNIFORM");
		output;
		end;
		do i = 1 to 220;
		treatment=2;
		u=rand("UNIFORM");
		output;
		end;
	end;
	drop i;
run;

* Merge all CDF values to each random number;
Proc sql noprint;
	create table rand2 as
	select * from 
	rand as a left join
	SP.eCDFfreq as b
	on a.treatment=b.treatment
	;
quit;

* Sort data;
Proc sort data=rand2;
	by k treatment u ecdf;
run;

* For each random number, find the inverse of the eCDF;
Data rand3;
	set rand2;
	by k treatment u;
	* Shifted value of ecdf;
	lagecdf=lag(ecdf);
	* reset for each random number;
	if first.u then lagecdf=.;
	* Ony keep rows where the random number is between ecdf and lag(ecdf). This corresponds to the glucose value we are searching for;
	if u>lagecdf and u LE ecdf ;
	* only keep relevant information;
	keep k treatment glucose;
run;

/****************/
/* CDF from KDE */
/****************/

* Merge all CDF values to each random number;
Proc sql noprint;
	create table rand4 as
	select * from 
	rand as a left join
	SP.ecdf_poly as b
	on a.treatment=b.treatment
	;
quit;

* Sort data;
Proc sort data=rand4;
	by k treatment u cdf0;
run;

* For each random number, find the inverse of the eCDF;
Data rand5;
	set rand4;
	by k treatment u;
	* Shifted value of ecdf and glucose;
	lagcdf0=lag(cdf0);
	lagglucose=lag(glucose);
	* reset for each random number;
	if first.u then lagcdf0=.;
	* Ony keep rows where the random number is between cdf0 and lag(cdf0). This corresponds to the glucose value we are searching for;
	if u>lagcdf0 and u LE cdf0 ;
	* Calculate inverse of estimated CDF (linearly interpolated);
	glucose_fit=(u-(lagcdf0-lagglucose*(cdf0-lagcdf0)/(glucose-lagglucose)))/((cdf0-lagcdf0)/(glucose-lagglucose));
	* only keep relevant information;
	keep k treatment glucose_fit;
	rename glucose_fit=glucose;
run;


* Read glucose data;
DATA Glucose;
     INFILE 'A:\MSBiostat\SAS\00_Data\00_RawData\Glucose.csv' FIRSTOBS=2 DLM=";" ;
	 INPUT Id Glucose Treatment;
RUN; 

* Calculate mean per treatment group;
proc sort data=glucose;
by treatment;
run;

Proc means data=glucose;
var glucose;
by treatment;
output out=means mean=mean;
run;


* merge mean to data sets;
Proc sql noprint;
	create table rand3mean as
	select a.*,b.mean from 
	rand3 as a left join
	means as b
	on a.treatment=b.treatment
	;
	create table rand5mean as
	select a.*,b.mean from 
	rand5 as a left join
	means as b
	on a.treatment=b.treatment
	;
quit;


* Substract means from observations;

Data rand3mean;
	set rand3mean;
	glucosenull=glucose-mean;
run;

Data rand5mean;
	set rand5mean;
	glucosenull=glucose-mean;
run;

Proc sort data=rand3mean;
	by k;
run;

Proc sort data=rand5mean;
	by k;
run;

* Calculate mean difference;
ods select none; *do not show output;
proc ttest data=rand3mean;
	var glucosenull;
	class treatment;
	by k;
	ods output Statistics=Diffsecdf;
run;
ods select all;

Data diffsecdf;
	set diffsecdf;
	if Class="Diff (1-2)";
	keep k mean;
	rename mean=Meandiff;
	label mean="Meandiff";
run;

ods select none; *do not show output;
proc ttest data=rand5mean;
	var glucosenull;
	class treatment;
	by k;
	ods output Statistics=Diffskde;
run;
ods select all;

Data Diffskde;
	set Diffskde;
	if Class="Diff (1-2)";
	keep mean;
	rename mean=Meandiff;
	label mean="Meandiff";
run;

* Calculate critical values;

Proc univariate data=Diffsecdf;
	var meandiff;
	OUTPUT OUT=crit_ecdf PCTLPTS=2.5 97.5 PCTLPRE=Q;
run;

Proc univariate data=Diffskde;
	var meandiff;
	OUTPUT OUT=crit_kde PCTLPTS=2.5 97.5 PCTLPRE=Q;
run;


* Calculate mean difference in initial sample;
proc sort data=means;
	by treatment;
run;
Data meandiffobs;
	set means;
	lagmean=lag(mean);
	meandiff_obs=lagmean-mean;
	if lagmean NE .;
	keep meandiff_obs;
run;

* Merge meandiff to simulated data;
Proc sql noprint;
	create table diffsecdf_meanobs as
	select * from diffsecdf, meandiffobs;
	create table diffskde_meanobs as
	select * from diffskde, meandiffobs;
quit;

* get rid of replicas;
data diffsecdf_meanobs;
	set diffsecdf_meanobs;
	by k;

	if first.k;
run;

data diffskde_meanobs;
	set diffskde_meanobs;
	by k;

	if first.k;
run;

* calculate pvalues;
Data pval_ECDF;
	set diffsecdf_meanobs end=_eof_;
	retain sum;
	if abs(meandiff)>abs(meandiff_obs) then indicator=1;
	else indicator=0;
	n+1;
	if n=1 then sum=0;
	sum=sum+indicator;
	if n > 1 then pvalest=sum/(n+1);
	if _eof_;
	keep pvalest;
run;
Data pval_KDE;
	set diffskde_meanobs end=_eof_;
	retain sum;
	if abs(meandiff)>abs(meandiff_obs) then indicator=1;
	else indicator=0;
	n+1;
	if n=1 then sum=0;
	sum=sum+indicator;
	if n > 1 then pvalest=sum/(n+1);
	if _eof_;
	keep pvalest;
run;
