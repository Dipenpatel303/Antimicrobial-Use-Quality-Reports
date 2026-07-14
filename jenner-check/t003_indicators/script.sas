/* Adapted from Data Validation-DP.sas: the days-present validation indicator
   (indic1) and the pooled days-of-therapy aggregation, run against a small mock
   of the NHSN AU data. The external LIBNAME AU is replaced by an inline mock
   with the same columns the repo's indicator queries read. */

/* Mock AU data standing in for the external NHSN AU download. Columns match
   what the repo's indicator queries read: antimicrobialDays vs numDaysPresent. */
data audata;
  infile datalines dsd dlm='|' truncover;
  length location $ 12 drugDescription $ 45;
  input orgid location $ drugDescription $ antimicrobialDays numDaysPresent;
  datalines;
10017|FACWIDEIN|CEFTRX - CEFTRIAXONE|20|450
10017|ICU|CEFTRX - CEFTRIAXONE|15|0
10017|ICU|VANC - VANCOMYCIN|60|40
10017|WARD|MERO - MEROPENEM|10|300
10100|FACWIDEIN|AZITH - AZITHROMYCIN|8|0
10100|ICU|CEFAZ - CEFAZOLIN|25|25
10100|WARD|LEVO - LEVOFLOXACIN|90|75
;
run;

*Indicator 1 - Antimicrobial days reported for any drug when days present are reported as zero;
proc sql;
create table indic1 as
select orgid, location, drugDescription, antimicrobialDays, numDaysPresent
from audata
where antimicrobialDays>0 and numDaysPresent=0;
quit;

title 'Antimicrobial Days Reported for any Drug when Days Present Reported as Zero';
proc print data=indic1 noobs label;
label orgid='Org ID' location='Location' drugDescription='Drug'
      antimicrobialDays='Antimicrobial Days' numDaysPresent='Days Present';
run;

*Pooled DOT per facility (audata2 aggregation pattern from the repo);
proc sql;
create table dot as
select orgid, sum(antimicrobialDays) as pooledDOT
from audata
group by orgid;
quit;

title 'Pooled Days of Therapy by Facility';
proc print data=dot noobs label;
label orgid='Org ID' pooledDOT='Pooled Days of Therapy';
run;
