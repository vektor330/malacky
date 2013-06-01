#!/bin/bash
# This script is meant to be executed on the target side!

if [[ $EUID -ne 0 ]]
then
	echo "This script must be run as root." 1>&2
	exit 1
fi

if [[ "${#}" != "10" ]]
then
	echo "10 parameters expected."
	exit 1
fi

USER="${1}"
HOST="${2}"
SRC="${USER}@${HOST}"
SRC_DATA="${3}"
TGT_DATA="${4}"
P_USER="${5}"
P_GROUP="${6}"
P_UPLOADERS="${7}"
DB="${8}"
DB_IMAGE="${9}"
SCHEMA="${10}"

# step 1 - SCP data from source to target
echo "Running step 1: SCP data from source to target."
SRC_TMP=`ssh "${SRC}" "mktemp -d"`
DEST_TMP=`mktemp -d`
ssh -t "${SRC}" "sudo cp -R '${SRC_DATA}' '${SRC_TMP}'; sudo chown -R '${USER}' '${SRC_TMP}'"
scp -r "${SRC}":"${SRC_TMP}" "${DEST_TMP}"
ssh "${SRC}" "rm -rf '${SRC_TMP}'"

# step 2 - stop server
echo "Running step 2: stopping the server."
/etc/init.d/tomcat6 stop

# step 2.5 - check the old backup does not exist
TGT_DATA_OLD="${TGT_DATA}-old"
if [[ -d "${TGT_DATA_OLD}" ]]
then
	echo "Data backup folder already exists - exiting."
	exit 1
fi

# step 3 - backup old data
echo "Running step 3: backing up the old data."
mv "${TGT_DATA}" "${TGT_DATA_OLD}"

# step 3.5 - check the old DB does not exist
DB_BACKUP="${DB}backup"
sudo -u postgres psql -l | grep "${DB_BACKUP}" > /dev/null

if [[ "${?}" == "0" ]]
then
	echo "DB Backup already exists - exiting."
	exit 1
fi

# step 4 - backup old DB (rename it to a different name)
echo "Running step 4: backing up the old DB."
sudo -u postgres psql --single-transaction -c "ALTER DATABASE ${DB} RENAME TO ${DB_BACKUP}"

# step 5 - move the new resources to their place
echo "Running step 5: moving the new data to their place."
mv "${DEST_TMP}" "${TGT_DATA}"

# step 5.5 - make sure the resources have correct owner, group and permissions
echo "Running step 5.5: setting up correct permissions."

chown "${P_USER}"."${P_GROUP}" "${TGT_DATA}"
chmod 777 "${TGT_DATA}"

chown -R tomcat6.tomcat6 "${TGT_DATA}/data" "${TGT_DATA}/thumbs"
chmod -R 640 "${TGT_DATA}/data" "${TGT_DATA}/thumbs"
chmod 770 "${TGT_DATA}/data" "${TGT_DATA}/thumbs"

chown -R tomcat6."${P_UPLOADERS}" "${TGT_DATA}/upload"
chown "${P_USER}"."${P_UPLOADERS}" "${TGT_DATA}/upload"
chmod -R 777 "${TGT_DATA}/upload"
chmod 770 "${TGT_DATA}/upload"
chmod g+s "${TGT_DATA}/upload"

# step 6 - create the DB from the image
echo "Running step 6: creating the DB from the image."
sudo -u postgres psql --single-transaction -c "CREATE DATABASE ${DB}"
sudo -u postgres psql -d "${DB}" --single-transaction -c "CREATE SCHEMA ${SCHEMA}"
sudo -u postgres psql -d "${DB}" --single-transaction -e -f "${DB_IMAGE}" > /dev/null

# step 7 - run server
echo "Running step 7: starting the server."
/etc/init.d/tomcat6 start
