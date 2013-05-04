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
	
	# get the full DB image from the environment
	db_download_dump "${ENV}" "${DUMP}" "${PG_DUMP}"
	remove_bom "${DUMP}"
	sed -i ".bak" "/CREATE SCHEMA/d" "${DUMP}"
	remove_bom "${DIFF}"
	
	FULL_LOG="${WORK}/${ENV}-full.log"
	DIFF_LOG="${WORK}/${ENV}-diff.log"
	
	HOST=`getparam "localhost" "host"`
	PORT=`getparam "localhost" "dbport"`
	USER=`getparam "localhost" "dbuser"`
	USER_ADMIN=`getparam "localhost" "admin"`
	DB=`getparam "localhost" "dbtestdatabase"`
	SCHEMA=`getparam "localhost" "dbschema"`
	
	COMMON="-h ${HOST} -p ${PORT} -d ${DB} --no-password --single-transaction"
	
	# delete local test schema
	${PSQL} ${COMMON} -U ${USER_ADMIN} -c "DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE" &> /dev/null

	# create local test schema
	${PSQL} ${COMMON} -U ${USER_ADMIN} -c "CREATE SCHEMA ${SCHEMA} AUTHORIZATION ${USER}" &> /dev/null

	# fill local test schema with data
	${PSQL} ${COMMON} -U ${USER} -e -f ${DUMP} > ${FULL_LOG}

	# try to apply the diff	
	${PSQL} ${COMMON} -U ${USER} -e -f ${DIFF} > ${DIFF_LOG}
	
	# TODO report success / failure
}

main "${@}"
exit 0
