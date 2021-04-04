#!/bin/bash

Created by Chris Mariano

#Switch to the /tmp directory
cd /tmp

#Download the Trend installer
curl -O -k https://y5vpnu.manage.trendmicro.com:443/officescan/console/html/TMSM_HTML/ActiveUpdate/ClientInstall/tmsminstall.zip
#curl -O -k https://y5vpnu.manage.trendmicro.com:443/officescan/console/html/TMSM_HTML/ActiveUpdate/ClientInstall/tmsmuninstall.zip
curl -O -k https://raw.githubusercontent.com/xtian08/cyrepo/master/tmsmuninstall.zip

#Unzip the installer
unzip tmsminstall.zip
unzip tmsmuninstall.zip

#Install the Trend Software
#/tmp/TMUninstallLauncher.app/Contents/MacOS/TMUninstallLauncher –-uninstall
installer -pkg /tmp/tmsmuninstall/tmsmuninstall.pkg -target /
installer -pkg /tmp/tmsminstall/tmsminstall.pkg -target /

#Clean up the folder
rm tmsminstall.zip
rm tmsmuninstall.zip
rm -rf /tmp/TMUninstallLauncher.app
rm -rf /tmp/tmsminstall
rm -rf /tmp/tmsmuninstall

exit 0