#!/bin/bash

# Usage : bash scripts/deployAll.sh from projectdir
# Warning : product must be compiled first !!

DEPLOYMENT()
{
  MACHINE=$1
  PRODUCT=$2
  USER=$3
  SCRIPT_PATH=$4
  TITLE="$MACHINE : $PRODUCT deployment ?"
  echo "###########################################################################"
  echo "$TITLE"
  select answer in yes no
    do
      case $answer in
      "no")
        break;;
      "yes")
        scp scripts/deploy.sh $USER@$MACHINE:$SCRIPT_PATH/.
        scp deploy.tgz $USER@$MACHINE:.
        echo "Connecting $USER@$MACHINE and executing $SCRIPT_PATH/deploy.sh"
        ssh $USER@$MACHINE "bash $SCRIPT_PATH/deploy.sh /home/$USER/deploy.tgz"
        ssh $USER@$MACHINE "rm deploy.tgz"
        echo "Connection closed for $USER@$MACHINE....."
        break;;
      "*") continue;;
      esac
  done
}

# create archive to deploy
rm -f deploy.tgz
find . -name "*.bak" -exec rm -f {} \;
rm -fR exports/sendmail/*.txt
rm -fR exports/tmp/*.txt
rm -fR exports/tmp/*.xls
rm -fR log/*.log
tar czvf deploy.tgz Android/dist/*.apk ios/dist/* bin/* gbc/dist/customization/salfatixmedia log res scripts sql tools/db_updates xcf

DEPLOYMENT 'griffon' 'salfatixmedia' 'f4gl' '/fourjs/appli/scripts'
