***********************************************************************************
***********************************************************************************
                                             Tennessee Department of Health
             CEDEP / Healthcare Associated Infections and Antimicrobial Stewardship Program
***********************************************************************************
***********************************************************************************
       Project:  NHSN AU Data Validation Reports

		Created: Yusuf

		Modified: Dipen M Patel

        Date: June 2025

       Version: V4

***********************************************************************************
***********************************************************************************
Description : Code Updated. New drugs added. AU rate consider Top 10 drugs. 

***********************************************************************************
***********************************************************************************
Notes: The program must be run after the end of the quarter of interest

***********************************************************************************
***********************************************************************************;

*Settings macro variables for paths and time period;

/*%let path=NHSN_20211117;*Update; */

 *Automatic setting of Quarter and Year Macro variables;     
%macro time ; 
%global quarter;
%global year;

data _null_;
call symputx ('quarter', qtr(intnx('qtr',today(),-1)));
run;

%if &quarter=4 %then %do;

data _null_;
call symputx ('year', year (today())-1);
run;
                                          %end;

                                  %else %do;

data _null_;
call symputx ('year', year (today()));
run;

                                           %end;
%mend;

%time;

%put &quarter &year;

                     *Other macro variables;

%let noflag=No Flags Identified;
Libname AU "H:\NHSN\Antimicrobial Stewardship\AUR Data\NHSN Current Download\AU - Current";

Options DLCREATEDIR; *This instructs SAS to create a directory if it does not exist in the libname path - 
                                              The goal is to automate the creation of an output folder that will have the name: 'Output_Qx 202x' ;
Libname Output "H:\NHSN\Antimicrobial Stewardship\AUR Data\AU\AU Data Validation\Output Q&quarter-&year";

%let path = H:\NHSN\Antimicrobial Stewardship\AUR Data\AU\AU Data Validation\Output Q&quarter-&year;

*Create DOT by adding sum of different routes;
data audatavalid1;
set au.summaryau_e ;
total_count=sum(IM_Count, IV_Count, digestive_Count, respiratory_Count);
diff=total_count-antimicrobialdays;
label total_count='Recalculated Days of Therapy' diff='Difference of  DOT';
if orgid = 44440 then delete;
run;

     *Deleting possible duplicates;

proc sort data=audatavalid1 nodup;
by orgid;
run;


*Importing Facilities name's table;

proc import datafile='H:\NHSN\Antimicrobial Stewardship\AUR Data\AUR Facilities.xlsx'
                          out=facs  dbms=excel replace;sheet='AU Facilities$'; run;

data facs_clean;
set facs (keep=name Org_ID Code where=(org_id ne .));
run;

*Joining facs table with main AU data;

proc sql;
create table audatavalid as
select a.* , b.name
from audatavalid1 a left join facs_clean b on a.orgid=b.org_id;
quit;


*Route Mismatch;

data audatavalid;
set audatavalid;
length mismatch $ 50;
mismatch=' ';
*PO only;
	if drugDescription in ('AMAN - AMANTADINE' 'AMOX - AMOXICILLIN'  'AMOXWC - AMOXICILLIN WITH CLAVULANATE' 'BALMAR - BALOXAVIR MARBOXIL'
							'CEFAC - CEFACLOR'  'CEFAD - CEFADROXIL' 'CEFDIN - CEFDINIR' 'CEFDIT - CEFDITOREN' 'CEFIX - CEFIXIME' 'CEFPO - CEFPODOXIME'
							'CEFPRO - CEFPROZIL' 'CEFTIB - CEFTIBUTEN' 'CEPHLX - CEPHALEXIN' 'CLARTH - CLARITHROMYCIN' 'DICLOX - DICLOXACILLIN' 'FIDAX - FIDAXOMICIN' 'ERYTHWS - ERYTHROMYCIN WITH SULFISOXAZOLE'
							'FOSFO - FOSFOMYCIN' 'GEMIF - GEMIFLOXACIN' 'ITRA - ITRACONAZOLE' 'MOLNU - MOLNUPIRAVIR' 'NIRMA - NIRMATRELVIR' 'NITRO - NITROFURANTOIN' 'OSELT - OSELTAMIVIR' 'PENV - PENICILLIN V' 'PIVMEC - PIVMECILLINAM' 'RIMAN - RIMANTADINE'
							'SULFI - SULFISOXAZOLE' 'TELITH - TELITHROMYCIN' 'TETRA - TETRACYCLINE' 'TINID - TINIDAZOLE') 
						and (IM_Count >0 or  IV_Count>0 or respiratory_Count>0) 
	then mismatch='Should be PO only';
*IV only;
	if drugDescription in ('ANID - ANIDULAFUNGIN' 'CASPO - CASPOFUNGIN' 'CEFENMET - CEFEPIME/ENMETAZOBACTAM' 'CEFID - CEFIDEROCOL' 'CEFTAR - CEFTAROLINE' 'CEFTAVI - CEFTAZIDIME/AVIBACTAM'
							'CEFTOMED - CEFTOBIPROLE MEDOCARIL' 'CEFTOTAZ - CEFTOLOZANE/TAZOBACTAM' 'CHLOR - CHLORAMPHENICOL' 'DALBA - DALBAVANCIN' 'DAPTO - DAPTOMYCIN' 'DORI - DORIPENEM'
							'ERAV - ERAVACYCLINE' 'IMICILRE - IMIPENEM/CILASTATIN/RELEBACTAM' 'IMIPWC - IMIPENEM WITH CILASTATIN' 'MERO - MEROPENEM' 'MEROVAB - MEROPENEM/VABORBACTAM'
							'MICA - MICAFUNGIN' 'ORITAV - ORITAVANCIN' 'PERAM - PERAMIVIR' 'PIPERWT - PIPERACILLIN WITH TAZOBACTAM' 'PLAZO - PLAZOMICIN' 'QUINWD - QUINUPRISTIN WITH DALFOPRISTIN' 
							'REMDES - REMDESIVIR' 'REZA - REZAFUNGIN' 'SULDUR - SULBACTAM/DURLOBACTAM' 'TELAV - TELAVANCIN' 'TICARWC - TICARCILLIN WITH CLAVULANATE' 'TIG - TIGECYCLINE')
				and (IM_Count >0 or  digestive_Count>0 or respiratory_Count>0) 
	then mismatch='Should be IV only';
*IM only;
	if drugDescription in ('NIRS - NIRSEVIMAB') 
						and (digestive_Count >0 or  IV_Count>0 or respiratory_Count>0) 
	then mismatch='Should be IM only';
*INH only;
	if drugDescription='ZANAM - ZANAMIVIR' and (IM_Count >0 or  digestive_Count>0 or IV_Count>0) then mismatch='Should be INH only';
*IM and IV only;
	if drugDescription in ('AMPIWS - AMPICILLIN WITH SULBACTAM' 'CEFAZ - CEFAZOLIN' 'CEFEP - CEFEPIME' 'CEFOT - CEFOTAXIME' 'CEFOX - CEFOXITIN' 'CEFTIZ - CEFTIZOXIME'
							'CEFTRX - CEFTRIAXONE' 'CTET - CEFOTETAN' 'ERTA - ERTAPENEM' 'NAF - NAFCILLIN' 'OX - OXACILLIN' 'PENG - PENICILLIN G' 'PIPER - PIPERACILLIN') 
					and (digestive_Count>0 or respiratory_Count>0) 
	then mismatch='Should be IM and IV only';
*IV+PO;
	if drugDescription in ('AZITH - AZITHROMYCIN' 'DELAF - DELAFLOXACIN' 'DOXY - DOXYCYCLINE' 'ERYTH - ERYTHROMYCIN' 'FLUCO - FLUCONAZOLE'
							'ISAVUC - ISAVUCONAZONIUM' 'LEFAMU - LEFAMULIN' 'LEVO - LEVOFLOXACIN' 'LNZ - LINEZOLID' 'METRO - METRONIDAZOLE' 'MINO - MINOCYCLINE' 'MOXI - MOXIFLOXACIN' 'OMAD - OMADACYCLINE' 
							'POSAC - POSACONAZOLE' 'RIF - RIFAMPIN'  'SULFAET - SULFAMETHOXAZOLE WITH TRIMETHOPRIM' 'TEDIZ - TEDIZOLID' 'VORI - VORICONAZOLE') 
					and (IM_Count>0 or respiratory_Count>0) 
	then mismatch='Should be PO and IV only';
