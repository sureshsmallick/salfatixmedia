#!/bin/bash

SEND_MAIL_ERROR="dh@4js.com, cg@4js.com"
#put this to Yes for production
SENDMAIL_SEND_FLAG=Yes
FILENAME=$1
#
# test the number of arguments
#
if [ $# -ne 1 ]; then
  echo "Error with the number of arguments"
  exit 1
fi

if [ ! -s $FILENAME ]; then
  echo "Argument file is empty"
  exit 2
fi


if [ $SENDMAIL_SEND_FLAG = "Yes" ]; then
  cat $FILENAME | /usr/lib/sendmail -oi -t -f noreply@salfatix.com
fi
ERROR=$?
if [ $ERROR -ne 0 ]; then
  echo "Error while sending the email file $1"
  mail -s "SalfatixMedia sendmail error" "$SEND_MAIL_ERROR"<<EOF
Sending email with file $FILENAME returned $ERROR
Content of file : 
`cat $FILENAME`
EOF
  exit 4
fi
exit 0
