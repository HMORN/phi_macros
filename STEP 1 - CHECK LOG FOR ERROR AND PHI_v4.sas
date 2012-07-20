/*--------------------------------------------------------------------*/
/*----------   S P E C I F I C A T I O N   D O C U M E N T  ----------*/
/*--------------------------------------------------------------------*/
/* PROJECT              :  VALIDATION                                 */
/* PROGRAM NAME         :  check_log                                  */
/* PROGRAMMER			:  Nargis Anwar
/**********************************************************************/
/* MACRO: check_log                                                   */
/*  PURPOSE:  Read in a log and capture ERROR and WARNING messages    */
/*            and data set obs information.  This info is put in a    */
/*            spreadsheet and emailed to the address(es) listed in    */
/*            the parameter SENDTO or save a file in the folder.                                   */
/*                                                                    */
/*  REQUIREMENTS:                                                     */
/*      CALLING PROGRAM MUST HAVE THE FOLLOWING OPTION:               */
/*      EMAILSYS='/opt/sas/utilities/bin/sasm.elm.mime'               */
/*                                                                    */
/*  PARAMETERS:                                                       */
/*      LOGPATH : the path to the folder containing the log file      */
/*         EXAMPLE: LOGPATH =/proj/sas/hsar2/user/eamoses/prog        */
/*                                                                    */
/*      LOGFILE:  the name of the log file without the .log extension */
/*         EXAMPLE: LOGFILE = mysasjob                                */
/*                                                                    */
/*      SENDTO:   email address to send message speadsheet            */
/*        EXAMPLE1: ONLY ONE RECIPIANT                                */
/*                  sendto = "NARGIS.X.ANWAR@HEALTHPARTNERS.COM"      */
/*        EXAMPLE2: MULTIPLE RECIPIANTS                               */
/*                  sendto = "NARGIS.X.ANWAR@HEALTHPARTNERS.COM"      */
/*                            "AMY.L.BUTANI@HEALTHPARTNERS.COM"      */
/*                                                                    */
/*      DB_OBS_INFO: SET TO Y IF YOU WANT THE Data set OBS INFO COLLECTED   */
/*         IF THE INFO IS NOT NEEDED, THEN DO NOT CODE THIS PARAMETER */
/*         EXAMPLE: DB_OBS_INFO = Y                                   */
/*      															  */
/*		OPTION: To specify if message should be sent to e-mail or
                save a file in the folder.
 			    EXAMPLE: OPTION=1 is for email. OPTION=2 for no email */
/*--------------------------------------------------------------------*/
  /********************************************/
  /* ADD THE DATE TO THE LIST AND LOG         */
  /********************************************/
data _null_;
 call symput('run_dt',put(today(),yymmddn8.));
run;

PROC PRINTTO LOG   ="&path.detect_phi_error.log" new;
PROC PRINTTO PRINT ="&path.detect_phi_error.lst" new;
run;


%**LET JOBNAME = %SCAN(&SYSPROCESSNAME,2);
%let jobname = fred ;
%put &sysprocessname ;
%put &jobname ;


  /********************************************/
  /* ADD THE DATE TO THE LIST AND LOG         */
  /********************************************/
%MACRO check_log(logpath=, logfile= , jobname= , SENDTO =, DB_OBS_INFO=, Option=);

%LET ERRORS = INDEX(line,'ERROR') > 0 or
     INDEX(line,'REPEATS OF BY VALUES') > 0 or
     INDEX(LINE,'WARNING') > 0 or
     INDEX(line,'IS UNINITIALIZED') > 0 or
     INDEX(line,'INVALID') > 0 or
     INDEX(line,'W.D FORMAT') > 0 or
     INDEX(line,'INVALID') > 0 or
     INDEX(line,'MATHEMATICAL OPERATIONS COULD NOT') > 0 or
     INDEX(LINE,'USER ERROR') > 0  or
     INDEX(LINE,'USER WARNING') > 0  or
     INDEX(LINE,'OUTSIDE THE AXIS RANGE') > 0 or
     INDEX(line,'BIRTH_DATE') > 0 OR
	 INDEX(line,'BDATE') > 0 OR
	 INDEX(line,'DOB') > 0 OR
	 INDEX(line,'BIRTH DATE') > 0 OR
     INDEX(line,'SSN') > 0 or
	 INDEX(line,'SOCIAL SECURITY') > 0 or
	 INDEX(line,'SOCIALSECURITYNUMBER') > 0 or
	 INDEX(line,'SOCSEC') > 0 or
	 INDEX(line,'SOCIAL_SECURITY_NUMBER') > 0 or
	 prxmatch(compress("/(&locally_forbidden_varnames)/i"), line) > 0
	 ;

  /************************/
  /* READ IN THE LOG FILE */
  /************************/
DATA saslog;
  INFILE "&logpath/&logfile..log" TRUNCOVER;
  INPUT @01 myline $char200.;
  length line $200
         message $200
         srt $25;

   LINE = UPCASE(myLINE);

  /***********************************/
  /* KEEP ERROR AND WARNING MESSAGES */
  /***********************************/
%IF &DB_OBS_INFO = Y %THEN %DO;
  if &ERRORS or
     INDEX(line,'OBSERVATIONS AND') > 0;
  if index(line,'UNABLE TO COPY SASUSER') > 0 then delete;

