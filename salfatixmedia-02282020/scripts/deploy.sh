#!/bin/bash

#
# Script that deploys the ams and all the batchs on the kobe machine
#
# Usage : sh deploy.sh full_path_to_tgz_file
# Example : sh deploy.sh /home/appliclm/pcode.tgz
#

#move the exported data of the previous used clm to the new one
MOVE_EXPORTED_DATA()
{
  IFS=$'\n'
  DATA_DIRNAME=$1
  DATA_SOURCE_DIRNAME=/fourjs/appli/$DEPLOY_SYMB_LINK/$DATA_DIRNAME
  for i in `ls $DATA_SOURCE_DIRNAME`; do
    mv $DATA_SOURCE_DIRNAME/$i $DATA_DIRNAME/.
  done
}

DEPLOY_DATE=`date +%Y%m%d-%H%M%S`

DEPLOY_ROOT_DIR=/fourjs/appli
DEPLOY_NAME=deployment-salfatixmedia-$DEPLOY_DATE
DEPLOY_DIR=$DEPLOY_ROOT_DIR/$DEPLOY_NAME
DEPLOY_PACKAGE=$1
DEPLOY_SYMB_LINK=salfatixmedia

DEPLOY_GBC_DIR=$DEPLOY_ROOT_DIR/gbc
DEPLOY_GBC_NAME=deployment-gbc-$DEPLOY_DATE
DEPLOY_GBC_FILENAME=gbc_salfatixmedia

DEPLOY_MOBILE_PACKAGE_DIR=/fourjs/gas/dev/web

echo "Deploy in production environment ?"
select answer in yes no
  do
    case $answer in
      "no") echo "Deployment abort..."; exit;;
      "yes") break;;
      "*") continue;;
    esac
done

echo "Create deployment directory $DEPLOY_DIR..."
mkdir -p $DEPLOY_DIR
if [ $? -ne 0 ]; then
  echo "mkdir -p $DEPLOY_DIR failed."
  exit 1
fi

echo "Go to deployment directory $DEPLOY_DIR..."
cd $DEPLOY_DIR

echo "Extract files from archive $DEPLOY_PACKAGE..."
tar zxf $DEPLOY_PACKAGE

echo "Cleanup archive..."
find . -name .keep -exec rm {} \;
rm -f scripts/deployAll.sh
rm -f scripts/deploy.sh
rm -f xcf/apps/apps.xcf
find . -name *.4gl -exec rm {} \;
find . -name *.4fd -exec rm {} \;
find . -name *.per -exec rm {} \;
mkdir -p exports/posts
mkdir -p exports/sendmail
mkdir -p exports/tmp

echo "Activate this deployment ?"
select answer in yes no
  do
    case $answer in
      "no")
        break;;
      "yes")
        echo "Move exports folder from old installation to this new deployment..."
        MOVE_EXPORTED_DATA exports/posts
        MOVE_EXPORTED_DATA exports/sendmail
        MOVE_EXPORTED_DATA exports/tmp
        echo "Deploy GBC..."
        cd $DEPLOY_GBC_DIR
        mv /fourjs/appli/$DEPLOY_NAME/gbc/dist/customization/salfatixmedia $DEPLOY_GBC_NAME
        rm -f $DEPLOY_GBC_FILENAME
        echo $DEPLOY_GBC_NAME > $DEPLOY_GBC_FILENAME
        echo "Deploy mobile packages..."
        cp /fourjs/appli/$DEPLOY_NAME/Android/dist/*.apk $DEPLOY_MOBILE_PACKAGE_DIR/.
        cp /fourjs/appli/$DEPLOY_NAME/ios/dist/* $DEPLOY_MOBILE_PACKAGE_DIR/.
        echo "Link to new application version..."
        cd $DEPLOY_ROOT_DIR
        rm -f $DEPLOY_SYMB_LINK
        ln -s $DEPLOY_NAME $DEPLOY_SYMB_LINK
        break;;
      "*") continue;;
    esac
done
echo "Deployment in $DEPLOY_LOCATION environment finished..."
