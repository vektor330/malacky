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
SRC_DATA="${3}"
TGT_DATA="${4}"
P_USER="${5}"
P_GROUP="${6}"
P_UPLOADERS="${7}"
DB="${8}"
DB_OWNER="${9}"
DB_IMAGE="${10}"

# step 0 - check the old DB does not exist
DB_BACKUP="${DB}backup"
sudo -u postgres psql -l | grep "${DB_BACKUP}" > /dev/null

if [[ "${?}" == "0" ]]
then
	echo "DB backup ($DB_BACKUP) already exists - exiting."
	exit 1
fi

# step 1 - stop server
echo "Running step 1: stopping the server."
/etc/init.d/tomcat6 stop

# step 2 - move the data from source to target
echo "Running step 2: rsync'ing data from source (${SRC_DATA}) to target (${TGT_DATA})."
rsync -azv --delete "${HOST}":"${SRC_DATA}"/* "${TGT_DATA}"

# step 3 - backup old DB (rename it to a different name)
echo "Running step 3: backing up the old DB: ${DB} to ${DB_BACKUP}."
sudo -u postgres psql --single-transaction -c "ALTER DATABASE ${DB} RENAME TO ${DB_BACKUP}"

# step 4 - make sure the resources have correct owner, group and permissions
echo "Running step 4: setting up correct permissions."

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

# step 5 - create the DB from the image
DB_DUMP=`mktemp`
mv "${DB_IMAGE}" "${DB_DUMP}"
chown postgres "${DB_DUMP}"
echo "Running step 5: creating the DB $DB from the image (${DB_DUMP})."
sudo -u postgres psql --single-transaction -c "CREATE DATABASE ${DB} OWNER ${DB_OWNER};"
sudo -u postgres psql --single-transaction -d "${DB}" -c "CREATE LANGUAGE plpgsql;"
echo "applying the image..."
sudo -u postgres psql --single-transaction -d "${DB}" -e -f "${DB_DUMP}" > /dev/null
rm "${DB_DUMP}"

# step 6 - run server
echo "Running step 6: starting the server: NOPE."
#/etc/init.d/tomcat6 start

