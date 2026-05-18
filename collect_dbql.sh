
#!/bin/bash

############################################################
#                                                          #         
# Script Name: dbql_collection.sh                          #                 
# 		                                           #
# Description: Bash/Bteq script to collect DBQL logs for   #
# query-performance investigation.                         #
#                                                          #
# Author: Noe Espino (np255021)                            #
#                                                          #
# Email: noe.penaespino@teradata.com                       #
#                                                          #
# Date:  2026-05-11                                        #
#                                                          #
# Version: branch_fr                                       #
#                                                          #
#                                 			   #	  
############################################################


#####################Global Variables################################################

LOGFILE="dbqlcollect__$(date +"%Y%m%d%H%M%S").log"
TERADATA_SERVER=""
USERNAME=""
PASSWORD=""
SESSION=""
DATESESS=""
QUERYID=""
OPTION=""
YEAR=""
MONTH=""
DAY=""


############################Functions###############################################



#Log and print function#

log_and_print() {
local timestamp=$(date +"%Y-%m-%d %H:%M:%S")    
echo "[$timestamp] $1" | tee -a "$LOGFILE"
}

#Input data fuctions: db-server, username, password, session, queryId, date #

input_data_dbqlog ()
{

read -p  "Server:" TERADATA_SERVER 
read -p  "DB-Username:" USERNAME 
read -sp "Password: " PASSWORD 
echo
read -p  "Session:" SESSION  
read -p  "Date (e.g. yyyy-mm-dd):" DATESESS 


### PATH KB0047374 Lake: DBQL ####################################################

IFS='-' read -r YEAR MONTH DAY <<< "$DATESESS"

##ON VCL dbqlogs are exported/moved to foreign-tables every 10-15 minutes ##
##################################################################################


} 

input_data_step_explain()
{

read -p  "Server:" TERADATA_SERVER 
read -p  "DB-Username:" USERNAME 
read -sp "Password: " PASSWORD 
echo
read -p "QueryID: " QUERYID
read -p "Date (e.g. yyyy-mm-dd):" DATESESS

### PATH KB0047374 Lake: DBQL ####################################################

IFS='-' read -r YEAR MONTH DAY <<< "$DATESESS"

##ON VCL dbqlogs are exported/moved to foreign-tables every 10-15 minutes ##
##################################################################################



#DBQLog collection function: dbc, pdcrinfo, vcl.

}

dbqlog_collect(){

log_and_print "DBQL-Collection"
bteq <<EOF | tee -a "$LOGFILE"
.LOGON $TERADATA_SERVER/$USERNAME,$PASSWORD;


/*BTEQ output format */ 

.width 1048575
.retlimit 0 *
.separator '|'
.titledashes off

/*BTEQ output format */


.export file = /var/opt/teradata/tdtemp/Session-$SESSION-dbqlog.txt

/*dbc dbqlog for session */

SELECT * FROM dbc.QryLogV
WHERE sessionid = $SESSION
AND cast(CollectTimeStamp as date) = '$DATESESS'
order by requestnum, internalrequestnum;

.IF ACTIVITYCOUNT > 1 THEN .GOTO LabelEnd

/*pdcrinfo dbqlog for session */

SELECT * FROM  pdcrinfo.DBQLogTbl 
WHERE logdate = '$DATESESS'
AND sessionid = $SESSION 
order by requestnum, internalrequestnum;


.IF ACTIVITYCOUNT > 1 THEN .GOTO LabelEnd


/*VCL dbqlog for session */ 


SEL * FROM TD_METRIC_SVC.DBQLogV 
WHERE sessionid = $SESSION
AND path_year = $YEAR
AND path_month = $MONTH
AND path_day = $DAY
order by requestnum, internalrequestnum;


.LABEL LabelEnd

.export reset

.LOGOFF;
.QUIT;
EOF

}

dbqlstep_collect(){

log_and_print "DBQLStep-Collection"
bteq <<EOF | tee -a "$LOGFILE"
.LOGON $TERADATA_SERVER/$USERNAME,$PASSWORD;


/*BTEQ output format */ 

.width 1048575
.retlimit 0 *
.separator '|'
.titledashes off

/*BTEQ output format */


.export file = /var/opt/teradata/tdtemp/QueryId-$QUERYID-dbqlstep.txt



/*dbc dbqlstep for queryid */

SELECT * FROM dbc.QryLogSteps
WHERE queryid = $QUERYID
AND cast(CollectTimeStamp as date) = '$DATESESS'
order by StepLev1Num, StepLev2Num;

.IF ACTIVITYCOUNT > 1 THEN .GOTO LabelEnd


/*pdcrinfo dbqlog for session */

SELECT * FROM  pdcrinfo.DBQLstepTbl
WHERE queryid = $QUERYID
AND cast(CollectTimeStamp as date) = '$DATESESS'
order by StepLev1Num, StepLev2Num;


.IF ACTIVITYCOUNT > 1 THEN .GOTO LabelEnd


/*VCL dbqlog for session */ 


SEL * FROM TD_METRIC_SVC.DBQLStepV 
WHERE queryid = $QUERYID
AND path_year = $YEAR
AND path_month = $MONTH
AND path_day = $DAY
order by StepLev1Num, StepLev2Num;




.LABEL LabelEnd
.export reset

.LOGOFF;
.QUIT;
EOF


}


