#!/bin/bash
# diffs the 2 specified (old, new) environments

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/config.sh"

function getschema {
    local _ENV="${1}"
    local _WORK="${2}"
    local _PG_DUMP="${3}"

    local HOST=`getparam "${_ENV}" "host"`
    local PORT=`getparam "${_ENV}" "port"`
    local LOCAL_PORT=`getparam "${_ENV}" "localport"`
    local USER=`getparam "${_ENV}" "user"`
    local DB_USER=`getparam "${_ENV}" "dbuser"`
    local DB_SCHEMA=`getparam "${_ENV}" "dbschema"`
    local DB_DATABASE=`getparam "${_ENV}" "dbdatabase"`
    
    if [[ "${HOST}" == "localhost" ]]
    then
    	    # get schema directly
    	    echo -n "Dumping local DB schema..."
    	    
    	    "${_PG_DUMP}" \
	    	--host localhost \
	    	--port "${PORT}" \
	    	--username "${DB_USER}" \
	    	--no-password  \
	    	--format plain \
	    	--schema-only \
	    	--no-owner \
	    	--create \
	    	--inserts \
	    	--no-privileges \
	    	--no-tablespaces \
	    	--no-unlogged-table-data \
	    	--file "${_WORK}/${_ENV}.sql" \
	    	--schema "${DB_SCHEMA}" "${DB_DATABASE}"
	    
	    echo "done."
    else

    	    # open SSH tunnel
    	    echo -n "Opening SSH tunnel..."
    	    ssh -fnTN -L ${LOCAL_PORT}:localhost:${PORT} ${USER}@${HOST} &
    	    sleep 3
    	    echo "done."
    	    
    	    echo -n "Dumping remote DB schema..."
    	    
    	    "${_PG_DUMP}" \
	    	--host localhost \
	    	--port "${LOCAL_PORT}" \
	    	--username "${DB_USER}" \
	    	--no-password  \
	    	--format plain \
	    	--schema-only \
	    	--no-owner \
	    	--create \
	    	--inserts \
	    	--no-privileges \
	    	--no-tablespaces \
	    	--no-unlogged-table-data \
	    	--file "${_WORK}/${_ENV}.sql" \
	    	--schema "${DB_SCHEMA}" "${DB_DATABASE}"
   
	    echo "done."
	    
	    echo -n "Closing tunnel..."
	    # close SSH tunnel
	    PID=$(pgrep -f "${LOCAL_PORT}:localhost:${DB_PORT}")
	    kill "${PID}"
	    echo "done."
	fi
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
    DIFF="${DIR}/apgdiff/apgdiff-2.3.jar"

    mkdir -p "${WORK}"
    
    getschema "${ENV1}" "${WORK}" "${PG_DUMP}"
    getschema "${ENV2}" "${WORK}" "${PG_DUMP}"
    
    OLD_SQL="${WORK}/${ENV1}.sql"
    NEW_SQL="${WORK}/${ENV2}.sql"
    
    if [[ ! -f "${OLD_SQL}" || ! -f "${NEW_SQL}" ]]
    then
    	    echo "Getting one or both of schemas failed."
    	    exit 1
    fi
    
    java -jar "${DIFF}" "${OLD_SQL}" "${NEW_SQL}"
}

main "${@}"
exit 0