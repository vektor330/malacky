PG_DUMP="/Applications/MacPorts/pgAdmin3.app/Contents/SharedSupport/pg_dump"
PSQL="/opt/local/lib/postgresql84/bin/psql"

# Takes 2 arguments, environment name and "property key".
# Returns the value of the property of that environment, from environments.conf.
function getparam {
	cat "${DIR}/environments.conf" | grep "${1}.${2}" | cut -d "=" -f 2 | tr -d "[[:space:]]"
}