dbqlexplain_collect(){

log_and_print "DBQLExplain-Collection"
bteq <<EOF | tee -a "$LOGFILE"
.LOGON $TERADATA_SERVER/$USERNAME,$PASSWORD;


/*BTEQ output format */ 

.width 1048575
.retlimit 0 *
.separator '|'
.titledashes off

/*BTEQ output format */


.export file = /var/opt/teradata/tdtemp/QueryId-$QUERYID-dbqlExplain.txt



/*dbc dbqlstep for queryid */

SELECT * FROM dbc.QryLogExplainV
WHERE queryid = $QUERYID
AND cast(CollectTimeStamp as date) = '$DATESESS';

.IF ACTIVITYCOUNT > 1 THEN .GOTO LabelEnd


/*pdcrinfo dbqlog for session */

SELECT * FROM  pdcrinfo.DBQLExplaintbl
WHERE queryid = $QUERYID
AND cast(CollectTimeStamp as date) = '$DATESESS';


.IF ACTIVITYCOUNT > 1 THEN .GOTO LabelEnd


/*VCL dbqlog for session */ 


SEL * FROM TD_METRIC_SVC.DBQLExplainV  
WHERE queryid = $QUERYID
AND path_year = $YEAR
AND path_month = $MONTH
AND path_day = $DAY;

.LABEL LabelEnd

.export reset

.LOGOFF;
.QUIT;
EOF


}



dbqlSQL_collect(){

log_and_print "DBQLSQL-Collection"
bteq <<EOF | tee -a "$LOGFILE"
.LOGON $TERADATA_SERVER/$USERNAME,$PASSWORD;


/*BTEQ output format */ 

.width 1048575
.retlimit 0 *
.separator '|'
.titledashes off

/*BTEQ output format */


.export file = /var/opt/teradata/tdtemp/QueryId-$QUERYID-dbqlSQL.txt



/*dbc dbqlstep for queryid */

SELECT * FROM dbc.QryLogSQLV
WHERE queryid = $QUERYID
AND cast(CollectTimeStamp as date) = '$DATESESS';

.IF ACTIVITYCOUNT > 1 THEN .GOTO LabelEnd


/*pdcrinfo dbqlog for session */

SELECT * FROM  pdcrinfo.DBQLSQLTbl
WHERE queryid = $QUERYID
AND cast(CollectTimeStamp as date) = '$DATESESS';


.IF ACTIVITYCOUNT > 1 THEN .GOTO LabelEnd



/*VCL dbqlog for session */ 


SEL * FROM TD_METRIC_SVC.DBQLSqlV  
WHERE queryid = $QUERYID
AND path_year = $YEAR
AND path_month = $MONTH
AND path_day = $DAY;

.LABEL LabelEnd
.export reset

.LOGOFF;
.QUIT;
EOF


}


upload_dbql (){

##Array to check file were generated 

DBQLogFiles=(
"/var/opt/teradata/tdtemp/Session-$SESSION-dbqlog.txt"
"/var/opt/teradata/tdtemp/QueryId-$QUERYID-dbqlstep.txt"
"/var/opt/teradata/tdtemp/QueryId-$QUERYID-dbqlExplain.txt"
"/var/opt/teradata/tdtemp/QueryId-$QUERYID-dbqlSQL.txt"

)

found=false

for file in "${DBQLogFiles[@]}"; do
        #check if the file is not empty
        if [ -s "$file" ]; then
                echo "DBQL log File $file ready for upload/download, check /var/opt/teradata/tdtemp/ for file."
                found=true
                
        fi
done

##check if files are with data

if [ "$found" = false ]; then
        echo "No data generated for dbql logfile, review log for root cause. We might need to collect without the DBQLCollect script."
fi

}


############################################################################

declare -A MENU_OPTIONS=(
    [a]="DBQLog|Collects DBQL logs for a specific session"
    [b]="DBQLStep|Collects DBQL step details for a query"
    [c]="DBQLExplain|Collects DBQL explain plan for a query"
    [d]="DBQLSQL|Collects DBQL SQL text for a query"
)

display_menu() {
    log_and_print ""
    log_and_print "╔════════════════════════════════════════╗"
    log_and_print "║     DBQL Collection Tool - v1.0        ║"
    log_and_print "╚════════════════════════════════════════╝"
    log_and_print ""
    log_and_print "Select what you want to collect:"
    log_and_print ""
    
    for key in a b c d; do
        IFS='|' read -r title desc <<< "${MENU_OPTIONS[$key]}"
        log_and_print "  [$key] $title"
        log_and_print "        → $desc"
    done
    
    log_and_print ""
}

get_menu_selection() {
    local choice
    while true; do
        display_menu
        read -p "Enter your choice [a-d]: " choice
        
        if [[ -v MENU_OPTIONS[$choice] ]]; then
            OPTION="$choice"
            IFS='|' read -r title desc <<< "${MENU_OPTIONS[$choice]}"
            log_and_print "You selected: $title"
            log_and_print ""
            return 0
        else
            log_and_print "ERROR: '$choice' is not a valid option. Try again."
            echo ""
        fi
    done
}

get_menu_selection

case $OPTION in

        a)      
                input_data_dbqlog
                dbqlog_collect
                upload_dbql
                ;;

        b)      
                input_data_step_explain
                dbqlstep_collect
                upload_dbql
                ;;

        c)      
                input_data_step_explain
                dbqlexplain_collect
                upload_dbql
                ;;
        d)
                input_data_step_explain
                dbqlSQL_collect
                upload_dbql
                ;;

        *) echo "Seems you did not select a correct option"
                ;;
esac


