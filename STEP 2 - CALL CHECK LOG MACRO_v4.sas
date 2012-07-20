/*--------------------------------------------------------------------*/
/*----------   S P E C I F I C A T I O N   D O C U M E N T  ----------*/
/*--------------------------------------------------------------------*/
/* PROJECT              :  VALIDATION                                 */
/* PROGRAM NAME         :  example_call_check_log_macro               */
/* PROGRAMMER			:  NARGIS ANWAR								  */
/* HEALTHPARTNERS RESEARCH FOUNDATION								  */
/* (952) 967 - 5046													  */
/**********************************************************************/
/* PROCESS:  run the job stream and then call the macro to check      */
/*           the log                                                  */
/*--------------------------------------------------------------------*/
options NOCENTER PAGENO=1 SYMBOLGEN ERRORS = 2 mlogic source2
        ; ** EMAILSYS='/opt/sas/utilities/bin/sasm.elm.mime';

/***********************************************************/
/* for testing purposes, call macro from local location    */
/* will be added to VDW Maco list 						   */
/***********************************************************/
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
/***********************************************************/
/* define the project folder                               */
/***********************************************************/
%let path= %str(C:\Documents and Settings\pardre1\Desktop\mid_year\phi\) ;

/***********************************************************/
/* include the chklog macro                                */
/***********************************************************/
%include "&path.STEP 1 - CHECK LOG FOR ERROR AND PHI_v4.sas";

/***********************************************************/
/* Select option 1 if you want e-mail notification, else
   select option 2 which will only save file in the folder
   if there is any error message 						   */
/* example calls to the chklog macro                       */
/***********************************************************/
%check_log(	logpath=&path, /*the path to the folder containing the log file */
           	logfile=STEP 1 - CHECK LOG FOR ERROR AND PHI_v4, /* the name of the log file without the .log extension */
   			jobname= &logfile. , /* Job Name to appear in email subject line*/
			option=2, /* 1=Email , 2=No e-mail, only Save rtf file in folder if there is any error */
            DB_OBS_INFO=Y , /* SET TO Y IF YOU WANT THE Data set OBS INFO COLLECTED */
			sendto = "NARGIS.X.ANWAR@HEALTHPARTNERS.COM"
 );





