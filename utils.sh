# Takes 2 arguments, environment name and "property key".
# Returns the value of the property of that environment, from environments.conf.
function getparam {
	# TODO DIR needs to be set as argument too!
	local _ENV="${1}"
	local _KEY="${2}"
	cat "${DIR}/environments.conf" | grep "${_ENV}.${_KEY}" | cut -d "=" -f 2 | tr -d "[[:space:]]"
}

# Takes 1 argument, file name.
# Removes the BOM (byte order marker) from the specified file.
function removebom {
	local _FILE="${1}"
	if [[ "$(file "${_FILE}")" == *UTF-8\ Unicode\ \(with\ BOM\)* ]]
	then
		echo "Removing UTF-8 BOM for ${_FILE}"
		tail -c +4 "${_FILE}" > "/tmp/killbom" || { echo "Failed to tail to /tmp/killbom"; exit 1; }
		mv "/tmp/killbom" "${_FILE}"
	fi
}

# Takes 6 parameters: path to the pg_dump tool, port of the DB (host is assumed 
# to be localhost - remote hosts have to be SSH tunnelled), database user name, 
# database name and schema and finally file name.
# Connects to the database and downloads its schema into the specified file.
function db_get_schema {
	local _PG_DUMP="${1}"
	local _PORT="${2}"
	local _USER="${3}"
	local _DATABASE="${4}"
	local _SCHEMA="${5}"
	local _FILE="${6}"
	
	"${_PG_DUMP}" \
	    	--host localhost \
	    	--port "${_PORT}" \
	    	--username "${_USER}" \
	    	--no-password  \
	    	--format plain \
	    	--schema-only \
	    	--no-owner \
	    	--create \
	    	--inserts \
	    	--no-privileges \
	    	--no-tablespaces \
	    	--no-unlogged-table-data \
	    	--file "${_FILE}" \
	    	--schema "${_SCHEMA}" "${_DATABASE}"
}

# Takes 6 parameters: path to the pg_dump tool, port of the DB (host is assumed 
# to be localhost - remote hosts have to be SSH tunnelled), database user name, 
# database name and schema and finally file name.
# Connects to the database and dumps it into the specified file.
function db_get_dump {
	local _PG_DUMP="${1}"
	local _PORT="${2}"
	local _USER="${3}"
	local _DATABASE="${4}"
	local _SCHEMA="${5}"
	local _FILE="${6}"
	
	"${_PG_DUMP}" \
	    	--host localhost \
	    	--port "${_PORT}" \
	    	--username "${_USER}" \
	    	--no-password  \
	    	--format plain \
	    	--no-owner \
	    	--create \
	    	--inserts \
	    	--no-privileges \
	    	--no-tablespaces \
	    	--no-unlogged-table-data \
	    	--file "${_FILE}" \
	    	--schema "${_SCHEMA}" "${_DATABASE}"
}

function db_download {
	local _COMMAND="${1}"
	local _ENV="${2}"
	local _FILE="${3}"
	local _PG_DUMP="${4}"

	local HOST=`getparam "${_ENV}" "host"`
	local DB_PORT=`getparam "${_ENV}" "dbport"`
	local LOCAL_PORT=`getparam "${_ENV}" "localport"`
	local USER=`getparam "${_ENV}" "user"`
	local DB_USER=`getparam "${_ENV}" "dbuser"`
	local DB_SCHEMA=`getparam "${_ENV}" "dbschema"`
	local DB_DATABASE=`getparam "${_ENV}" "dbdatabase"`
	local REMOTE=`getparam "${_ENV}" "remote"`
	
	if [[ "${REMOTE}" == "false" ]]
	then
		# get schema directly
		echo -n "Dumping local DB..."
    	    
		"${_COMMAND}" "${_PG_DUMP}" "${DB_PORT}" "${DB_USER}" "${DB_DATABASE}" "${DB_SCHEMA}" "${_FILE}"
    	    
		echo "done."
	else
		# open SSH tunnel
		echo -n "Opening SSH tunnel..."
		ssh -fnTN -L ${LOCAL_PORT}:localhost:${DB_PORT} ${USER}@${HOST} &
		sleep 3
		echo "done."
    	    
		echo -n "Dumping remote DB..."
    	    
		"${_COMMAND}" "${_PG_DUMP}" "${LOCAL_PORT}" "${DB_USER}" "${DB_DATABASE}" "${DB_SCHEMA}" "${_FILE}"
    	    
		echo "done."
	    
		echo -n "Closing tunnel..."
		# close SSH tunnel
		PID=$(pgrep -f "${LOCAL_PORT}:localhost:${DB_PORT}")
		kill "${PID}"
		echo "done."
	fi
}

# Takes 3 parameters: environment, file name and pg_dump path.
# Saves the DB schema of the specified environment to the specified file.
function db_download_schema {
	    local _ENV="${1}"
	    local _FILE="${2}"
	    local _PG_DUMP="${3}"
	    db_download "db_get_schema" "${_ENV}" "${_FILE}" "${_PG_DUMP}"
}

# Takes 3 parameters: environment, file name and pg_dump path.
# Saves the DB dump of the specified environment to the specified file.
function db_download_dump {
	    local _ENV="${1}"
	    local _FILE="${2}"
	    local _PG_DUMP="${3}"
	    db_download "db_get_dump" "${_ENV}" "${_FILE}" "${_PG_DUMP}"
}
