#!/bin/bash
# controls a Tomcat instance on the specified environment with {start|stop|restart}

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/config.sh"

function main {
	if [[ "${#}" != "2" ]]
	then
		echo "2 parameters expected: environment {start|stop|restart}"
		exit 1
	fi
	
	ENV="${1}"
	COMMAND="${2}"
	
	if [[ "${COMMAND}" != "start" && "${COMMAND}" != "stop" && "${COMMAND}" != "restart" ]]
	then
		echo "Unknown command: ${COMMAND}"
		exit 1
	fi
	
	local HOST=`getparam "${ENV}" "host"`
	local USER=`getparam "${ENV}" "user"`
	ssh -t ${USER}@${HOST} "sudo /etc/init.d/tomcat6 ${COMMAND}"
}

main "${@}"
exit 0