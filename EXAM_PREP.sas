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
	IF Treatment="P" THEN FEV_P=FEV;
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

     IF FEV_P > . THEN FEV_legendP = FEV_P;
     IF FEV_T > . THEN FEV_legendT = FEV_T;

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
		IF  Treatment="P" THEN DO;
			FEV_mean_P=FEV_mean;
			FEV_cil_P=FEV_mean-FEV_se;
			FEV_ciu_P=FEV_mean+FEV_se;
		END;
		IF  Treatment="T" THEN DO;
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
	IF FEV_Meanimp=. THEN FEV_Meanimp=fevmean;
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
	IF FEV_Meanimp=. THEN FEV_Meanimp=fevmean;
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