#!/bin/bash
# Performs a dry run of a database upgrade using the specified SQL diff script
# on the specified environment.

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/conf/config.sh"
source "${DIR}/utils/utils.sh"
source "${DIR}/utils/db-utils.sh"

function main {
	if [[ "${#}" != "2" ]]
	then
		echo "2 parameters expected: {environment|dump.sql} diff.sql"
		exit 1
	fi
	
	# TODO move somehow to config
	WORK="${DIR}/work"
	mkdir -p "${WORK}"
	
	# set up parameters - we either get an environment and have to dump...
	if [[ `is_environment "${1}"` == "0" ]]
	then
		ENV="${1}"
		DUMP="${WORK}/${ENV}-dump.sql"
		
		echoerr "Will dump environment ${ENV} and save it to \"${DUMP}\"."
		
		# get the full DB image from the environment
		db_download_dump "${ENV}" "${DUMP}" "${PG_DUMP}"
		remove_bom "${DUMP}"
		sed -i ".bak" "/CREATE SCHEMA/d" "${DUMP}"
	else
		# ... or we get the dump itself
		ENV="unknown"
		DUMP="${1}"
		
		echoerr "Will use the existing dump \"${DUMP}\"."
		
		remove_bom "${DUMP}"
		sed -i ".bak" "/CREATE SCHEMA/d" "${DUMP}"
	fi

	DIFF="${2}"
	remove_bom "${DIFF}"
	
	FULL_LOG="${WORK}/${ENV}-full.log"
	DIFF_LOG="${WORK}/${ENV}-diff.log"
	
	DBHOST=`getparam "localhost" "dbhost"`
	PORT=`getparam "localhost" "dbport"`
	USER=`getparam "localhost" "dbuser"`
	USER_ADMIN=`getparam "localhost" "admin"`
	DB=`getparam "localhost" "dbtestdatabase"`
	SCHEMA=`getparam "localhost" "dbschema"`
	
	COMMON="-h ${DBHOST} -p ${PORT} -d ${DB} --no-password --single-transaction"
	
	echoerr "Will use the local test DB \"${DB}\", schema \"${SCHEMA}\"."
	
	# delete local test schema
	${PSQL} ${COMMON} -U ${USER_ADMIN} -c "DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE" &> /dev/null
	
	echoerr "Local schema cleaned."

	# create local test schema
	${PSQL} ${COMMON} -U ${USER_ADMIN} -c "CREATE SCHEMA ${SCHEMA} AUTHORIZATION ${USER}" &> /dev/null
	
	echoerr "Local schema re-created."

	# fill local test schema with data
	${PSQL} ${COMMON} -U ${USER} -e -f "${DUMP}" > "${FULL_LOG}"
	
	echoerr "Dump applied."

	# try to apply the diff	
	${PSQL} ${COMMON} -U ${USER} -e -f "${DIFF}" > "${DIFF_LOG}"
	
	echoerr "Finished applying the diff."
	
	# TODO report success / failure
}

main "${@}"
exit 0
