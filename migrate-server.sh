#!/bin/bash
# This is the final step in the environment migration.

# full path to this script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/conf/config.sh"
source "${DIR}/utils/utils.sh"
source "${DIR}/utils/db-utils.sh"

function main {
	if [[ "${#}" != "3" ]]
	then
		echo "3 parameters expected: source target dbdump"
		echo "Make sure the backup DB is deleted. Make sure not clients are connected to the DB (for example by restarting the DB server)."
		exit 1
	fi
	
	ENV_SRC="${1}"
	ENV_TGT="${2}"
	
	# TODO check the environment specifications were correct
	
	DB_DUMP="${3}"
	DB_DUMP_FILE=`basename "${DB_DUMP}"`
	
	TGT_USER=`getparam "${ENV_TGT}" "user"`
	TGT_HOST=`getparam "${ENV_TGT}" "host"`
	TGT="${TGT_USER}"@"${TGT_HOST}"
	
	# push the DB dump to the target
	TMP=`ssh "${TGT}" "mktemp -d"`
	scp -C "${DB_DUMP}" "${TGT}":"${TMP}"
	
	SRC_USER=`getparam "${ENV_SRC}" "user"`
	SRC_HOST=`getparam "${ENV_SRC}" "host"`
	SRC_DATA=`getparam "${ENV_SRC}" "datafolder"`
	TGT_DATA=`getparam "${ENV_TGT}" "datafolder"`
	TGT_P_USER=`getparam "${ENV_TGT}" "permuser"`
	TGT_P_GROUP=`getparam "${ENV_TGT}" "permgroup"`
	TGT_P_UPLOADERS=`getparam "${ENV_TGT}" "permuploaders"`
	TGT_DB=`getparam "${ENV_TGT}" "dbdatabase"`
	TGT_DB_OWNER=`getparam "${ENV_TGT}" "dbuser"`
	
	# push the script to the target
	scp migrate-target-side.sh "${TGT}":"${TMP}"
	
	# run the script on the target
	ssh -t "${TGT}" sudo "${TMP}/migrate-target-side.sh" "${SRC_USER}" "${SRC_HOST}" "${SRC_DATA}" "${TGT_DATA}" "${TGT_P_USER}" "${TGT_P_GROUP}" "${TGT_P_UPLOADERS}" "${TGT_DB}" "${TGT_DB_OWNER}" "${TMP}/${DB_DUMP_FILE}"
	
	# cleanup temp on target
	ssh "${TGT}" rm -rf "${TMP}"
}

main "${@}"
exit 0
