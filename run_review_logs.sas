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
options CENTER PAGENO=1 SYMBOLGEN ERRORS = 2 sastrace=',,,d' sastraceloc=saslog nomlogic;
		*options NOCENTER PAGENO=1 SYMBOLGEN ERRORS = 2 mlogic source2      
        EMAILSYS='/opt/sas/utilities/bin/sasm.elm.mime';

/***********************************************************/
/* for testing purposes, call macro from local location    */
/* will be added to VDW Maco list 						   */	
/***********************************************************/
%let codedir = /apps/sas/datasets/data12/MAVDW/code/;
%let datadir = /apps/sas/datasets/data12/MAVDW/data/;

%let StdVars = &codedir.VDW_Support/StdVars.sas;
%include "&StdVars";
/***********************************************************/
/* define the project folder                               */
/***********************************************************/
%let trans_dir = &datadir.FDAMS/Data_Requests/mpr28/transfer/;
libname trans "&trans_dir";

** Where you want the PDF report spat out.  Please include a trailing path separator. ;
*%let out_folder = c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\ ;
%let out_folder = &datadir.cbredfeldt/test_phi/;
* what you want the pdf report to be named; 
%let log_review = log_review_mpr28;

** ====================== END EDIT SECTION ============================ ;
  
/***********************************************************/
/* include the chklog macro                                */
/***********************************************************/
%include vdw_macs ;
%include "&codedir.macros/review_logs.sas";
* get date for report; 
data _null_;
 call symput('run_dt',put(today(),yymmddn8.));
run;

options orientation = landscape ;

ods pdf file = "&out_folder.&log_review" STARTPAGE=NEVER;

ods EXCLUDE ENGINEHOST (PERSIST);

  options nofmterr ;

 %review_logs(transfer_lib=trans, trans_dir = &trans_dir); 
 run; 

ods pdf close; 
 run; 

 ods select all; 
 run; 
