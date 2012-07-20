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

  /********************************************/
  /* ADD THE DATE TO THE LIST AND LOG         */
  /********************************************/
**%MACRO check_log(logpath=, logfile= , jobname= , SENDTO =, DB_OBS_INFO=, Option=);

%MACRO check_log(logpath=, DB_OBS_INFO=);

%LET ERRORS = INDEX(line,'ERROR') =1 or
     INDEX(line,'REPEATS OF BY VALUES') > 0 or
     INDEX(LINE,'WARNING') = 1 or
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
  INFILE "&logpath" TRUNCOVER;
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
   if INDEX(LINE,'ERROR') = 1  or
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
   ELSE IF INDEX(LINE,'WARNING: Apparent symbolic') = 1 THEN DO;
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
   ELSE IF INDEX(line, 'WARNING') = 1  OR
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

proc sql print; 
ODS pdf text ="^S={just=center font_weight=bold font_style=italic
	font_size=12pt}^1n List of potential problems in log &logpath "; 
select logrow, srt, message  from saslog
order by logrow; 
ODS pdf text ="^S={just=center font_weight=bold font_style=italic
	font_size=12pt}^2n "; 
quit; 



PROC DATASETS LIBRARY=work NOLIST;
  DELETE saslog;
QUIT;


%MEND check_log;

%MACRO Review_logs(transfer_lib, trans_dir); 

%put ;
%put ;
%put ============================================================== ;
%put ;
%put Macro Review_Logs: ;
%put ;
%put Checking all logs found in %sysfunc(pathname(&transfer_lib)) for the following: ;
%put 1) Errors; 
%put 1) Warnings; 
%put 1) Notes; 
%put 1) Signs of PHI such as sensitive variable names, birthdates, social security numbers, etc. ;
%put ;
%put THIS IS BETA SOFTWARE-PLEASE SCRUTINIZE THE RESULTS AND REPORT PROBLEMS TO Christine.E.Bredfeldt@kp.org. ;
%put ;
%put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL LOGS - WHETHER;
%put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE LOG CONTAINS NO ERRORS OR PHI!!! ;
%put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL LOGS - WHETHER;
%put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE LOG CONTAINS NO ERRORS OR PHI!!! ;
%put ;
%put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL LOGS - WHETHER;
%put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE LOG CONTAINS NO ERRORS OR PHI!!! ;
%put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL LOGS - WHETHER;
%put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE LOG CONTAINS NO ERRORS OR PHI!!! ;
%put ;
%put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL LOGS - WHETHER;
%put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE LOG CONTAINS NO ERRORS OR PHI!!! ;
%put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL LOGS - WHETHER;
%put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE LOG CONTAINS NO ERRORS OR PHI!!! ;
%put ;
%put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL LOGS - WHETHER;
%put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE LOG CONTAINS NO ERRORS OR PHI!!! ;
%put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL LOGS - WHETHER;
%put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE LOG CONTAINS NO ERRORS OR PHI!!! ;
%put ;
%put ;
%put ============================================================== ;
%put ;
%put ;

title1 "Log Review for the directory &trans_dir." ;
title2 "please inspect all output carefully to make sure there are no errors or PHI!!!" ;

* get a list of all log files in the transfer directory; 
filename indata pipe "ls -1 &trans_dir";
data fnames; 
   infile indata truncover; 
   input filename $char1000.; 
   if upcase(strip(substr(filename,index(filename,'.')+1,length(filename)))) = 'LOG'; 
run;

proc sql noprint; 
select '&trans_dir' || '.' || fnames.filename into :d1-:d999
from fnames; 
quit; 
%local num_logs ;
%let num_logs = &sqlobs ;
quit ;
 
%local i ; %local j; 
 
%if &num_logs = 0 %then %do i = 1 %to 10 ;
	%put ERROR: NO logs FOUND IN &transfer_lib!!!! ;
%end;

* print a list of the log files to the report; 
proc sql print; 
ODS escapechar="^";
ODS pdf text ="^S={just=center font_weight=bold font_style=italic
	font_size=12pt}^4n List of all logs in the directory &trans_dir.: "; 

select filename from fnames 
order by filename;
quit;  
%RemoveDset(dset = fnames) ;
ods pdf startpage=now;

%do j = 1 %to &num_logs ;
%put about to check &&d&j ;
%check_log(logpath = &&d&j, DB_OBS_INFO='Y') ;
%end;

%mend Review_logs ;