*IV+INH;
	if drugDescription in ('AMPBLIC - AMPHOTERICIN B LIPID COMPLEX' 'AMPH - AMPHOTERICIN B'  'AMPHOT- AMPHOTERICIN B LIPOSOMAL') 
						and (digestive_Count>0 or IM_Count>0) 
	then mismatch='Should be IV and INH only';
*IM+IV+PO;
	if drugDescription in ('AMP - AMPICILLIN' 'CEFUR - CEFUROXIME' 'CLIND - CLINDAMYCIN') 
						and respiratory_Count>0 
	then mismatch='Should NOT be INH';
*IV+PO+INH ;
if drugDescription in ('VANC - VANCOMYCIN' 'CIPRO - CIPROFLOXACIN') and IM_Count>0 then mismatch='Should NOT be IM';
*IM+IV+INH;
	if drugDescription in ('AMK - AMIKACIN' 'AZT - AZTREONAM' 'CEFTAZ - CEFTAZIDIME' 'COLIST - COLISTIMETHATE' 'GENTA - GENTAMICIN' 'PB - POLYMYXIN B' 'TOBRA - TOBRAMYCIN')
						and digestive_Count>0 
	then mismatch='Should NOT be PO';
label mismatch='Mismatch Type';
run;


*Creating a style;

ods escapechar='^';
ods path(prepend) work.templat(update);
proc template;
	define style Styles.valid;
	parent=Styles.rtf;

	replace fonts /
		'TitleFont' = ("Cambria",14pt, Bold)
		'TitleFont2' = ("Cambria",14pt)
		'StrongFont' = ("Cambria",9pt)
		'EmphasisFont' = ("Open Sans",9pt)
		'headingEmphasisFont' = ("Open Sans",10pt)
		'headingFont' = ("Open Sans",8pt, Bold)
		'docFont' = ("Open Sans",8pt)
		'footFont' = ("Open Sans",8pt)
		'FixedEmphasisFont' = ("Open Sans",8pt)
		'FixedStrongFont' = ("Open Sans",8pt)
		'FixedHeadingFont' = ("Open Sans",8pt)
		'BatchFixedFont' = ("Open Sans",6.7pt)
		'FixedFont' = ("Open Sans",8pt);

       replace Table from Output /
		frame = hsides
		cellpadding = 4pt
		cellspacing = 0pt
		borderwidth = 1.2pt;
	end;
run;

/* Creating macro to select facilities name and orgID */
 
 proc sql ;
 select distinct orgid, name, count (distinct orgid) into: org separated by '/', :hosp separated by '/',:n
 from audatavalid
where orgid in (10017 10100 16098)
 order by orgid;
 %put  &hosp &n;
 quit;

 /* Macro Programs for Decoration Style */

 %macro decor1 (title);*This will be used when there is no flag;
 	 ods pdf text="^S={font_weight=bold font_size=14pt just=center  font_face='Cambria' } &title";
	 ods pdf text=" ";
     ods pdf text=" ";
     ods pdf text=" ";
	 ods pdf text="^S={font_style=italic font_size=10pt just=center font_face='Cambria' } &noflag";
%mend;

 %macro decor2; *This will be used for spacing between sections;
	 ods pdf text="^S={font_weight=bold font_size=14pt  font_face='Cambria' } ";
     ods pdf text=" ";
%mend;

%macro decor3 (title); *This will be used when there is no historical data;
     ods pdf text="^S={font_weight=bold font_size=14pt just=center  font_face='Cambria' } &title";
	 ods pdf text=" ";
     ods pdf text=" ";
     ods pdf text=" ";
	 ods pdf text="^S={font_style=italic font_size=10pt just=center font_face='Cambria' } Not Enough Historical Data Available";
%mend;

%macro decor4 (title);*This will be used when there is an output to be printed;
     ods pdf text="^S={font_weight=bold font_size=14pt just=center  font_face='Cambria' } &title";
	 ods pdf text=" ";
     ods pdf text=" ";
     ods pdf text=" ";
%mend;


%macro decor5 (rationale, solution);*This will be used when there is an output to be printed;
       ods pdf text=" ";
       ods pdf text=" ";
     ods pdf text="^S={font_weight=bold font_size=8pt just=left  font_face='Cambria' }Rationale:^S={font_weight=medium font_size=8pt}&rationale";
	 ods pdf text=" ";
     ods pdf text="^S={font_weight=bold font_size=8pt just=left  font_face='Cambria' }Potential Solutions:^S={font_weight=medium  font_size=8pt }&solution";
     ods pdf text=" ";
%mend;

%macro decor6; 
	 ods pdf text="^S={font_style=italic font_size=14pt just=center font_face='Cambria' }No data submitted for the current quarter";
     ods pdf text=" ";
%mend;

* Clear Log Window ;
DM "log; clear; ";

 /* Final macro program */

options symbolgen mprint mlogic mcompilenote=all ;

%macro validation ;


 %do i=1 %to 3;


 options nodate number papersize=standard orientation=portrait;
title ' ';
data audata;
 set audatavalid;
 where year(summaryYM)=&year and qtr(summaryYM)=&quarter and orgid=%scan(&org,&i, '/');
 drug=Propcase(scan(drugdescription, 2, '-'));
run;


proc sql noprint;
select nobs into: obs
from  dictionary.tables where memname="AUDATA";
quit;


 	ods pdf file="&path\%scan(%bquote(&hosp),&i, '/').pdf"  
               startpage=nEVER notoc style=valid;
	ods layout START columns=1 column_widths=(8in);

ods escapechar='^';
 ods pdf text='^S={preimage="H:\NHSN\Antimicrobial Stewardship\AUR Data\AU\AU Data Validation\TDH Logo.png" just=c}';
 ods pdf text="  "; /* Each  blank ods pdf text will pad the line with blank space*/
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
 ods pdf text=" ^S={font_weight=bold font_size=22pt just=center font_face='Cambria' textdecoration=underline} Data Validation Report for Q&quarter.-&year";
 ods pdf text=" ";
 ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
 ods pdf text=" ^S={font_weight=bold font_size=18pt just=center font_face='Cambria' } %scan(%bquote(&hosp),&i, '/')";
ods pdf text="     "; /* Each  blank ods pdf text will pad the line with blank space, so the actual report will start on the 2nd page */
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text="^S={font_weight=bold font_size=14pt just=left font_face='Cambria' } Abbreviations used in this Document:";
ods pdf text=" ";
ods pdf text="ADT – Admission/Discharge/Transfer ";
ods pdf text="ASP – Antimicrobial Stewardship Program ";
ods pdf text="AU – Antimicrobial Use ";
ods pdf text="BCMA – Bar Code Medication Administration ";
ods pdf text="ED – Emergency Department ";
ods pdf text="eMAR – electronic Medication Administration Record";
ods pdf text="FACWIDE or FACWIDEIN – Facility Wide Inpatient ";
ods pdf text="IM - Intramuscular";
ods pdf text="IQR – Interquartile range";
ods pdf text="IV - Intravenous ";
ods pdf text="NHSN – National Healthcare Safety Network";
ods pdf text="OR – Operating Room ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
ods pdf text=" ";
 
%if %eval(&obs > 1) %then %do;

*********************************************+ ALL FACIITY LEVEL +***********************************************************;
*Data Processing to create Pooled DOT for each facility;

proc sql;
create table dot as 
select orgid, summaryym, sum (antimicrobialDays) as pooledDOT 
from audata
group by 1, 2;
create table audata2 as
select a.*, b.pooleddot
from audata a left join dot b
on a.orgid=b.orgid and a.summaryym=b.summaryym;
quit;

