#!/bin/bash
# Performs a dry run of a database upgrade using the specified SQL diff script
# on the specified environment.

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/config.sh"
source "${DIR}/utils.sh"

function main {
	if [[ "${#}" != "2" ]]
	then
		echo "2 parameters expected: environment diff.sql"
		exit 1
	fi
	
	ENV="${1}"
	DIFF="${2}"
	
	# TODO move somehow to config
	WORK="${DIR}/work"
	mkdir -p "${WORK}"
	
	DUMP="${WORK}/${ENV}-dump.sql"
	
	db_download_dump "${ENV}" "${DUMP}" "${PG_DUMP}"
	
	# TODO create local test DB
	
	# TODO try to apply the diff
	
	# TODO report success / failure
}

main "${@}"
exit 0
