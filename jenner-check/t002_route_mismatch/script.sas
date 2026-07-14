/* Adapted from Data Validation-DP.sas: the DOT-recalculation DATA step and the
   route-mismatch classification (verbatim classification logic from the repo),
   run against a small mock of the NHSN AU download (summaryau_e). The external
   LIBNAME AU "H:\NHSN\..." is replaced by an inline mock with the same columns. */

/* Mock summaryau_e standing in for the external NHSN AU download
   (LIBNAME AU "H:\NHSN\..."). Columns match what the repo's DATA step reads. */
data summaryau_e;
  infile datalines dsd dlm='|' truncover;
  length drugDescription $ 45;
  input orgid IM_Count IV_Count digestive_Count respiratory_Count antimicrobialdays drugDescription $;
  datalines;
10017|0|0|12|0|12|AMOX - AMOXICILLIN
10017|3|0|0|0|3|AMOX - AMOXICILLIN
10017|0|8|0|0|8|MERO - MEROPENEM
10017|2|0|0|0|2|MERO - MEROPENEM
10100|0|0|5|0|5|AZITH - AZITHROMYCIN
10100|4|0|0|0|4|AZITH - AZITHROMYCIN
10100|0|6|0|0|6|CEFAZ - CEFAZOLIN
44440|0|0|9|0|9|AMOX - AMOXICILLIN
;
run;

*Create DOT by adding sum of different routes;
data audatavalid1;
set summaryau_e ;
total_count=sum(IM_Count, IV_Count, digestive_Count, respiratory_Count);
diff=total_count-antimicrobialdays;
label total_count='Recalculated Days of Therapy' diff='Difference of  DOT';
if orgid = 44440 then delete;
run;

     *Deleting possible duplicates;

proc sort data=audatavalid1 nodup;
by orgid;
run;

*Route Mismatch (verbatim classification logic from the repo);

data audatavalid;
set audatavalid1;
length mismatch $ 50;
mismatch=' ';
*PO only;
	if drugDescription in ('AMAN - AMANTADINE' 'AMOX - AMOXICILLIN'  'AMOXWC - AMOXICILLIN WITH CLAVULANATE'
							'NITRO - NITROFURANTOIN' 'PENV - PENICILLIN V')
						and (IM_Count >0 or  IV_Count>0 or respiratory_Count>0)
	then mismatch='Should be PO only';
*IV only;
	if drugDescription in ('MERO - MEROPENEM' 'DAPTO - DAPTOMYCIN' 'CEFTAR - CEFTAROLINE')
				and (IM_Count >0 or  digestive_Count>0 or respiratory_Count>0)
	then mismatch='Should be IV only';
*IM and IV only;
	if drugDescription in ('CEFAZ - CEFAZOLIN' 'CEFEP - CEFEPIME' 'CEFTRX - CEFTRIAXONE')
					and (digestive_Count>0 or respiratory_Count>0)
	then mismatch='Should be IM and IV only';
*IV+PO;
	if drugDescription in ('AZITH - AZITHROMYCIN' 'DOXY - DOXYCYCLINE' 'LEVO - LEVOFLOXACIN')
					and (IM_Count>0 or respiratory_Count>0)
	then mismatch='Should be PO and IV only';
label mismatch='Mismatch Type';
run;

*Route Mismatch report (indic9 logic);
proc sql;
create table indic9 as
select orgid, drugDescription, IM_Count, IV_Count, digestive_Count, respiratory_Count, mismatch
from audatavalid
where mismatch ne '';
quit;

title 'Drug Route Mismatch';
proc print data=indic9 noobs label;
label IM_count='IM' IV_count='IV' digestive_count='Oral' respiratory_count='Respiratory'
      orgid='Org ID' drugDescription='Drug' mismatch='Mismatch Type';
run;
