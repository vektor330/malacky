#!/bin/bash
# Diffs the master tables in DBs of the 2 specified (old, new) environments. 
# The result is written to the stdout.

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/conf/config.sh"
source "${DIR}/utils/utils.sh"
source "${DIR}/utils/db-utils.sh"

function main {
	if [[ "${#}" != "2" ]]
	then
		echo "2 parameters expected: oldenvironment newenvironment"
		exit 1
	fi
	
	ENV1="${1}"
	ENV2="${2}"
	
	# TODO check the environment specifications were correct
	
	# TODO move somehow to config
	WORK="${DIR}/work"
	mkdir -p "${WORK}"
	
	OLD_SQL="${WORK}/${ENV1}-dump.sql"
	NEW_SQL="${WORK}/${ENV2}-dump.sql"
	
	db_download_dump "${ENV1}" "${OLD_SQL}" "${PG_DUMP}"
	db_download_dump "${ENV2}" "${NEW_SQL}" "${PG_DUMP}"
	
	if [[ ! -f "${OLD_SQL}" || ! -f "${NEW_SQL}" ]]
	then
		echo "Getting one or both of schemas failed."
		exit 1
	fi
	
	cat "${OLD_SQL}" | grep 'INSERT INTO "C_' > "${OLD_SQL}.masters"
	cat "${NEW_SQL}" | grep 'INSERT INTO "C_' > "${NEW_SQL}.masters"
	
	diff "${OLD_SQL}.masters" "${NEW_SQL}.masters"
}

main "${@}"
exit 0