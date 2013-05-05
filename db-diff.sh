#!/bin/bash
# Diffs the DB schema of the 2 specified (old, new) environments.

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
    DIFF="${DIR}/apgdiff/apgdiff-2.3.jar"

    OLD_SQL="${WORK}/${ENV1}-schema.sql"
    NEW_SQL="${WORK}/${ENV2}-schema.sql"
    
    db_download_schema "${ENV1}" "${OLD_SQL}" "${PG_DUMP}"
    db_download_schema "${ENV2}" "${NEW_SQL}" "${PG_DUMP}"
    
    if [[ ! -f "${OLD_SQL}" || ! -f "${NEW_SQL}" ]]
    then
    	    echo "Getting one or both of schemas failed."
    	    exit 1
    fi
    
    java -jar "${DIFF}" "${OLD_SQL}" "${NEW_SQL}"
}

main "${@}"
exit 0