%END;
%ELSE %DO;
   IF &ERRORS;
  if index(line,'UNABLE TO COPY SASUSER') > 0 then delete;

%END;

      /* ERRORS   */
   if INDEX(LINE,'ERROR:') > 0  or
      INDEX(LINE,'ERROR:') > 0 then do;
      srt = '1. ERROR';
      MESSAGE = myline;
      LOGROW = _N_;
      OUTPUT;
    END;

      /* merge problem */
   ELSE if INDEX(line,'REPEATS OF BY VALUES') > 0 then do;
     srt = '2. MERGE PROBLEM';
     MESSAGE = myline;
     LOGROW = _N_;
     OUTPUT;
   END;

     /* unresolved macro */
   ELSE IF INDEX(LINE,'WARNING: Apparent symbolic') > 0 THEN DO;
     srt = '3. UNRESOLVED MACRO VARIABLE';
     MESSAGE = myline;
     LOGROW = _N_;
     OUTPUT;
   END;

    /* uninitialized */
   ELSE IF INDEX(line,'IS UNINITIALIZED') > 0 or
           INDEX(line,'MISSING VALUES') > 0  THEN DO;
     srt = '4. MISSING DATA PROBLEM';
     MESSAGE = myline;
     LOGROW = _N_;
     OUTPUT;
   END;

    /*Warning */
   ELSE IF INDEX(line, 'WARNING') > 0  OR
           INDEX(line, 'WARNING:') > 0 THEN DO;
     srt = '5. OTHER WARNINGS';
     MESSAGE = myline;
     LOGROW = _N_;
     OUTPUT;
   END;

    /* PHI warnings */
   ELSE IF  INDEX (line, 'BIRTH_DATE') > 0 OR
			INDEX (line, 'BDATE') > 0 OR
			INDEX (line, 'DOB') > 0 OR
			INDEX (line, 'BIRTH_DATE') > 0 OR
            INDEX(line,  'SSN') > 0 or
		    INDEX(line,  'SOCIAL SECURITY') > 0 or
			INDEX(line,  'SOCIALSECURITYNUMBER') > 0 or
			INDEX(line,  'SOCSEC') > 0 or
		    INDEX(line,  'SOCIAL_SECURITY_NUMBER') > 0 or
		    prxmatch(compress("/(&locally_forbidden_varnames)/i"), line) > 0  THEN DO;
     srt = '11. PHI WARNINGS';
     MESSAGE = myline;
     LOGROW = _N_;
     OUTPUT;
   END;

   ELSE IF INDEX(line,'OBSERVATIONS AND') > 0 THEN DO;
     SRT = '9. DATA SET OBS INFO';
     MESSAGE = myline;
     LOGROW = _N_;
     OUTPUT;
   END;

   ELSE IF INDEX(line,'W.D FORMAT') > 0 THEN DO;
     SRT = '6. DATA FORMAT PROBLEM';
     MESSAGE = myline;
     LOGROW = _N_;
     OUTPUT;
   END;


    /* EVERYTHING ELSE */
   ELSE DO;
     srt = '7. Other ISSUES';
     MESSAGE = myline;
     LOGROW = _N_;
     OUTPUT;
   END;
RUN;

data _null_;
   dsid=open('saslog');
   nobs =  attrn(dsid,'nobs');
   if nobs > 0 then call symputx('send_excel','Y');
   else call symputx('send_excel','N');
run;

/******************************************************/
/* sending results to email or in a focument          */
/******************************************************/

%if (&option= 1 and &send_excel = Y) %then %do;
PROC SORT DATA=saslog;
  BY srt LOGROW;
RUN;

ODS LISTING CLOSE;
 ods tagsets.excelxp
 file="&logpath/&jobname._&run_dt._messages.xls"
      style=RTF
  options(sheet_name="MESSAGES FROM &JOBNAME"
          FROZEN_ROWHEADERS = 'yes') ;



PROC PRINT DATA=saslog noobs;
  var srt LOGROW MESSAGE;
RUN;

ods tagsets.excelxp close;

filename mymail email to  = (&sendto)
  attach="&logpath/&jobname._&run_dt._messages.xls"
  subject="SAS MESSAGES FOR &JOBNAME &RUN_DT ";
  data _null_;
       file mymail;
       Put  "Hello,";
       Put  "CHECK THE MESSAGES FROM THE LOG FOR";
       Put  "Job &jobname.";
       Put  " ";
	   put  "Thank You";
       run;

%end;
%else %if (&option= 1 and &send_excel = N) %then %do;
filename mymail email to  = (&sendto)
  subject="No error messages found in job: &logfile &sysdate";
  data _null_;
       file mymail;
       Put  "Hello,";
       Put  "No error messages or warnings were found in the log for";
       Put  "Job &logfile.";
       Put  " ";
	   Put  "Thank You";
       run;
%end;
ods rtf close;

%if (&option= 2 and &send_excel = Y) %then %do;
PROC SORT DATA=saslog;
  BY srt LOGROW;
RUN;

ods rtf file="&logpath/&jobname._&run_dt._messages.rtf" ;
PROC PRINT DATA=saslog noobs;
title1 "SAS MESSAGES FOR &JOBNAME &RUN_DT ";
  var srt LOGROW MESSAGE;
RUN;
title1;
%end;
ods rtf close;
%end;


PROC DATASETS LIBRARY=work NOLIST;
  DELETE saslog;
QUIT;


%MEND check_log;


