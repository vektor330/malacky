# Takes 6 parameters: path to the pg_dump tool, port of the DB (host is assumed 
# to be localhost - remote hosts have to be SSH tunnelled), database user name, 
# database name and schema and finally file name.
# Connects to the database and downloads its schema into the specified file.
function __db_get_schema {
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
	    	--create \
	    	--inserts \
	    	--no-privileges \
	    	--no-tablespaces \
	    	--file "${_FILE}" \
	    	--schema "${_SCHEMA}" "${_DATABASE}"
}

# Takes 6 parameters: path to the pg_dump tool, port of the DB (host is assumed 
# to be localhost - remote hosts have to be SSH tunnelled), database user name, 
# database name and schema and finally file name.
# Connects to the database and dumps it into the specified file.
function __db_get_dump {
	local _PG_DUMP="${1}"
	local _PORT="${2}"
	local _USER="${3}"
	local _DATABASE="${4}"
	local _SCHEMA="${5}"
	local _FILE="${6}"
	
	EXCLUDED=`for i in $(echo ${EXCLUDE_TABLE} | tr "," "\n"); do echo -n " --exclude-table $i"; done;`
	
	"${_PG_DUMP}" \
	    	--host localhost \
	    	--port "${_PORT}" \
	    	--username "${_USER}" \
	    	--no-password  \
	    	--format plain \
	    	--create \
	    	--inserts \
	    	--no-privileges \
	    	--no-tablespaces \
	    	${EXCLUDED} --file "${_FILE}" \
	    	--schema "${_SCHEMA}" "${_DATABASE}"
}

# Takes 6 parameters: path to the pg_dump tool, port of the DB (host is assumed 
# to be localhost - remote hosts have to be SSH tunnelled), database user name, 
# database name and schema and finally file name.
# Connects to the database and dumps it into the specified file.
function __db_get_masters {
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
	    	--create \
	    	--inserts \
	    	--no-privileges \
	    	--no-tablespaces \
	    	--table "${_SCHEMA}.\"${MASTER_TABLE_PREFIX}\"*" \
	    	--file "${_FILE}" \
	    	--schema "${_SCHEMA}" "${_DATABASE}"
}

function __db_download {
	local _COMMAND="${1}"
	local _ENV="${2}"
	local _FILE="${3}"
	local _PG_DUMP="${4}"

	local DB_HOST=`getparam "${_ENV}" "dbhost"`
	local DB_PORT=`getparam "${_ENV}" "dbport"`
	local LOCAL_PORT=`getparam "${_ENV}" "localport"`
	local DB_SSH_USER=`getparam "${_ENV}" "dbsshuser"`
	local DB_USER=`getparam "${_ENV}" "dbuser"`
	local DB_DATABASE=`getparam "${_ENV}" "dbdatabase"`
	local DB_SCHEMA=`getparam "${_ENV}" "dbschema"`
	local REMOTE=`getparam "${_ENV}" "remote"`
	
	if [[ "${REMOTE}" == "false" ]]
	then
		# get schema directly
		echoerr -n "Dumping local DB..."
    	    
		"${_COMMAND}" "${_PG_DUMP}" "${DB_PORT}" "${DB_USER}" "${DB_DATABASE}" "${DB_SCHEMA}" "${_FILE}"
    	    
		echoerr "done."
	else
		# open SSH tunnel
		echoerr -n "Opening SSH tunnel..."
		ssh -fnTN -L ${LOCAL_PORT}:localhost:${DB_PORT} ${DB_SSH_USER}@${DB_HOST} &
		sleep 5
		echoerr "done."
    	    
		echoerr -n "Dumping remote DB..."
    	    
		"${_COMMAND}" "${_PG_DUMP}" "${LOCAL_PORT}" "${DB_USER}" "${DB_DATABASE}" "${DB_SCHEMA}" "${_FILE}"
    	    
		echoerr "done."
	    
		echoerr -n "Closing tunnel..."
		# close SSH tunnel
		PID=$(pgrep -f "${LOCAL_PORT}:localhost:${DB_PORT}")
		kill "${PID}"
		echoerr "done."
	fi
}

# Takes 3 parameters: environment, file name and pg_dump path.
# Saves the DB schema of the specified environment to the specified file.
function db_download_schema {
	    local _ENV="${1}"
	    local _FILE="${2}"
	    local _PG_DUMP="${3}"
	    __db_download "__db_get_schema" "${_ENV}" "${_FILE}" "${_PG_DUMP}"
}

# Takes 3 parameters: environment, file name and pg_dump path.
# Saves the DB dump of the specified environment to the specified file.
function db_download_dump {
	    local _ENV="${1}"
	    local _FILE="${2}"
	    local _PG_DUMP="${3}"
	    __db_download "__db_get_dump" "${_ENV}" "${_FILE}" "${_PG_DUMP}"
}

# Takes 3 parameters: environment, file name and pg_dump path.
# Saves the DB dump of the specified environment to the specified file.
function db_download_masters {
	    local _ENV="${1}"
	    local _FILE="${2}"
	    local _PG_DUMP="${3}"
	    __db_download "__db_get_masters" "${_ENV}" "${_FILE}" "${_PG_DUMP}"
}