proc sort data=audata2 out=sorted nodupkey;
by orgid location summaryym;
run;

/*proc sql;
create table dot_vs_dp as
select a.*, b.PooledDP
from audata2 a inner left join (select orgid, summaryym,sum(numDaysPresent) as PooledDP 
                                                   from (select distinct orgid, location, summaryym, numDaysPresent from audata)
												   group by 1,2) b
												   on a.orgid=b.orgid and a.summaryym=b.summaryym;
quit;


*Pooled Monthly DOT > DP for any month;
proc print data=dot_vs_dp noobs label;
title 'Pooled Days of Therapy GREATER THAN Days Present For a Specific Month';
var  orgid summaryym pooledDOT numDaysPresent;
where pooledDOT > numDaysPresent;
run;
     */

*1-Antimicrobial days reported for any drug when days present are reported as zero;

proc sql;
create table indic1 as
select * from audata
where antimicrobialDays>0  and numDaysPresent=0;
quit;

    %if %eval(&sqlobs > 0) %then %do;
		Data Indic1_%scan(&org,&i, '/');
			set indic1;
			keep orgid summaryym location drugDescription antimicrobialDays numDaysPresent;
			label orgid='Org ID' summaryym='Month'  location='Location' drugDescription='Drug' antimicrobialDays='Antimicrobial Days'
		         numDaysPresent='Days Present';
		RUN;

		%decor4 (Antimicrobial Days Reported for any Drug when Days Present Reported as Zero);

		proc print data=indic1_%scan(&org,&i, '/') noobs label;	
		*title 'Antimicrobial Days Reported for any Drug when Days Present Reported as Zero';
		run;
     %end;

	 %else %do;
	     %decor1(Antimicrobial Days Reported for any Drug when Days Present Reported as Zero);
		 proc sql;
		 	Create table NF_Indic1_%scan(&org,&i, '/') as 
			select distinct orgid, Name from audatavalid
			where year(summaryYM)=&year and qtr(summaryYM)=&quarter and orgid=%scan(&org,&i, '/');
		quit;
	 %end;
      
	 %decor5 (%str(This report flags when a location reports antimicrobial use for any agent but reports 0 days present for the location.  If no patients were present on a given location, then no antimicrobial days should be reported.),
	                   %str(If patients were present at the location, check with vendor to ensure surveillance software is accurately pulling and reporting ADT data.  If no patients were present at the location, check to ensure surveillance software is accurately pulling eMAR/BCMA data and attributing it to the correct location.))
	%decor2;

*2-Antimicrobial days for a single drug > Days Present for a given location or for FacWideIn;


proc sql;
create table indic2 as
select * from audata
where antimicrobialDays>numDaysPresent and numDaysPresent not in (0, .) ;
quit;

	%if %eval(&sqlobs > 0) %then %do; 
	
		Data Indic2_%scan(&org,&i, '/');
			set indic2;
			keep orgid summaryym location drugDescription antimicrobialDays numDaysPresent;
			label orgid='Org ID' summaryym='Month'  location='Location' drugDescription='Drug' antimicrobialDays='Antimicrobial Days'
		         numDaysPresent='Days Present';
		run;

		%decor4 (Reported Antimicrobial Days for a Single Drug Greater than Days Present);

		proc print data=Indic2_%scan(&org,&i, '/') noobs label;
		*title 'Reported Antimicrobial Days for a Single Drug Greater Than Days Present';
		run;
	%end;
	%else %do;
		%decor1(Reported Antimicrobial Days for a Single Drug Greater Than Days Present);
		 proc sql;
		 	Create table NF_Indic2_%scan(&org,&i, '/') as 
			select distinct orgid, Name from audatavalid
			where year(summaryYM)=&year and qtr(summaryYM)=&quarter and orgid=%scan(&org,&i, '/');
		quit;
	%end;

	 %decor5(%str(Based on the NHSN AU Protocol, a single patient can only contribute up to one antimicrobial day per drug per location.  Therefore, total antimicrobial days for an individual drug may not exceed reported days present.),
	                   %str(Review your eMAR/BCMA system antimicrobial day counts to ensure the vendor system attributes only one total antimicrobial day per drug per patient per calendar day regardless of how many doses were administered to the patient during that day. Review the ADT system days present to ensure the vendor system attributes one day present per patient if the patient is in the location at any time during that calendar day . Then check with your vendor for the next steps on addressing this data quality issue.))
     %decor2;
	/*
*3-Pooled DOT=0 or missing;

proc sql;
create table indic3 as
select * from sorted
where pooledDOT=0 or pooledDOT=.;
quit;

%if %eval(&sqlobs > 0) %then %do; 

%decor4 (Missing or Null Reported Days of Therapy For a Specific Month);

proc print data=sorted noobs label;
var  orgid summaryym pooledDOT;
where pooledDOT=0 or pooledDOT=.;
label orgid='Org ID' summaryym='Month' pooleddot='Antimicrobial Days ' ;
run;

%end;

	 %else %do;

	 %decor1(Missing or Null Reported Days of Therapy For a Specific Month);

	 %end;
     
	 %decor5(%str(For an individual drug, available antimicrobial days were available for at least one month, but not available for at least one of the other two months during this quarter.),
	                   %str(For an individual drug, review your eMAR/BCMA system antimicrobial day counts to ensure the vendor system has included them in that month’s report.  If no antimicrobial days are available for any drugs for a given month, ensure that NHSN AU Option data is included in that month’s NHSN Reporting Plan and that data has been uploaded appropriately.))
	%decor2;
*4-DP=0 or missing;

proc sql;
create table indic4 as
select * from sorted
where  numDaysPresent=. or numDaysPresent=0 ;
quit;

%if %eval(&sqlobs > 0) %then %do; 

%decor4(Missing or Null Reported Days Present for a Specific Month in any Location);

proc print data=sorted noobs label;
var  orgid location summaryym numDaysPresent;
where  numDaysPresent=. or numDaysPresent=0 ;
label orgid='Org ID' summaryym='Month'  location='Location' 
         numDaysPresent='Days Present';
run;

%end;

	 %else %do;

	 %decor1(Missing or Null Reported Days Present for a Specific Month in any Location);

	 %end;
     
	 %decor5(%str(For an individual drug, available days present were available for at least one month, but not available for at least one of the other two months during this quarter.),
	                   %str(For an individual drug, review your ADT system days present data to ensure the vendor system has included them in that month’s report.  If no days present are available for any drugs for a given month, ensure that NHSN AU Option data is included in that month’s NHSN Reporting Plan and that data has been uploaded appropriately.))
	 %decor2; */
*********************************************+ DRUG LEVEL +*******************************************************************; 

*5-IM+IV+PO+INH  <  total DOT for each drug;

proc sql;
create table indic5 as
select * from audata
where total_count < antimicrobialDays;
quit;

	%if %eval(&sqlobs > 0) %then %do; 
		Data Indic5_%scan(&org,&i, '/');
			set indic5;
			Keep orgid location summaryym  IM_Count IV_Count digestive_Count respiratory_Count total_count antimicrobialDays;
			where total_count < antimicrobialDays;*Total Count should always be >= antimicrobial days ;
			label IM_count='IM' IV_count='IV' digestive_count='Oral' respiratory_count='Respiratory'  
			         orgid='Org ID' summaryym='Month'  location='Location' antimicrobialDays='Antimicrobial Days';
		run;
	%decor4(Sum of Routes Less than Reported Total Days of Therapy);
 		proc print data=Indic5_%scan(&org,&i, '/') noobs label;
		/*title 'Sum of Routes Less than Reported Total Days of Therapy';*/
		run;
	%end;
	%else %do;
	   %decor1(Sum of Routes Less than Reported Total Days of Therapy);
	    proc sql;
		 	Create table NF_Indic5_%scan(&org,&i, '/') as 
			select distinct orgid, Name from audatavalid
			where year(summaryYM)=&year and qtr(summaryYM)=&quarter and orgid=%scan(&org,&i, '/');
		quit;
	%end;
     
     %decor5(%str(Based on the NHSN AU Protocol, the total antimicrobial day count should only include IV, IM, digestive, and respiratory administrations.  Therefore, the total antimicrobial days should always be equal to or greater than the sum of these four routes.),
	                  %str(For each location/month/drug listed in this table, review the data in your eMAR/BCMA system to determine if your vendor system is incorrectly including additional routes of administration (e.g. intrapleural, irrigation, topical) in your total antimicrobial day counts.  If this is the case, work with the vendor to ensure only IV, IM, digestive, and respiratory routes are being included in the total antimicrobial days count.))
	 %decor2;
