#!/bin/bash
# Runs the redeploy script on the specified environment

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/config.sh"
source "${DIR}/utils.sh"

function main {
	if [[ "${#}" != "1" ]]
	then
		echo "1 parameter expected: environment"
		exit 1
	fi
	
	ENV="${1}"
	
	REMOTE=`getparam "${ENV}" "remote"`
	if [[ "${REMOTE}" == "false" ]] 
	then
		echo "This command does not work on local environment."
		exit 1
	fi
	
	HOST=`getparam "${ENV}" "host"`
	USER=`getparam "${ENV}" "user"`
	
	ssh -t ${USER}@${HOST} "sudo ./redeploy.sh"
}

main "${@}"
exit 0
