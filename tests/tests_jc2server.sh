#!/bin/bash
# TravisCI Tests: Just Cause 2
# Server Management Script
# Author: Daniel Gibbs
# Website: https://gameservermanagers.com
version="101716"

if [ -f ".dev-debug" ]; then
	exec 5>dev-debug.log
	BASH_XTRACEFD="5"
	set -x
fi

#### Variables ####

# Notification Alerts
# (on|off)

# Email
emailalert="off"
email="email@example.com"

# Pushbullet
# https://www.pushbullet.com/#settings
pushbulletalert="off"
pushbullettoken="accesstoken"

# Steam login
steamuser="anonymous"
steampass=""

# Start Variables
updateonstart="off"

fn_parms(){
parms=""
}

#### Advanced Variables ####

# Github Branch Select
# Allows for the use of different function files
# from a different repo and/or branch.
githubuser="dgibbs64"
githubrepo="linuxgsm"
githubbranch="$TRAVIS_BRANCH"

# Steam
appid="261140"

# Server Details
servicename="jc2-server"
gamename="Just Cause 2"
engine="avalanche"

# Directories
rootdir="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
selfname="$(basename $(readlink -f "${BASH_SOURCE[0]}"))"
lockselfname=".${servicename}.lock"
lgsmdir="${rootdir}/lgsm"
functionsdir="${lgsmdir}/functions"
libdir="${lgsmdir}/lib"
filesdir="${rootdir}/serverfiles"
systemdir="${filesdir}"
executabledir="${filesdir}"
executable="./Jcmp-Server"
servercfg="config.lua"
servercfgdir="${filesdir}"
servercfgfullpath="${servercfgdir}/${servercfg}"
servercfgdefault="${servercfgdir}/default_config.lua"
backupdir="${rootdir}/backups"

# Logging
logdays="7"
#gamelogdir="" # No server logs available
scriptlogdir="${rootdir}/log/script"
consolelogdir="${rootdir}/log/console"
consolelogging="on"

scriptlog="${scriptlogdir}/${servicename}-script.log"
consolelog="${consolelogdir}/${servicename}-console.log"
emaillog="${scriptlogdir}/${servicename}-email.log"

scriptlogdate="${scriptlogdir}/${servicename}-script-$(date '+%d-%m-%Y-%H-%M-%S').log"
consolelogdate="${consolelogdir}/${servicename}-console-$(date '+%d-%m-%Y-%H-%M-%S').log"

##### Script #####
# Do not edit

# Fetches core_dl for file downloads
fn_fetch_core_dl(){
github_file_url_dir="lgsm/functions"
github_file_url_name="${functionfile}"
filedir="${functionsdir}"
filename="${github_file_url_name}"
githuburl="https://raw.githubusercontent.com/${githubuser}/${githubrepo}/${githubbranch}/${github_file_url_dir}/${github_file_url_name}"
# If the file is missing, then download
if [ ! -f "${filedir}/${filename}" ]; then
	if [ ! -d "${filedir}" ]; then
		mkdir -p "${filedir}"
	fi
	echo -e "    fetching ${filename}...\c"
	# Check curl exists and use available path
	curlpaths="$(command -v curl 2>/dev/null) $(which curl >/dev/null 2>&1) /usr/bin/curl /bin/curl /usr/sbin/curl /sbin/curl)"
	for curlcmd in ${curlpaths}
	do
		if [ -x "${curlcmd}" ]; then
			break
		fi
	done
	# If curl exists download file
	if [ "$(basename ${curlcmd})" == "curl" ]; then
		curlfetch=$(${curlcmd} -s --fail -o "${filedir}/${filename}" "${githuburl}" 2>&1)
		if [ $? -ne 0 ]; then
			echo -e "\e[0;31mFAIL\e[0m\n"
			echo "${curlfetch}"
			echo -e "${githuburl}\n"
			exit 1
		else
			echo -e "\e[0;32mOK\e[0m"
		fi
	else
		echo -e "\e[0;31mFAIL\e[0m\n"
		echo "Curl is not installed!"
		echo -e ""
		exit 1
	fi
	chmod +x "${filedir}/${filename}"
fi
source "${filedir}/${filename}"
}

core_dl.sh(){
# Functions are defined in core_functions.sh.
functionfile="${FUNCNAME}"
fn_fetch_core_dl
}

core_functions.sh(){
# Functions are defined in core_functions.sh.
functionfile="${FUNCNAME}"
fn_fetch_core_dl
}

core_dl.sh
core_functions.sh

fn_currentstatus_tmux(){
	check_status.sh
	if [ "${status}" != "0" ]; then
		currentstatus="ONLINE"
	else
		currentstatus="OFFLINE"
	fi
}

fn_currentstatus_ts3(){
	check_status.sh
	if [ "${status}" != "0" ]; then
		currentstatus="ONLINE"
	else
		currentstatus="OFFLINE"
	fi
}

