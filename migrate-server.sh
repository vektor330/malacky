#!/bin/bash
# This is the final step in the environment migration.

function main {
	if [[ "${#}" != "3" ]]
	then
		echo "3 parameters expected: source target dbdump"
		exit 1
	fi
	
	ENV_SRC="${1}"
	ENV_TGT="${2}"
	
	# TODO check the environment specifications were correct
	
	DB_DUMP="${3}"
	
	TGT_USER=`getparam "${ENV_TGT}" "user"`
	TGT_HOST=`getparam "${ENV_TGT}" "host"`
	TGT="${TGT_USER}"@"${TGT_HOST}"
	
	# push the DB dump to the target
	TMP=`ssh "${TGT}" "mktemp -d"`
	scp "${DB_DUMP}" "${TGT}":"${TMP}"
	
	SRC_USER=`getparam "${ENV_SRC}" "user"`
	SRC_HOST=`getparam "${ENV_SRC}" "host"`
	SRC_DATA=`getparam "${ENV_SRC}" "datafolder"`
	TGT_DATA=`getparam "${ENV_TGT}" "datafolder"`
	TGT_P_USER=`getparam "${ENV_TGT}" "permuser"`
	TGT_P_GROUP=`getparam "${ENV_TGT}" "permgroup"`
	TGT_P_UPLOADERS=`getparam "${ENV_TGT}" "permuploaders"`
	TGT_DB=`getparam "${ENV_TGT}" "dbdatabase"`
	TGT_DB_SCHEMA=`getparam "${ENV_TGT}" "dbschema"`
	
	# TODO matej Run on target
	echo migrate-target-side.sh "${SRC_USER}" "${SRC_HOST}" "${SRC_DATA}" "${TGT_DATA}" "${TGT_P_USER}" "${TGT_P_GROUP}" "${TGT_P_UPLOADERS}" "${TGT_DB}" "${TGT_DB_SCHEMA}" "${TMP}/${DB_DUMP}"
}

main "${@}"
exit 0