*6-Ceftriaxon IM not used in ED;

proc sql;
create table indic6 as
select * from audata2
where locCDC in ('OUT:ACUTE:ED', 'OUT:ACUTE:ED:PED') and IM_count=0 and drugDescription='CEFTRX - CEFTRIAXONE';
quit;

	%if %eval(&sqlobs > 0) %then %do;
	Data Indic6_%scan(&org,&i, '/');
		set indic6;
		keep orgid location summaryym drugDescription IM_count;
		where locCDC in ('OUT:ACUTE:ED', 'OUT:ACUTE:ED:PED') and IM_count=0 and drugDescription='CEFTRX - CEFTRIAXONE';
		label orgid='Org ID' summaryym='Month'  location='Location' drugDescription='Drug' IM_count='IM Days of Therapy';
	run;
	%decor4(Ceftriaxone IM not Used in ED);
		proc print data=Indic6_%scan(&org,&i, '/') noobs label ;
		/*title 'Ceftriaxon IM not Used in ED';*/
		run;
	%end;
	%else %do;
		%decor1(Ceftriaxone IM not Used in ED);
		 proc sql;
		 	Create table NF_Indic6_%scan(&org,&i, '/') as 
			select distinct orgid, Name from audatavalid
			where year(summaryYM)=&year and qtr(summaryYM)=&quarter and orgid=%scan(&org,&i, '/');
		quit;
	%end;
	 %decor5(%str(Ceftriaxone is commonly given via the IM route in the ED.  If the facility reports ED antimicrobial use into the NHSN AU Option, this flag can be used as an indicator to ensure that IM antimicrobial days are accurately pulling into the AU Option and that ED are accurately pulling into the AU Option.  If antimicrobial days for the ED location are present, it would be unlikely than none of the ceftriaxone use was given via the IM route.  If your facility did not report any ED location data, this report will read “No flags identified”.   ),
                       %str(For the ED location, review the data in your eMAR/BCMA system to determine if your vendor system is not including the IM route of administration for your ceftriaxone antimicrobial day counts.  If this is the case, work with the vendor to ensure that IM routes are accurately pulled into the antimicrobial days count.))
	 %decor2;

*7-Cefazolin not used in OR;

proc sql;
create table indic7 as
select * from audata2
where locCDC='IN:ACUTE:OR'  and IV_count=0 and drugDescription='CEFAZ - CEFAZOLIN';
quit;

	%if %eval(&sqlobs > 0) %then %do;
		Data Indic7_%scan(&org,&i, '/');
			set Indic7;
			keep orgid location summaryym drugDescription IV_count;
			where locCDC='IN:ACUTE:OR'  and IV_count=0 and drugDescription='CEFAZ - CEFAZOLIN';
			label orgid='Org ID' summaryym='Month'  location='Location' drugDescription='Drug' IV_count='IV Days of Therapy';
		run;
	%decor4(Cefazolin not Used in OR);
		proc print data=Indic7_%scan(&org,&i, '/') noobs label ;
		/*title 'Cefazolin not Used in OR';*/
		run;
	%end;
	%else %do;
		 %decor1(Cefazolin not Used in OR);
		  proc sql;
		 	Create table NF_Indic7_%scan(&org,&i, '/') as 
			select distinct orgid,name from audatavalid
			where year(summaryYM)=&year and qtr(summaryYM)=&quarter and orgid=%scan(&org,&i, '/');
		quit;
	%end;

	 %decor5(%str(Cefazolin is commonly given via the IV route for surgical prophylaxis in the OR.  If the facility reports OR antimicrobial use into the NHSN AU Option, this flag can be used as an indicator to ensure that OR antimicrobial days are accurately pulling into the AU Option.  If antimicrobial days for the OR location are present, it would be unlikely than no cefazolin use was given in this location.  It would also be warranted to check if other agents used for prophylaxis (e.g. vancomycin) are also omitted from your OR antimicrobial days report.   If your facility did not report any OR location data, this report will read “No flags identified”.  ),
                       %str(For the OR location, review the data in your eMAR/BCMA system to determine if your vendor system is accurately including ALL antimicrobial days.  If this is not the case, work with the vendor to ensure that the OR antimicrobial days are being pulled appropriately.))
   %decor2;
*8-For drugs given once daily: sum of routes NOT = total DOT / / However we chose to tolerate a difference of less than 5;

proc sql;
	create table indic8 as
	select * from audata2
	where drugDescription in ('AMPBLIC - AMPHOTERICIN B LIPID COMPLEX' 'AMPH - AMPHOTERICIN B' 'AMPHOT- AMPHOTERICIN B LIPOSOMAL' ' ANID - ANIDULAFUNGIN' 'AZITH - AZITHROMYCIN' 
							  'BALMAR - BALOXAVIR MARBOXIL' 'CASPO - CASPOFUNGIN' 'CEFTIB - CEFTIBUTEN' 'DALBA - DALBAVANCIN' 'DAPTO - DAPTOMYCIN' 'FLUCO - FLUCONAZOLE' 'FOSFO - FOSFOMYCIN'
							  'GEMIF - GEMIFLOXACIN' 'LEVO - LEVOFLOXACIN' 'MICA - MICAFUNGIN' 'MOXI - MOXIFLOXACIN' 'NIRS - NIRSEVIMAB' 'ORITAV - ORITAVANCIN' 'PENG - PENICILLIN G'
							  'PERAM - PERAMIVIR' 'PLAZO - PLAZOMICIN' 'REMDES - REMDESIVIR' 'REZA - REZAFUNGIN' 'TEDIZ - TEDIZOLID' 'TELAV - TELAVANCIN' 'TELITH - TELITHROMYCIN') 
							and total_count > antimicrobialDays and diff>5;
quit;

	%if %eval(&sqlobs > 0) %then %do; 
		Data Indic8_%scan(&org,&i, '/');
			set Indic8;
			keep orgid location summaryym drug IM_Count IV_Count digestive_Count respiratory_Count total_count antimicrobialDays;
			where drugDescription in ('AMPBLIC - AMPHOTERICIN B LIPID COMPLEX' 'AMPH - AMPHOTERICIN B' 'AMPHOT- AMPHOTERICIN B LIPOSOMAL' ' ANID - ANIDULAFUNGIN' 'AZITH - AZITHROMYCIN' 
							  'BALMAR - BALOXAVIR MARBOXIL' 'CASPO - CASPOFUNGIN' 'CEFTIB - CEFTIBUTEN' 'DALBA - DALBAVANCIN' 'DAPTO - DAPTOMYCIN' 'FLUCO - FLUCONAZOLE' 'FOSFO - FOSFOMYCIN'
							  'GEMIF - GEMIFLOXACIN' 'LEVO - LEVOFLOXACIN' 'MICA - MICAFUNGIN' 'MOXI - MOXIFLOXACIN' 'NIRS - NIRSEVIMAB' 'ORITAV - ORITAVANCIN' 'PENG - PENICILLIN G'
							  'PERAM - PERAMIVIR' 'PLAZO - PLAZOMICIN' 'REMDES - REMDESIVIR' 'REZA - REZAFUNGIN' 'TEDIZ - TEDIZOLID' 'TELAV - TELAVANCIN' 'TELITH - TELITHROMYCIN') and total_count > antimicrobialDays and diff>5;
			label IM_count='IM' IV_count='IV' digestive_count='Oral' respiratory_count='Respiratory' antimicrobialdays='Reported Antimicrobial Days'  
			         orgid='Org ID' summaryym='Month'  location='Location' drug='Drug';
		run;
	%decor4 (Sum of Routes Greater than Reported Total Days of Therapy for Drugs given Once Daily);
		proc print data=Indic8_%scan(&org,&i, '/') noobs label;
		/*title 'Sum of Routes Greater than Reported Total Days of Therapy for Drugs given Once Daily';*/
		run;
	%end;
	%else %do;
		 %decor1(Sum of Routes Greater than Reported Total Days of Therapy for Drugs given Once Daily);
		  proc sql;
		 	Create table NF_Indic8_%scan(&org,&i, '/') as 
			select distinct orgid, name from audatavalid
			where year(summaryYM)=&year and qtr(summaryYM)=&quarter and orgid=%scan(&org,&i, '/');
		quit;
	%end;
    
	 %decor5(%str(It is not uncommon for the sum of routes to be greater than the reported total days of therapy for drugs administered multiple times per day (e.g. ciprofloxacin given IV in the AM and via digestive route in the PM would contribute 1 DOT to the IV route, 1 DOT to the digestive route, and 1 DOT to the total antimicrobial days count) .  It is less common for this scenario to occur when a drug is administered once daily.),
                        %str(For each location/month/drug listed in this table, review the data in your eMAR/BCMA system to determine if your vendor system is incorrectly including additional routes of administration (for example, intrapleural, irrigation, topical) in your total antimicrobial day counts.  If this is the case, work with the vendor to ensure only IV, IM, digestive, and respiratory routes are being included in the total antimicrobial days count.  If no technical issue is identified, review eMAR/BCMA to identify specific cases to identify if the drug in question is routinely being administered too frequently.))
	 %decor2;
