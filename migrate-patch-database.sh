#!/bin/bash
# This is the second step in the environment migration.
# Patches the specified DB dump file with the specified DB diff file. The 
# resulting dump is saved in the specified file.
# Takes three arguments - DB dump, DB diff and the resulting dump file.

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/conf/config.sh"
source "${DIR}/utils/utils.sh"
source "${DIR}/utils/db-utils.sh"

function main {
	if [[ "${#}" != "4" ]]
	then
		echo "4 parameters (env + 3 files) expected: originalenv dbdump dbdiff outputdump"
		exit 1
	fi
	
	ENV_ORIGINAL="${1}"
	DB_DUMP="${2}"
	DB_DIFF="${3}"
	OUT_DUMP="${4}"
	
	remove_bom "${DB_DUMP}"
	sed -i ".bak" "/CREATE SCHEMA/d" "${DB_DUMP}"
	remove_bom "${DB_DIFF}"
	
	HOST=`getparam "localhost" "host"`
	PORT=`getparam "localhost" "dbport"`
	USER=`getparam "localhost" "dbuser"`
	USER_ADMIN=`getparam "localhost" "admin"`
	DB=`getparam "localhost" "dbtestdatabase"`
	SCHEMA=`getparam "localhost" "dbschema"`
	
	COMMON="-h ${HOST} -p ${PORT} -d ${DB} --no-password --single-transaction"

	echo -n "Flushing temp DB..."
	
	# delete local test schema
	${PSQL} ${COMMON} -U ${USER_ADMIN} -c "DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE" &> /dev/null
	
	echo "done."

	echo -n "Creating DB..."
	
	# create local test schema
	${PSQL} ${COMMON} -U ${USER_ADMIN} -c "CREATE SCHEMA ${SCHEMA} AUTHORIZATION ${USER}" &> /dev/null

	echo "done."
	
	echo -n "Creating DB schema & data from the dump..."
	
	# fill local test schema with data
	${PSQL} ${COMMON} -U ${USER} -e -f ${DB_DUMP} &> /dev/null
	
	echo "done."
	
	# re-sync with the source
	echo "Re-syncing with the source..."
	
	# TODO move somehow to config
	WORK="${DIR}/work"
	mkdir -p "${WORK}"
	
	RESYNC_DIFF="${WORK}/migrate-resync-diff.sql"
	
	# TODO "test" should be parametrized
	"${DIR}/db-diff.sh" "test" "${ENV_ORIGINAL}" > "${RESYNC_DIFF}"
	
	echo "done."
	
	echo -n "Applying re-sync diff..."
	
	# try to apply the diff	
	${PSQL} ${COMMON} -U ${USER} -e -f ${RESYNC_DIFF} > /dev/null
	
	echo "done."

	echo -n "Applying diff..."
	
	# try to apply the diff	
	${PSQL} ${COMMON} -U ${USER} -e -f ${DB_DIFF} > /dev/null
	
	echo "done."

	
	echo -n "Dumping the patched image..."
	
	# dump the schema
	"${PG_DUMP}" \
	    	--host localhost \
	    	--port "${PORT}" \
	    	--username "${USER}" \
	    	--no-password  \
	    	--format plain \
	    	--create \
	    	--inserts \
	    	--no-tablespaces \
	    	--file "${OUT_DUMP}" \
	    	--schema "${SCHEMA}" "${DB}"
	    	
	echo "done."
}

main "${@}"
exit 0
