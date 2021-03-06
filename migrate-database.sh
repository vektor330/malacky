#!/bin/bash
# This is the second step in the environment migration.
# Prepares the database for the migration.
# First it downloads the full image of the source DB.
# Second it prepares the diff between the source and target DB schemas.
# At this point the script finishes and waits for the user to check the diff.
# Takes two arguments - source and target environment.

# TODO migration scripts should be in sub-folder - but then the utils script fails loading configuration...

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/conf/config.sh"
source "${DIR}/utils/utils.sh"
source "${DIR}/utils/db-utils.sh"

function main {
	if [[ "${#}" != "2" ]]
	then
		echo "2 parameters (environments) expected: source target"
		exit 1
	fi
	
	ENV_SRC="${1}"
	ENV_TGT="${2}"
	
	# TODO move somehow to config
	WORK="${DIR}/work"
	mkdir -p "${WORK}"
	
	SRC_DUMP="${WORK}/migrate-src-dump.sql"
	DB_DIFF="${WORK}/migrate-diff.sql"
	
	# step 1 - dump the source DB
	db_download_dump "${ENV_SRC}" "${SRC_DUMP}" "${PG_DUMP}"
	
	# step 2 - create the DB diff
	"${DIR}/db-diff.sh" "${ENV_SRC}" "${ENV_TGT}" > "${DB_DIFF}"
	
	# step 3 - append the patch to the DB diff
	echo "" >> "${DB_DIFF}"
	echo "-- *** patch.sql inserted below this line ***" >> "${DB_DIFF}"
	echo "" >> "${DB_DIFF}"
	
	cat "${DIR}/conf/patch.sql" >> "${DB_DIFF}"
	
	echo "DB dump written to '${SRC_DUMP}.'"
	echo "DB diff written to '${DB_DIFF}'."
	echo "Please verify the diff (try-upgrade) and continue with the next step of the migration (migrate-patch-database)."
}

main "${@}"
exit 0
