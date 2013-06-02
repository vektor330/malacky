# Takes 2 arguments, environment name and "property key".
# Returns the value of the property of that environment, from environments.conf.
function getparam {
	# TODO DIR needs to be set as argument too!
	local _ENV="${1}"
	local _KEY="${2}"
	# TODO this grep has SERIOUS problems with prefix-ness!
	cat "${DIR}/conf/environments.conf" | grep "${_ENV}.${_KEY}" | cut -d "=" -f 2 | tr -d "[[:space:]]"
}

# The same as echo, but writes on the standard error.
function echoerr {
	echo "${@}" 1>&2
}

# Takes 1 argument, file name.
# Removes the BOM (byte order marker) from the specified file.
function remove_bom {
	local _FILE="${1}"
	if [[ "$(file "${_FILE}")" == *UTF-8\ Unicode\ \(with\ BOM\)* ]]
	then
		echoerr "Removing UTF-8 BOM for ${_FILE}"
		tail -c +4 "${_FILE}" > "/tmp/killbom" || { echoerr "Failed to tail to /tmp/killbom"; exit 1; }
		mv "/tmp/killbom" "${_FILE}"
	fi
}

# Checks if the argument is a valid environment name, as described in the 
# environment config file.
function is_environment {
	local _ENV="${1}"
	# TODO DIR needs to be a parameter, too
	cat "${DIR}/conf/environments.conf" | grep -v "#" | cut -d "." -f 1 | sort | uniq | grep "." | grep -q "${_ENV}"
	echo ${?}
}