/*
*For drugs given more than once daily: sum of routes NOT > total DOT;

proc print data=audata2 noobs label;
title 'Sum of Routes Less or Equal Reported Total Days of Therapy for Drugs given more than Once Daily';
var orgid location summaryym drug IM_Count IV_Count digestive_Count respiratory_Count total_count antimicrobialDays;
where drugDescription not in ('AMPH - Amphotericin B', 'AMPHOT- Amphotericin B Liposomal', 'ANID - Anidulafungin', 'AZITH - Azithromycin',
'CASPO - Caspofungin', 'CEFTIB - Ceftibuten', 'DALBA - Dalbavancin', 'DAPTO - Daptomycin', 'ERTA - Ertapenem', 'FLUCO - Fluconazole',
'FOSFO - Fosfomycin', 'GEMIF - Gemifloxacin', 'LEVO - Levofloxacin', 'MICA - Micafungin', 'MOXI - Moxifloxacin', 'ORITAV - Oritavancin', 
'PERAM - Peramivir', 'TEDIZ - Tedizolid', 'TELAV - Telavancin', 'TELITH - Telithromycin') and total_count < antimicrobialDays;
label IM_count='IM' IV_count='IV' digestive_count='PO' respiratory_count='Respiratory' antimicrobialdays='DOT'  summaryym='Quarter';
run;
*/


*9-Route Mismatch;

proc sql;
create table indic9 as
select * from audata
where mismatch ne '';
quit;

	%if %eval(&sqlobs > 0) %then %do; 
		Data Indic9_%scan(&org,&i, '/');
			set Indic9;
			Keep orgid location summaryym drug mismatch IM_Count IV_Count digestive_Count respiratory_Count ;
			where mismatch ne '';
			label IM_count='IM' IV_count='IV' digestive_count='Oral' respiratory_count='Respiratory' 
			         orgid='Org ID' summaryym='Month'  location='Location' drug='Drug' drug='Drug' ;
		run;
	%decor4(Drug Route Mismatch);
		proc print data=Indic9_%scan(&org,&i, '/') noobs label;
		/*title "Drugs Route Mismatch";*/
		run;
	%end;
	%else %do;
	 %decor1(Drug Route Mismatch);
	  proc sql;
		 	Create table NF_Indic9_%scan(&org,&i, '/') as 
			select distinct orgid, name from audatavalid
			where year(summaryYM)=&year and qtr(summaryYM)=&quarter and orgid=%scan(&org,&i, '/');
		quit;
	%end;

	 %decor5(%str(This report will flag if antimicrobial days are reported for a route that is not conventionally used for a given drug (e.g. ceftriaxone given via digestive route, amoxicillin/clavulanate given via IV or IM routes).),
                       %str(There may be legitimate reasons why a drug was administered via a nonconventional route.  Review eMAR/BCMA report to identify specific cases to determine if antimicrobial days was appropriately counted and attributed.  If this is not the case, work with the vendor to ensure only IV, IM, digestive, and respiratory routes are being included in the total antimicrobial days count and are being attributed correctly.))
    %decor2;


/* 10-AU Rate for the top 10 abx */

    *Computing Reference statistics (median rate and IQR) for top 20 Abx for the same quarter of the previous year;

proc means data=audatavalid Median Qrange noprint ;
class orgid drugdescription;
where drugdescription in ('CEFTRX - CEFTRIAXONE' 'VANC - VANCOMYCIN' 'PIPERWT - PIPERACILLIN WITH TAZOBACTAM' 'CEFEP - CEFEPIME' 'CEFAZ - CEFAZOLIN'
						  'AZITH - AZITHROMYCIN' 'METRO - METRONIDAZOLE' 'MERO - MEROPENEM' 'DOXY - DOXYCYCLINE' 'LEVO - LEVOFLOXACIN') 
             and orgid=%scan(&org,&i, '/') and (qtr(summaryym)=&quarter and year(summaryym)=&year-1);
var RateDaysPresent;
output out=stats (where=(_type_>2) drop=_freq_)  median=RateDaysPresent_Median qrange=RateDaysPresent_QRange;
run;

    *merging stats to Top 10;

proc sql;
create table Fullstats as
select a.*, (b.RateDaysPresent_Median  - 2*b.RateDaysPresent_QRange) as Lowerbound,
                   (b.RateDaysPresent_Median + 2*b.RateDaysPresent_QRange) as Upperbound
from (select * from audata where drugdescription in ('CEFTRX - CEFTRIAXONE' 'VANC - VANCOMYCIN' 'PIPERWT - PIPERACILLIN WITH TAZOBACTAM' 'CEFEP - CEFEPIME' 'CEFAZ - CEFAZOLIN'
						 							 'AZITH - AZITHROMYCIN' 'METRO - METRONIDAZOLE' 'MERO - MEROPENEM' 'DOXY - DOXYCYCLINE' 'LEVO - LEVOFLOXACIN')) a 
            left join stats b on a.orgid=b.orgid and a.drugdescription=b.drugdescription
          where calculated lowerbound>=0 and calculated Upperbound>0 and a.RateDaysPresent ne .;
quit;


              
                  *Printing output errors;

 proc sql;*Check if there is any historic data;
create table historic_data_indic as
select * from audatavalid
where orgid=%scan(&org,&i, '/') and (qtr(summaryym)=&quarter and year(summaryym)=&year-1);
quit;

	%if %eval(&sqlobs = 0) %then %do; *If historic data available then do the operation underneath;
	%decor3(Drug-Level AU Rate Above Outlier Boundaries);
	%end;
	%else %do;

 proc sql;
