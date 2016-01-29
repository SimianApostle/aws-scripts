#!/bin/bash

#################################
# Script Name:   amazon-file-sync-to-s3.sh
#
# Description:   This script is for synchronising files from a local location
#                up to a S3 Bucket in the Amazon Account
#                The Server running this script requires the server to have
#                a role attached to it that allows read / write access to S3
# 				 FOLDER_NAME will become the name of the folder in the S3 Bucket
#
# Script Author: oliver@leehaswell.co.uk
#
# Date:          17/09/2015
#
# Rev:           1.3
#
# Change Log:	 Added in debugging mode if required
# 				 Added in some extra debugging
# 				 Added GetOpts arguments to it so can work for both way syncs
#
# Requirements:	 you need to have a directory owned by the user (and permissions 700)
#                called: /var/log/s3-sync/
#
#
# Usage:
#
# */15 * * * * <PATH TO SCRIPT> -b <BUCKET PATH> -l <LOCAL PATH> -d <DIRECTION - UP / DOWN> -f <FOLDER NAME>
# 
# */15 * * * * /home/<USER>/bin/amazon-file-sync-to-s3.sh -b my-bucket/ -l /data/media/ -d UP -f fonts
# */15 * * * * /home/<USER>/bin/amazon-file-sync-to-s3.sh -b my-bucket/ -l /data/media/ -d UP -f static
#
#################################

#####################
#     VARIABLES     #
#####################

DATE=`date "+%Y-%m-%d"`
LOG_FILE=/var/log/s3-sync/s3-sync-$DATE.log
LINE="---------------------------------------"
DEBUG=false

#####################
#     FUNCTIONS     #
#####################

function writeLog () {
        echo "`date`: $1 " >> $LOG_FILE
        if $DEBUG;  then
                echo "`date`: $1 "
        fi
}

function writeLogStdin () {
        while read aline; do
                writeLog "$aline"
        done
}

errorExit () {
     writeLog "$1"
     writeLog "Usage: amazon-file-sync-to-s3.sh -b <PATH TO SCRIPT> -b <BUCKET PATH> -l <LOCAL PATH> -d <DIRECTION - UP / DOWN> -f <FOLDER NAME>"
     writeLog "Usage: amazon-file-sync-to-s3.sh -b /home/<USER>/bin/amazon-file-sync-to-s3.sh -b my-bucket/ -l /data/media/ -d UP -f fonts"
     exit 1
}

#####################
#        RUN        #
#####################

while getopts "b:f:l:d:x" OPT; do
	case $OPT in
		b)
			S3_BUCKET=$OPTARG
			;;
		f)
			FOLDER_NAME=$OPTARG
			LOG_FILE=/var/log/s3-sync/"$FOLDER_NAME"_sync-$DIRECTION-$DATE.log
			;;
		l)
			LOCAL_PATH=$OPTARG
			;;
		d)
			DIRECTION=$OPTARG
			;;
		x)
			DEBUG=true
			;;
		*)
			errorExit "Invalid option"
			;;
	esac
done

writeLog $LINE
writeLog "Starting Script"

if $DEBUG;  then
	writeLog "Debug mode set to $DEBUG"
	writeLog "Log File set as: $LOG_FILE"
	writeLog "S3 Bucket: $S3_BUCKET"
	writeLog "FOLDER_NAME: $FOLDER_NAME"
	writeLog "LOCAL_PATH: $LOCAL_PATH"
	writeLog "DIRECTION: $DIRECTION"
	writeLog "Absolute Local Path: $LOCAL_PATH$FOLDER_NAME"
	writeLog "Absolute S3 Path: s3://$S3_BUCKET$FOLDER_NAME"
fi

if [ $DIRECTION = "UP" ]; then
	writeLog "Sending contents of: $LOCAL_PATH$FOLDER_NAME to AWS S3: s3://$S3_BUCKET$FOLDER_NAME"
	writeLog "*********** AWS Commend Running ***********"
	writeLog "aws s3 sync $LOCAL_PATH$FOLDER_NAME s3://$S3_BUCKET$FOLDER_NAME"
	aws s3 sync $LOCAL_PATH$FOLDER_NAME s3://$S3_BUCKET$FOLDER_NAME 2>&1 | writeLogStdin
	writeLog "********** AWS Commend Finished ***********"
	else if [ $DIRECTION = "DOWN" ]; then
		writeLog "Grabbing contents of AWS S3: s3://$S3_BUCKET$FOLDER_NAME TO Local path: $LOCAL_PATH$FOLDER_NAME"
		writeLog "*********** AWS Commend Running ***********"
		writeLog "aws s3 sync s3://$S3_BUCKET$FOLDER_NAME $LOCAL_PATH$FOLDER_NAME"
		aws s3 sync s3://$S3_BUCKET$FOLDER_NAME $LOCAL_PATH$FOLDER_NAME 2>&1 | writeLogStdin
		writeLog "********** AWS Commend Finished ***********"
	fi
fi

if [[ ${?} -ne 0 ]]; then
        writeLog "Sync Failed - with an exit result of: ${?}"
else
        writeLog "Sync Successful - with an exit result of: ${?}"
fi

writeLog "Finished"
writeLog $LINE