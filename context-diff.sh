#!/bin/bash
# diffs the context.xml of the 2 specified (old, new) environments

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/config.sh"

function getcontext {
	local _ENV="${1}"
	local _FILE="${2}"
	local HOST=`getparam "${_ENV}" "host"`
	local USER=`getparam "${_ENV}" "user"`
	local DNS=`getparam "${_ENV}" "dns"`
	ssh ${USER}@${HOST} cat /etc/tomcat6/Catalina/${DNS}/context.xml.default > "${_FILE}" 
}

function main {
	if [[ "${#}" != "2" ]]
	then
		echo "2 parameters expected: environment1 environment 2"
		echo "For the purpose of the diff, environment1 is considered the old one, environment2 the new one."
		exit 1
	fi
	
	ENV1="${1}"
	ENV2="${2}"
	
	WORK="${DIR}/work"
	
	FILE1="${WORK}/${ENV1}.context.xml"
	FILE2="${WORK}/${ENV2}.context.xml"
	
	getcontext "${ENV1}" "${FILE1}"
	getcontext "${ENV2}" "${FILE2}"
	
	diff "${FILE1}" "${FILE2}"
}

main "${@}"
exit 0