fn_setstatus(){
	fn_currentstatus_tmux
	echo""
	echo "Required status: ${requiredstatus}"
	counter=0
	echo "Current status:  ${currentstatus}"
	while [  "${requiredstatus}" != "${currentstatus}" ]; do
		counter=$((counter+1))
		fn_currentstatus_tmux
		echo -ne "New status:  ${currentstatus}\\r"

		if [ "${requiredstatus}" == "ONLINE" ]; then
			(command_start.sh > /dev/null 2>&1)
		else
			(command_stop.sh > /dev/null 2>&1)
		fi
		if [ "${counter}" -gt "5" ]; then
			currentstatus="FAIL"
			echo "Current status:  ${currentstatus}"
			echo ""
			echo "Unable to start or stop server."
			exit 1
		fi
	done
	echo -ne "New status:  ${currentstatus}\\r"
	echo -e "\n"
	echo "Test starting:"
	echo ""
	sleep 0.5
}

# End of every test will expect the result to either pass or fail
# If the script does not do as intended the whole test will fail
# if excpecting a pass
fn_test_result_pass(){
	if [ $? != 0 ]; then
		echo "================================="
		echo "Expected result: PASS"
		echo "Actual result: FAIL"
		fn_print_fail_nl "TEST FAILED"
		exitcode=1
		core_exit.sh
	else
		echo "================================="
		echo "Expected result: PASS"
		echo "Actual result: PASS"
		fn_print_ok_nl "TEST PASSED"
		echo ""
	fi
}

# if excpecting a fail
fn_test_result_fail(){
	if [ $? == 0 ]; then
		echo "================================="
		echo "Expected result: FAIL"
		echo "Actual result: PASS"
		fn_print_fail_nl "TEST FAILED"
		exitcode=1
		core_exit.sh
	else
		echo "================================="
		echo "Expected result: FAIL"
		echo "Actual result: FAIL"
		fn_print_ok_nl "TEST PASSED"
		echo ""
	fi
}

echo "================================="
echo "TravisCI Tests"
echo "Linux Game Server Manager"
echo "by Daniel Gibbs"
echo "https://gameservermanagers.com"
echo "================================="
echo ""
echo "================================="
echo "Server Tests"
echo "Using: ${gamename}"
echo "Testing Branch: $TRAVIS_BRANCH"
echo "================================="
echo ""

echo "0.1 - Create log dir's"
echo "================================="
echo "Description:"
echo "Create log dir's"
echo ""
(install_logs.sh)


echo "0.2 - Enable dev-debug"
echo "================================="
echo "Description:"
echo "Enable dev-debug"
echo ""
(command_dev_debug.sh)
fn_test_result_pass

echo "1.0 - start - no files"
echo "================================="
echo "Description:"
echo "test script reaction to missing server files."
echo "Command: ./jc2server start"
echo ""
(command_start.sh)
fn_test_result_fail

echo ""
echo "1.1 - getopt"
echo "================================="
echo "Description:"
echo "displaying options messages."
echo "Command: ./jc2server"
echo ""
(core_getopt.sh)
fn_test_result_pass

echo ""
echo "1.2 - getopt with incorrect args"
echo "================================="
echo "Description:"
echo "displaying options messages."
echo "Command: ./jc2server abc123"
echo ""
getopt="abc123"
(core_getopt.sh)
fn_test_result_fail

echo ""
echo "2.0 - install"
echo "================================="
echo "Description:"
echo "install ${gamename} server."
echo "Command: ./jc2server auto-install"
(fn_autoinstall)
fn_test_result_pass


echo ""
echo "3.1 - start"
echo "================================="
echo "Description:"
echo "start ${gamename} server."
echo "Command: ./jc2server start"
requiredstatus="OFFLINE"
fn_setstatus
(command_start.sh)
fn_test_result_pass

echo ""
echo "3.2 - start - online"
echo "================================="
echo "Description:"
echo "start ${gamename} server while already running."
echo "Command: ./jc2server start"
requiredstatus="ONLINE"
fn_setstatus
(command_start.sh)
fn_test_result_fail

echo ""
echo "3.3 - start - updateonstart"
echo "================================="
echo "Description:"
echo "will update server on start."
echo "Command: ./jc2server start"
requiredstatus="OFFLINE"
fn_setstatus
(updateonstart="on";command_start.sh)
fn_test_result_pass

echo ""
echo "3.4 - stop"
echo "================================="
echo "Description:"
echo "stop ${gamename} server."
echo "Command: ./jc2server stop"
requiredstatus="ONLINE"
fn_setstatus
(command_stop.sh)
fn_test_result_pass

echo ""
echo "3.5 - stop - offline"
echo "================================="
echo "Description:"
echo "stop ${gamename} server while already stopped."
echo "Command: ./jc2server stop"
requiredstatus="OFFLINE"
fn_setstatus
(command_stop.sh)
fn_test_result_fail

echo ""
echo "3.6 - restart"
echo "================================="
echo "Description:"
echo "restart ${gamename}."
echo "Command: ./jc2server restart"
requiredstatus="ONLINE"
fn_setstatus
(command_restart.sh)
fn_test_result_pass

