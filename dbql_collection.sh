#!/bin/bash

#####################################################################
#                                  
# Script Name: dbql_collection.sh                                 
# 		
# Description: Collect DBQL logs for a session.
#
# Author: Noe Espino (np255021)
#
# Email: noe.penaespino@teradata.com
#
# Date:  2024-09-11
#
# Version: 1.0				   
#                                 				  
#####################################################################



#Defenitions

LOGFILE="session_details_$(date +"%Y%m%d%H%M%S").log"
TERADATA_SERVER=""
USERNAME=""
PASSWORD=""
SESSION=""
DATESESS=""


#Log and print function

log_and_print() {
local timestamp=$(date +"%Y-%m-%d %H:%M:%S")    
echo "[$timestamp] $1" | tee -a "$LOGFILE"
}

#Input data in shell fuction: db-server, username, password, session, date. 

input_data ()
{

read -p  "Server:" TERADATA_SERVER 
read -p  "DB-Username:" USERNAME 
read -sp "Password: " PASSWORD 
echo
read -p  "Session:" SESSION  
read -p  "Date (e.g. 2024-01-04):" DATESESS 

} 

#bteq collection function: dbc, pdcrinfo, vcl.


bteq_collection(){

log_and_print "DBQL-Collection"
bteq <<EOF | tee -a "$LOGFILE"
.LOGON $TERADATA_SERVER/$USERNAME,$PASSWORD;


/* Date ranges in the different locations of dbqlog */ 

SELECT min(logdate), max(logdate) from pdcrinfo.DBQLogTbl;

SELECT min(CollectTimeStamp), max(CollectTimeStamp) from dbc.dbqlogtbl;

SELECT min(CollectTimeStamp), max(CollectTimeStamp) from TD_METRIC_SVC.Parquet_DBQLogTbl_v3; 


/* Database version */

SELECT * FROM dbc.dbcinfo; 

/*BTEQ output format */ 

.width 1048575
.retlimit 0 *
.separator '|'
.titledashes off

/*pdcrinfo dbqlog for session */
.export file = /var/opt/teradata/tdtemp/Session-$SESSION-pdcrinfo-dbqlog.txt


SELECT * FROM  pdcrinfo.DBQLogTbl 
WHERE logdate = '$DATESESS'
AND sessionid = $SESSION 
order by requestnum, internalrequestnum;

.export reset

/*dbc dbqlog for session */

.export file = /var/opt/teradata/tdtemp/Session-$SESSION-dbc-dbqlog.txt

SELECT * FROM dbc.dbqlogtbl
WHERE sessionid = $SESSION
order by requestnum, internalrequestnum;

.export reset

/*VCL dbqlog for session */ 

.export file = /var/opt/teradata/tdtemp/Session-$SESSION-vcl-dbqlog.txt

SEL * FROM TD_METRIC_SVC.Parquet_DBQLogTbl_v3 
WHERE sessionid = $SESSION
AND cast(collecttimestamp as date) = date '$DATESESS'
order by requestnum, internalrequestnum;

.export reset

.LOGOFF;
.QUIT;
EOF

}


input_data
bteq_collection

