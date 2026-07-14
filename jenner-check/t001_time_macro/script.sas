/* Adapted from Data Validation-DP.sas: the %time macro that derives the
   reporting quarter/year, plus a small caller that confirms the derived
   quarter is a valid 1-4 value. The macro body is verbatim from the repo. */

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

%put NOTE: Derived reporting period Q&quarter of &year;
title "AU Validation reporting period: Q&quarter-&year";

/* Small caller: confirm the derived quarter is a valid 1-4 value */
data check;
  quarter = &quarter;
  year = &year;
  if quarter in (1,2,3,4) then valid = 'YES';
  else valid = 'NO ';
run;

proc print data=check noobs;
run;
