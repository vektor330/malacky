PG_DUMP="/Applications/MacPorts/pgAdmin3.app/Contents/SharedSupport/pg_dump"
PSQL="/opt/local/lib/postgresql84/bin/psql"

function getparam {
	cat "${DIR}/environments.conf" | grep "${1}.${2}" | cut -d "=" -f 2 | tr -d "[[:space:]]"
}
