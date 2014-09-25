#!/bin/bash

#################################
# 检测系统是否需要重启，如果需要，则重启系统。
# 需要重启的情况分两种：
#	1. 系统安全更新时，内核有更新。
#	2. 系统运行时间超过 UP_MAX_DAY 天。
# 本脚本应该在任务计划中设置。在每天的系统没有用户访问的时间来运行。
# 任务计划设置的执行时间应该在下面的参数：REBOOT_AFTER 与 REBOOT_BEFORE 之间。否则不会达到重启系统的条件。
# Author: lxg
# Date: 2014-04-17
##################################

### History ######################
# 2014-06-25: change log format
#
##################################

LOG_FILE=/var/log/sys_reboot_cron.log

# 最长运行时间（天）
UP_MAX_DAY=32

# 可以重启的时间段（时）, REBOOT_AFTER:00 到 REBOOT_BEFORE:00
REBOOT_AFTER=0
REBOOT_BEFORE=5


# --- 以上为设置参数，可以更改。 ---
# --- --- --- --- --- --- 如非必要，不要更改下面代码 --- --- --- --- --- ---
UPT=$(uptime)
LOG_STR=''
TIME=`date`

reboot_sys() {
	NOW_HOUR=${UPT:1:2}
	if [ $NOW_HOUR -ge $REBOOT_AFTER ] && [ $NOW_HOUR -lt $REBOOT_BEFORE ]; then
		LOG_STR="$LOG_STR, restart system."
		echo $LOG_STR
		echo $LOG_STR >> $LOG_FILE
		/sbin/shutdown -r now
	else
		LOG_STR="$TIME : system must be restart between $REBOOT_AFTER:00 and $REBOOT_BEFORE:00."
		echo $LOG_STR
		echo $LOG_STR >> $LOG_FILE
	fi
}

SIG_FILE=/var/run/reboot-required
if [ -f "$SIG_FILE" ]; then
	# File can not be empty
	if [ ! -z "`cat $SIG_FILE`" ]; then
		LOG_STR="$TIME : AS sys update"
		reboot_sys
	else
		echo 'do not need reboot system.'
	fi
else
	UP=${UPT:13:2} #已运行时长
	TIME_TYPE=${UPT:15:3}
	IS_DAY=`expr index $TIME_TYPE 'd'` #已运行时长是否是日，而不是小时或月份
	if [ $IS_DAY -gt 0 ] && [ $UP -gt $UP_MAX_DAY ]; then
		LOG_STR="$TIME : AS uptime is too long"
		reboot_sys
	else
		echo 'do not need reboot system.'
	fi
fi

