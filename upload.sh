#!/bin/bash
# Uploads a specified WAR file to the specified environment.
# TODO add -r --redeploy to redeploy right after uploading

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/config.sh"

function main {
	if [[ "${#}" != "2" ]]
	then
		echo "2 parameters expected: environment WARfile"
		exit 1
	fi
	
	ENV="${1}"
	WAR="${2}"
	
	LOC=`getparam "${ENV}" "local"`
	if [[ "${LOC}" == "true" ]] 
	then
		echo "This command does not work on local environment."
		exit 1
	fi
	
	HOST=`getparam "${ENV}" "host"`
	USER=`getparam "${ENV}" "user"`
	
	scp "${WAR}" ${USER}@${HOST}:~
}

main "${@}"
exit 0