echo ""
echo "3.7 - restart - offline"
echo "================================="
echo "Description:"
echo "restart ${gamename} while already stopped."
echo "Command: ./jc2server restart"
requiredstatus="OFFLINE"
fn_setstatus
(command_restart.sh)
fn_test_result_pass

echo "4.1 - update"
echo "================================="
echo "Description:"
echo "check for updates."
echo "Command: ./jc2server update"
requiredstatus="OFFLINE"
fn_setstatus
(command_update.sh)
fn_test_result_pass

echo ""
echo "4.2 - update  - change buildid"
echo "================================="
echo "Description:"
echo "change the buildid tricking SteamCMD to update."
echo "Command: ./jc2server update"
requiredstatus="OFFLINE"
fn_setstatus
fn_print_info_nl "changed buildid to 0."
sed -i 's/[0-9]\+/0/' "${filesdir}/steamapps/appmanifest_${appid}.acf"
(command_update.sh)
fn_test_result_pass

echo ""
echo "4.3 - update  - change buildid - online"
echo "================================="
echo "Description:"
echo "change the buildid tricking SteamCMD to update server while already running."
echo "Command: ./jc2server update"
requiredstatus="ONLINE"
fn_setstatus
fn_print_info_nl "changed buildid to 0."
sed -i 's/[0-9]\+/0/' "${filesdir}/steamapps/appmanifest_${appid}.acf"
(command_update.sh)
fn_test_result_pass

echo ""
echo "4.4 - update  - remove appmanifest file"
echo "================================="
echo "Description:"
echo "removing appmanifest file will cause script to repair."
echo "Command: ./jc2server update"
requiredstatus="OFFLINE"
fn_setstatus
fn_print_info_nl "removed appmanifest_${appid}.acf."
rm --verbose "${filesdir}/steamapps/appmanifest_${appid}.acf"
(command_update.sh)
fn_test_result_pass

echo ""
echo "4.5 - force-update"
echo "================================="
echo "Description:"
echo "force-update bypassing update check."
echo "Command: ./jc2server force-update"
requiredstatus="OFFLINE"
fn_setstatus
(forceupdate=1;command_update.sh)
fn_test_result_pass

echo ""
echo "4.6 - force-update - online"
echo "================================="
echo "Description:"
echo "force-update bypassing update check server while already running."
echo "Command: ./jc2server force-update"
requiredstatus="ONLINE"
fn_setstatus
(forceupdate=1;command_update.sh)
fn_test_result_pass

echo ""
echo "4.7 - validate"
echo "================================="
echo "Description:"
echo "validate server files."
echo "Command: ./jc2server validate"
requiredstatus="OFFLINE"
fn_setstatus
(command_validate.sh)
fn_test_result_pass

echo ""
echo "4.8 - validate - online"
echo "================================="
echo "Description:"
echo "validate server files while server already running."
echo ""
echo "Command: ./jc2server validate"
requiredstatus="ONLINE"
fn_setstatus
(command_validate.sh)
fn_test_result_pass

echo ""
echo "5.1 - monitor - online"
echo "================================="
echo "Description:"
echo "run monitor server while already running."
echo "Command: ./jc2server monitor"
requiredstatus="ONLINE"
fn_setstatus
(command_monitor.sh)
fn_test_result_pass


echo ""
echo "5.2 - monitor - offline - with lockfile"
echo "================================="
echo "Description:"
echo "run monitor while server is offline with lockfile."
echo "Command: ./jc2server monitor"
requiredstatus="OFFLINE"
fn_setstatus
fn_print_info_nl "creating lockfile."
date > "${rootdir}/${lockselfname}"
(command_monitor.sh)
fn_test_result_pass


echo ""
echo "5.3 - monitor - offline - no lockfile"
echo "================================="
echo "Description:"
echo "run monitor while server is offline with no lockfile."
echo "Command: ./jc2server monitor"
requiredstatus="OFFLINE"
fn_setstatus
(command_monitor.sh)
fn_test_result_fail

echo ""
echo "5.4 - monitor - gsquery.py failure"
echo "================================="
echo "Description:"
echo "gsquery.py will fail to query port."
echo "Command: ./jc2server monitor"
requiredstatus="ONLINE"
fn_setstatus
sed -i 's/[0-9]\+/0/' "${servercfgfullpath}"
(command_monitor.sh)
fn_test_result_fail
echo ""
fn_print_info_nl "Re-generating ${servercfg}."
install_config.sh
echo "================================="

echo ""
echo "6.0 - details"
echo "================================="
echo "Description:"
echo "display details."
echo "Command: ./jc2server details"
requiredstatus="ONLINE"
fn_setstatus
(command_details.sh)
fn_test_result_pass

echo ""
echo "================================="
echo "Server Tests - Complete!"
echo "Using: ${gamename}"
echo "================================="
requiredstatus="OFFLINE"
fn_setstatus
sleep 1
fn_print_info "Tidying up directories."
sleep 1
rm -rfv "${serverfiles}"
core_exit.sh
