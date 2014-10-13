#!/bin/sh
#***********************************************
# File Name  : Monitor.sh
# Description: 
# Make By    :lqf/200309129@163.com
# Date Time  :2012/07/13 
#***********************************************

sleeptime=180

xRouterLog 0 "Monitor.sh" "-" "in Monitor.sh"
sleep 15
while [ 1 ]
do
    if [ "" == "`ps | grep xCloudClient | grep -v grep | awk '{print $NF}'`" ]; then

        /usr/local/xcloud/bin/xCloudClient &
		xRouterLog 0 "Monitor.sh" "-" "start xCloudClient"
    fi
    if [ ` ps|grep crond|grep -v grep|wc -l` -eq 0 ]; then
    	/etc/init.d/cron restart &
    fi
   sleep $sleeptime
done