create table indic10a as
select * from fullstats
where RateDaysPresent > Upperbound;
quit;

              %if %eval(&sqlobs > 0) %then %do; 
				  Data Indic10A_%scan(&org,&i, '/');
				  	set Indic10a;
					Keep orgid location summaryym drugdescription RateDaysPresent Lowerbound Upperbound;
					where RateDaysPresent > Upperbound;
					format RateDaysPresent Lowerbound Upperbound 5.1;
					label RateDaysPresent="Drug Rate" Lowerbound='Ouliers Lower Bound' Upperbound='Ouliers Upper Bound'
					         orgid='Org ID' summaryym='Month'  location='Location' drugdescription='Drug';
				  run;
			 %decor4(Drug-Level AU Rate Above Outlier Boundaries);
					proc print data=Indic10a_%scan(&org,&i, '/') noobs label;
					/*title "Drug-Level AU Rate Above Outlier Boundaries";*/
					run;
              %end;
	          %else %do;
				 %decor1(Drug-Level AU Rate Above Outlier Boundaries);
	          %end;
	%end;

	%decor5(%str(For historical comparison, we compare this metric to the median AU rate of the same quarter from the previous calendar year.  If the AU rate from this quarter is greater than the median + 2 times the IQR for the previous quarter, this report will flag for FACWIDEIN antimicrobial days for a specific drug.  To ensure that uncommonly used agents don’t make this flag too frequently, this is only analyzed for the top 20 antimicrobials used statewide.  If historical data are not available from the same quarter of the previous calendar year, this report will read “Not Enough Historical Data Available”.),
	                  %str(If a facility has a different patient population, significantly more or fewer days present than the previous year, or if significant changes in antimicrobial days for a specific drug from the previous year are already known, this flag can typically be disregarded.  If this is not the case, check with vendor to ensure surveillance software is accurately pulling and reporting ADT data and check to ensure surveillance software is accurately pulling eMAR/BCMA data and attributing it to the correct location.  If all technical problems are ruled out, consider targeted stewardship interventions to discover rationale and improve antibiotic use, if necessary, as determined by the ASP.))
	%decor2;

 proc sql;*Check if there is any historic data;
create table historic_data_indic as
select * from audatavalid
where orgid=%scan(&org,&i, '/') and (qtr(summaryym)=&quarter and year(summaryym)=&year-1);
quit;

	%if %eval(&sqlobs = 0) %then %do; *If historic data available then do the operation underneath;
	%decor3(Drug-Level AU Rate Below Outlier Boundaries);
	%end;
	%else %do;

proc sql;
create table indic10b as
select * from fullstats
where Lowerbound>RateDaysPresent;
quit;

                %if %eval(&sqlobs > 0) %then %do; 
					Data Indic10b_%scan(&org,&i, '/');
						set Indic10b;
						keep orgid location summaryym drugdescription RateDaysPresent Lowerbound Upperbound;
						where Lowerbound>RateDaysPresent;
						format RateDaysPresent Lowerbound Upperbound 5.1;
						label RateDaysPresent="Drug Rate" Lowerbound='Ouliers Lower Bound' Upperbound='Ouliers Upper Bound'
						         orgid='Org ID' summaryym='Month'  location='Location' drugdescription='Drug';
					run;
				%decor4(Drug-Level AU Rate Below Outlier Boundaries);
				proc print data=Indic10b_%scan(&org,&i, '/') noobs label;
				/*title "Drug-Level AU Rate Below Outlier Boundaries";*/
				run;
               %end;
	           %else %do;
				 %decor1(Drug-Level AU Rate Below Outlier Boundaries);
	           %end;
	%end;

    %decor5(%str(For historical comparison, we compare this metric to the median AU rate of the same quarter from the previous calendar year.  If the AU rate from this quarter is less than the median – 2 times the IQR for the previous quarter, this report will flag for FACWIDEIN antimicrobial days for a specific drug.  To ensure that uncommonly used agents don’t make this flag too frequently, this is only analyzed for the top 20 antimicrobials used statewide.  If historical data are not available from the same quarter of the previous calendar year, this report will read “Not Enough Historical Data Available”.),
                       %str(If a facility has a different patient population, significantly more or fewer days present than the previous year, or if significant changes in antimicrobial days for a specific drug from the previous year are already known, this flag can typically be disregarded.  If this is not the case, check with vendor to ensure surveillance software is accurately pulling and reporting ADT data and check to ensure surveillance software is accurately pulling eMAR/BCMA data and attributing it to the correct location.  If all technical problems are ruled out, consider targeted stewardship interventions to discover rationale and improve antibiotic use, if necessary, as determined by the ASP.))
	%decor2;
************************************************** LOCATION LEVEL *************************************************************;

/* 11-Sum of DP for specific locations < FacwideIn DP */


proc sql;
create table fac_DP as
select orgid, summaryym, case 
                                              when locCDC='  ' then 'FACWIDEIN'
											  when  locCDC in ('OUT:ACUTE:ED' 'OUT:ACUTE:ED:PED') then 'ED'
											  else 'OTHER LOC' end as Location2, sum (numDaysPresent) as DP
from (select distinct orgid, locCDC, summaryym, numDaysPresent from audata)
group by 1, 2, 3;
quit;


proc sort data=fac_dp out=sorted;
by  orgid summaryYM;
run;

proc transpose data=sorted out=transposed;
var dp;
id location2;
by orgid summaryYM;
run;


		           *Printing Output Errors;

proc sql;
create table indic11 as
select * from transposed
where FACWIDEIN > OTHER_LOC and  OTHER_LOC  ne .;
quit;

	%if %eval(&sqlobs > 0) %then %do; 
		Data Indic11_%scan(&org,&i, '/');
			set indic11;
			Keep orgid summaryYM FACWIDEIN OTHER_LOC;
			label OTHER_LOC='Total DP for all Inpatient Locations '
		          FACWIDEIN='FacWideIn DP'
		         orgid='Org ID' summaryym='Month';
			*title "Days Present for All Specific Locations LESS THAN Fac-wide Days Present";
		run; 
	%decor4(Days Present for All Specific Locations LESS THAN Facility-wide Days Present);
	proc print data=Indic11_%scan(&org,&i, '/')  noobs label;
	*title "Days Present for All Specific Locations LESS THAN Fac-wide Days Present ";
	run;
	%end;
	%else %do;
		%decor1(Days Present for All Specific Locations LESS THAN Facility-wide Days Present);
	%end;

	 %decor5(%str(Due to admissions, discharges and transfers within the system, the FACWIDEIN days present count should always be less than the sum of the location-specific days present count.),
                       %str(Review NHSN mapping to ensure that non-inpatient units (e.g. ED, 24-hr observation units) are not being included in your FACWIDEIN AU Option data.  Review NHSN mapping to ensure that a reportable inpatient unit is not being missed in your FACWIDEIN AU Option data.  If either is the case, work with your NHSN Facility Administrator and/or vendor to correct.))
	 %decor2;

 /* 12-DOT for specific locations < DOT for FACWIDEIN for each month */

proc sql;
create table fac_DOT as
select orgid, summaryym,  case 
                                                  when locCDC='  ' then 'FACWIDEIN'
											       when  locCDC in ('OUT:ACUTE:ED' 'OUT:ACUTE:ED:PED') then 'ED'
											       else 'OTHER LOC' end as Location2, sum (antimicrobialDays) as DOT
from  audata
group by 1, 2, 3;
quit;



proc sort data=fac_dot out=sorted_dot;
by  orgid summaryYM ;
run;

proc transpose data=sorted_dot out=transposed_dot;
var dot;
id location2;
by orgid summaryYM ;
run;

         *Deleting noisy rows;
data transposed_dot;
set transposed_dot;
if (FACWIDEIN=.  and  OTHER_LOC=0) or (FACWIDEIN=0 and  OTHER_LOC=.) or (FACWIDEIN=0 and  OTHER_LOC=0)
   or (FACWIDEIN=.  and  OTHER_LOC=.) or (OTHER_LOC=.  and FACWIDEIN not in (., 0))then delete;
run;

          *Output Errors;
