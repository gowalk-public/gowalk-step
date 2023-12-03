#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG_tmp_script_file_path="${THIS_SCRIPT_DIR}/._script_cont"

#config
source "${THIS_SCRIPT_DIR}/variables.sh"

#functions to change app version and build
content=$(<"${THIS_SCRIPT_DIR}/change_version.sh")

#functions to manipulate with Pods and Packages
content+=$(<"${THIS_SCRIPT_DIR}/pods_packages.sh")

#function to get credentials for AppStoreConnect API
content+=$(<"${THIS_SCRIPT_DIR}/appstore_creds.sh")

#function to get budnle id from Xcode project
content+=$(<"${THIS_SCRIPT_DIR}/get_bundleid.sh")

#function to get app id from AppStoreConnect API
content+=$(python3 "${THIS_SCRIPT_DIR}/getappid.py")

#function to create app at AppStoreConnect API if app id not found
#python3 content+=$(python3 "${THIS_SCRIPT_DIR}/create_app.py")

#function to manage app version in AppStoreConnect
content+=$(python3 "${THIS_SCRIPT_DIR}/manage_version.py")

#function to update What's New field in AppStoreConnect
#python3 content+=$(python3 "${THIS_SCRIPT_DIR}/update_whatsnew.py")

if [ -z "${content}" ] ; then
	echo " [!] => Failed: No script (content) defined for execution!"
	exit 1
fi

if [ -z "${runner_bin}" ] ; then
	echo " [!] => Failed: No script executor defined!"
	exit 1
fi

function debug_echo {
	local msg="$1"
	if [[ "${is_debug}" == "yes" ]] ; then
		echo "${msg}"
	fi
}


debug_echo
debug_echo "==> Start"

if [ ! -z "${working_dir}" ] ; then
	debug_echo "==> Switching to working directory: ${working_dir}"
	cd "${working_dir}"
	if [ $? -ne 0 ] ; then
		echo " [!] Failed to switch to working directory: ${working_dir}"
		exit 1
	fi
fi

if [ ! -z "${script_file_path}" ] ; then
	debug_echo "==> Script (tmp) save path specified: ${script_file_path}"
	CONFIG_tmp_script_file_path="${script_file_path}"
fi

echo -n "${content}" > "${CONFIG_tmp_script_file_path}"

debug_echo
if [[ "$(basename "${runner_bin}")" == "bash" ]] ; then
	# bash syntax check
	${runner_bin} -n "${CONFIG_tmp_script_file_path}"
	if [ $? -ne 0 ] ; then
		echo " [!] Bash: Syntax Error!"
		rm "${CONFIG_tmp_script_file_path}"
		exit 1
	fi
fi
${runner_bin} "${CONFIG_tmp_script_file_path}"
script_result=$?

debug_echo
debug_echo "==> Script finished with exit code: ${script_result}"

rm "${CONFIG_tmp_script_file_path}"
exit ${script_result}