proc sql;
create table indic12 as
select * from transposed_dot
where  FACWIDEIN >  OTHER_LOC ;
quit;

	%if %eval(&sqlobs > 0) %then %do; 
		Data Indic12_%scan(&org,&i, '/');
			set indic12;
			keep orgid summaryYM FACWIDEIN OTHER_LOC;
			label OTHER_LOC='Total DOT for all Inpatient Locations'
	          FACWIDEIN='FacWideIn DOT'  
	         orgid='Org ID' summaryym='Month';
		run;
	%decor4(Days of Therapy for All Specific Locations LESS THAN Facility-wide Days of Therapy);
	proc print data=Indic12_%scan(&org,&i, '/') label noobs;
	*title "Days of Therapy for All Specific Locations LESS THAN Fac-wide Days of Therapy";
	run;
	%end;
	%else %do;
		%decor1(Days of Therapy for All Specific Locations LESS THAN Facility-wide Days of Therapy);
	%end;
     %decor5(%str(Because antimicrobials administered multiple times per day may contribute 1 day of therapy to multiple units on a given day, the sum of days of therapy for all specific locations should be greater than the FACWIDEIN days of therapy.),
                       %str(Review NHSN mapping to ensure that non-inpatient units (e.g. ED, 24-hr observation units) are not being included in your FACWIDEIN AU Option data.  Review NHSN mapping to ensure that a reportable inpatient unit is not being missed in your FACWIDEIN AU Option data.  If either is the case, work with your NHSN Facility Administrator and/or vendor to correct.))
	 %decor2;

/* 13-Large change of DP in each Facility's  Locations*/
  
         *Selecting unique rows of DP  for each facility, location and month;
proc sort data=audatavalid nodupkey out=sorted_faclocdp_historic;
by orgid  location summaryym numDaysPresent;
where orgid=%scan(&org,&i, '/') and qtr(summaryym)=&quarter and year(summaryym)=&year-1;
run;

proc sort data=audata nodupkey out=sorted_faclocdp;
by orgid  location summaryym numDaysPresent;
run;

        *Computing Median DP and IQR for each facility and location;

proc means data=sorted_faclocdp_historic median qrange noprint;
var numDaysPresent;
class orgid  location;
output out=stats_faclocdp (where=(_type_>2) drop=_freq_) median=numDaysPresent_Median qrange=numDaysPresent_QRange;
run;

         *Joining the stats with the unique rows table  & calculting Outlyers boundaries   ;
proc sql;
create table faclocdp as
select a.*, (b.numDaysPresent_Median + 2* b.numDaysPresent_QRange) as Upperbound,
                   (b.numDaysPresent_Median - 2* b.numDaysPresent_QRange) as Lowerbound
from sorted_faclocdp a left join stats_faclocdp b
       on a.orgid=b.orgid and a.location=b.location;
quit;


          *Printing Output errors;

 proc sql;*Check if there is any historic data;
create table historic_data_indic as
select * from audatavalid
where orgid=%scan(&org,&i, '/') and (qtr(summaryym)=&quarter and year(summaryym)=&year-1);
quit;

	%if %eval(&sqlobs = 0) %then %do; *If historic data not available then do the operation underneath;
	%decor3(Location-Level Days Present GREATER than Outlying Upper Boundary);
	%end;
	%else %do;

proc sql;
create table indic13a as
select * from faclocdp
where numDaysPresent > Upperbound and Upperbound not in (0,.) ;
quit;

			%if %eval(&sqlobs > 0) %then %do; 
				Data Indic13a_%scan(&org,&i, '/');
				   	set indic13a;
					keep orgid location summaryym numDaysPresent Upperbound;
					label orgid='Org ID' summaryym='Month' location='Location' numDaysPresent='Days Present' Upperbound='Outliers Upper Bound';
				run;
			%decor4(Location-Level Days Present GREATER than Outlying Upper Boundary);
			proc print data=Indic13a_%scan(&org,&i, '/') noobs label;
			*title "Location-Level Days Present GREATER THAN Outlying Upper Boundary";
			run;
            %end;
			%else %do;
			 %decor1(Location-Level Days Present GREATER than Outlying Upper Boundary);
	        %end;
	%end;
    %decor5(%str(For historical comparison, we compare this metric to the median days present of the same quarter from the previous calendar year.  If the days present from this quarter is greater than the median + 2 times the IQR for the previous quarter, this report will flag for an individual location. If historical data are not available from the same quarter of the previous calendar year, this report will read “Not Enough Historical Data Available”.),
	                  %str(This warrants a determination if significant changes have occurred in NHSN unit mapping.  If a unit has a different patient population or significantly more or fewer days present than the previous year, this flag can typically be disregarded.  If this is not the case, check with vendor to ensure surveillance software is accurately pulling and reporting ADT data.))
	 %decor2;

proc sql;*Check if there is any historic data;
create table historic_data_indic as
select * from audatavalid
where orgid=%scan(&org,&i, '/') and (qtr(summaryym)=&quarter and year(summaryym)=&year-1);
quit;

	%if %eval(&sqlobs = 0) %then %do; *If historic data not available then do the operation underneath;
	%decor3(Location-Level Days Present LESS than Outlying Lower Boundary);
	%end;
	%else %do;

 proc sql;
create table indic13b as
select * from faclocdp
where numDaysPresent < Lowerbound and Lowerbound >0;
quit;

			%if %eval(&sqlobs > 0) %then %do; 
				Data indic13b_%scan(&org,&i, '/');
					set indic13b;
					Keep orgid location summaryym numDaysPresent Lowerbound ;
					label orgid='Org ID' summaryym='Month' location='Location' numDaysPresent='Days Present' lowerbound='Outliers Lower Bound';
				run;
			%decor4(Location-Level Days Present LESS than Outlying Lower Boundary);
			proc print data=Indic13b_%scan(&org,&i, '/') noobs label;
			*title "Location-Level Days Present LESS THAN Outlying Lower Boundary";
			run;
            %end;
	        %else %do;
			 %decor1(Location-Level Days Present LESS than  Outlying Lower Boundary);
	           %end;
	%end;
    
    %decor5(%str(For historical comparison, we compare this metric to the median days present of the same quarter from the previous calendar year.  If the days present from this quarter is less than the median – 2 times the IQR for the previous quarter, this report will flag for an individual location. If historical data are not available from the same quarter of the previous calendar year, this report will read “Not Enough Historical Data Available”.),
                      %str(This warrants a determination if significant changes have occurred in NHSN unit mapping.  If a unit has a different patient population or significantly more or fewer days present than the previous year, this flag can typically be disregarded.  If this is not the case, check with vendor to ensure surveillance software is accurately pulling and reporting ADT data.))
    %decor2;
/* 14-Large change of AU Rate in each Facility's  Locations*/


     *Creating rates table for each facility, location and month;
proc  sql;
create table aurate_historic as 
select a.orgid , a.location , a.summaryym, (sum(a.DOT)*1000/sum(numDaysPresent)) as rate format=5.
from (select orgid , location , summaryym, sum (antimicrobialDays) as DOT  from audatavalid c where orgid=%scan(&org,&i, '/') and qtr(summaryym)=&quarter and year(summaryym)=&year-1 group by 1,2,3 ) a inner join
          (select distinct orgid , location , summaryym, numDaysPresent from audatavalid d where orgid=%scan(&org,&i, '/') and qtr(summaryym)=&quarter and year(summaryym)=&year-1) b 
      on   a.orgid=b.orgid and a.location =b.location  and a.summaryym=b.summaryym
group by 1, 2,3;
quit;

proc  sql;
create table aurate as 
select a.orgid , a.location , a.summaryym, (sum(a.DOT)*1000/sum(numDaysPresent)) as rate format=5.
from (select orgid , location, summaryym, sum (antimicrobialDays) as DOT  from audata c group by 1,2,3 ) a inner join
          (select distinct orgid , location , summaryym, numDaysPresent from audata d) b 
      on   a.orgid=b.orgid and a.location=b.location and a.summaryym=b.summaryym
group by 1, 2,3;
quit;


      *Calculating summary stats;


proc means data=aurate_historic median qrange noprint;
var rate;
class orgid location;
output out=stats_aurate (where=(_type_>2) drop=_freq_)  median=rate_Median qrange=rate_QRange;
run;


     *Combining tables;

proc sql;
create table rate_combined as
select a.*, b.rate_Median, b.rate_QRange, (b.rate_Median + 1.5* b.rate_QRange) as Upperbound,
                   (b.rate_Median - 1.5* b.rate_QRange) as Lowerbound
from aurate a left join stats_aurate b
       on a.orgid=b.orgid and a.location=b.location;
quit;

data rate_combined;
set rate_combined;
if (Lowerbound=0 and Upperbound=0) then delete;
run;

     *Printing Output errors;

 proc sql;*Check if there is any historic data;
create table historic_data_indic as
select * from audatavalid
where orgid=%scan(&org,&i, '/') and (qtr(summaryym)=&quarter and year(summaryym)=&year-1);
quit;

	%if %eval(&sqlobs = 0) %then %do; *If historic data not available then do the operation underneath;

	%decor3(Location-level AU Rate GREATER than Outlying Upper Boundary);

	%end;
	%else %do;

proc sql;
create table indic14a as
select * from rate_combined
where rate > Upperbound and Upperbound not in (0,.);
quit;

		%if %eval(&sqlobs > 0) %then %do; 
			Data Indic14a_%scan(&org,&i, '/');
				set indic14a;
				keep orgid location summaryym rate  Upperbound;
				format rate  Upperbound 5.1;
				label rate='AU Rate'  orgid='Org ID' summaryym='Month' location='Location' Upperbound='Outliers Upper Bound';
			run;
			%decor4(Location-level AU Rate GREATER than Outlying Upper Boundary);
			proc print data=Indic14a_%scan(&org,&i, '/') noobs label;
			*title "Location-level AU Rate GREATER THAN Outlying Upper Boundary";
			run;
		%end;
	    %else %do;
		%decor1(Location-level AU Rate GREATER than Outlying Upper Boundary);
	    %end;
	%end;
   
     %decor5(%str(For historical comparison, we compare this metric to the median AU rate of the same quarter from the previous calendar year.  If the AU rate from this quarter is greater than the median + 2 times the IQR for the previous quarter, this report will flag for an individual location. If historical data are not available from the same quarter of the previous calendar year, this report will read “Not Enough Historical Data Available”.),
                       %str(This warrants a determination if significant changes have occurred in NHSN unit mapping.  If a unit has a different patient population, significantly more or fewer days present than the previous year, or if significant changes in antimicrobial days for a specific drug from the previous year are already known, this flag can typically be disregarded.  If this is not the case, check with vendor to ensure surveillance software is accurately pulling and reporting ADT data and check to ensure surveillance software is accurately pulling eMAR/BCMA data and attributing it to the correct location.  If all technical problems are ruled out, consider targeted stewardship interventions to discover rationale and improve antibiotic use for the unit, if necessary, as determined by the ASP.))
	 %decor2;

 proc sql;*Check if there is any historic data;
create table historic_data_indic as
select * from audatavalid
where orgid=%scan(&org,&i, '/') and (qtr(summaryym)=&quarter and year(summaryym)=&year-1);
quit;

	%if %eval(&sqlobs = 0) %then %do; *If historic data not available then do the operation underneath;
	%decor3(Location-level AU Rate LESS than Outlying Lower Boundary);
	%end;
	%else %do;

proc sql;
create table indic14b as
select * from rate_combined
where rate < Lowerbound and rate not in (., 0) and Lowerbound >0;
quit;

		%if %eval(&sqlobs > 0) %then %do;
			Data Indic14b_%scan(&org,&i, '/');
				set indic14b;
				keep orgid location summaryym rate  Lowerbound;
				format rate  Upperbound 5.1;
				label rate='AU Rate'  orgid='Org ID' summaryym='Month' location='Location' Lowerbound='Outliers Lower Bound';
			run;
		%decor4(Location-level AU Rate LESS than Outlying Lower Boundary);
			proc print data=Indic14b_%scan(&org,&i, '/') noobs label;
			*title "Location-level AU Rate LESS THAN Outlying Lower Boundary";
			run;
        %end;
	    %else %do;
		 %decor1(Location-level AU Rate LESS than  Outlying Upper Boundary);
	    %end;
	%end;
     %decor5(%str(For historical comparison, we compare this metric to the median AU rate of the same quarter from the previous calendar year.  If the AU rate from this quarter is less than the median – 2 times the IQR for the previous quarter, this report will flag for an individual location.  If historical data are not available from the same quarter of the previous calendar year, this report will read “Not Enough Historical Data Available”.),
                        %str(This warrants a determination if significant changes have occurred in NHSN unit mapping.  If a unit has a different patient population, significantly more or fewer days present than the previous year, or if significant changes in antimicrobial days for a specific drug from the previous year are already known, this flag can typically be disregarded.  If this is not the case, check with vendor to ensure surveillance software is accurately pulling and reporting ADT data and check to ensure surveillance software is accurately pulling eMAR/BCMA data and attributing it to the correct location.  If all technical problems are ruled out, consider targeted stewardship interventions to discover rationale and improve antibiotic use for the unit, if necessary, as determined by the ASP.))
	 %decor2;

%end;%*This ends the very first  macro if statement @ line #371;
%else %do;
	
	ods region;
	%decor6;
/*	ods pdf text=" ^S={font_style=Italic  font_size=10pt just=center font_face='Open Sans' }No data submitted for the current quarter";*/
	 proc sql;
		 	Create table ND_%scan(&org,&i, '/') as 
			select org_id, Name from Facs_Clean
			where org_id=%scan(&org,&i, '/');
		quit;
%end;
ODS LAYOUT END;
ods pdf close;

*Clear Log Window ;
/*DM "log; clear; ";*/

%end; * end for do;

 %mend;

 %validation


/* Printing Flag Report 1 to 9 */


 %macro merge;

ods Excel file = "&path/flag.xlsx" options (EMBEDDED_TITLES="yes");
	%let title1 = 'Antimicrobial Days Reported for any Drug when Days Present Reported as Zero';
	%let title2 = 'Reported Antimicrobial Days for a Single Drug Greater Than Days Present';
	%let title5 = 'Sum of Routes Less than Reported Total Days of Therapy';
	%let title6 = 'Ceftriaxone IM not Used in ED';
	%let title7 = 'Cefazolin not Used in OR';
	%let title8 = 'Sum of Routes Greater than Reported Total Days of Therapy for Drugs given Once Daily';
	%let title9 = 'Drug Route Mismatch';

	
%do i= 1 %to 9;
	
	%if &i NE 3 AND &i NE 4 %then %do;
	
	Data Merge&i;
		merge indic&i._: ;
		by orgid;
	run;

	proc sql noprint;
	select nobs into: obs
	from  dictionary.tables where memname="MERGE&i";
	quit;

	
	    %if %eval(&obs > 0) %then %do;
		ods excel options (EMBEDDED_TITLES="yes" sheet_interval="proc" sheet_name="&&Title&i");
		Title &&Title&i;
		proc print data=merge&i noobs label;
			
		run;

	/*	Data NF_Merge&i;*/
	/*		merge NF_indic&i._: ;*/
	/*		by orgid;*/
	/*	run;*/
	/*	ods excel options (EMBEDDED_TITLES="yes" sheet_interval="NONE");*/
	/*	proc print data=NF_merge&i noobs label;*/
	/*	Title 'No Flags Identified';*/
	/*	run;*/

		%end;
		%else %do;
		ods excel options (EMBEDDED_TITLES="yes" sheet_interval="PROC" sheet_name="&&Title&i");
	/*	Data NF_Merge&i;*/
	/*		merge NF_indic&i._: ;*/
	/*		by orgid;*/
	/*	run;*/
		data _null_;
			title &&Title&i;
			file print;
			put _page_;
			put "No Flags Identified";
		run;


	/*	proc print data=NF_merge&i label obs=0;*/
	/*		title &&Title&i;*/
	/*		Title2 'No Flags Identified';*/
	/*	run;*/
		%end;

	%end;
%end;
	
/*	No data for Current quarter*/
	Data ND_merge;
		merge ND_: ;
		by org_id;
	run;

	ods excel options (EMBEDDED_TITLES="yes" sheet_interval="proc" sheet_name="No Data");
	Proc print data=ND_Merge Noobs label;
		Title 'No data submitted for the current quarter';
	run;
	

ods excel close;

%mend;

%Merge;

/*Clear Log Window ;*/
DM "log; clear; ";








