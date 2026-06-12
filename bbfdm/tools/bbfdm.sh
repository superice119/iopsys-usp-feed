#!/bin/bash

BBFDM_BASE_DM_PATH="usr/share/bbfdm"
BBFDM_INPUT_PATH="etc/bbfdm/micro_services"
INPUT_FILE="0"

MICRO_SERVICE=0
SCRIPT=0
DIAG=0
PLUGIN=0
DEST=""
VENDOR_EXTN=""
TOOLS="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SRC=""
EXTRA_DATA=""

while getopts ":mpsdtv:" opt; do
	case ${opt} in
	  m)
	  	MICRO_SERVICE=1
		;;
	  p)
	  	PLUGIN=1
		;;
	  s)
	  	SCRIPT=1
		;;
	  d)
	  	DIAG=1
		;;
	  t)
	  	INPUT_FILE=1
		;;
	  v)
	  	VENDOR_EXTN=${OPTARG}
		;;
	  ?)
	  	echo "Invalid option: ${OPTARG}"
		exit 1
		;;
	esac
done
shift $((OPTIND-1))

SRC="${1}"
shift
DEST="${1}"
shift
DATA="${1}"
shift
EXTRA_DATA="${1}"


install_bin() {
	if ! install -m0755 ${1} ${2}; then
		echo "Failed to install bin ${1} => ${2}"
		exit 1
	fi
}

install_dir() {
	if ! install -d -m0755 ${1}; then
		echo "Failed to create directory ${1}"
		exit 1
	fi
}

install_data() {
	if ! install -m0644 ${1} ${2}; then
		echo "Failed to install ${1} => ${2}"
		exit 1
	fi
}

# Installing datamodel
bbfdm_install_dm()
{
	local src dest minfile

	src="$1"
	dest="$2"
	minfile=""

	if [ -z "${src}" ] || [ -z "${dest}" ] || [ -z "${TOOLS}" ]; then
		echo "Invalid input option for install dm $@"
		exit 1
	fi

	if [ ! -f "${src}" ]; then
		echo "File $src does not exists..."
		exit 1
	fi

	if [ "${src##*.}" = "json" ]; then
		echo "Compacting BBFDM JSON file"
		minfile=$(mktemp)
		if ! jq -c 'del(..|.description?)' ${src} > ${minfile}; then
			echo "Compression of json input file (${src}) failed"
			rm "${minfile}"
			exit 1
		fi

		if [ -n "${VENDOR_EXTN}" ]; then
			sed -i "s/{BBF_VENDOR_PREFIX}/${VENDOR_EXTN}/g" ${minfile}
		fi

		src=${minfile}
		if dpkg -s python3-jsonschema >/dev/null 2>&1; then
			echo "Verifying bbfdm Datamodel JSON file"
			if ! ${TOOLS}/validate_plugins.py ${src}; then
				echo "Validation of the plugin failed ${src}"
				exit 1
			fi
		else
			echo "## Install python3-jsonschema to verify datamodel plugins"
		fi
	fi

	install_bin ${src} ${dest}

	if [ -f "${minfile}" ]; then
		rm ${minfile}
	fi
}

if [ -z "$SRC" ] || [ -z "${DEST}" ] ; then
	echo "# BBFDM Null value in src[${SRC}], dest[${DEST}]"
	exit 1
fi

if [ "${SCRIPT}" -eq "1" ]; then
	if [ "${DIAG}" -eq "1" ]; then
		install_dir ${DEST}/${BBFDM_BASE_DM_PATH}/scripts/bbf_diag
		install_bin ${SRC} ${DEST}/${BBFDM_BASE_DM_PATH}/scripts/bbf_diag/
	else
		install_dir ${DEST}/${BBFDM_BASE_DM_PATH}/scripts
		install_bin ${SRC} ${DEST}/${BBFDM_BASE_DM_PATH}/scripts/
	fi
	exit 0
fi

if [ "${INPUT_FILE}" -eq "1" ]; then

	tempfile=""
	if [ ! -f "${SRC}" ]; then
		echo "# Datamodel Input file ${SRC} not available"
		exit 1
	fi

	if ! cat ${SRC} |jq >/dev/null 2>&1; then
		echo "# Invalid datamodel json input file"
		exit 1
	fi

	service_name="$(cat ${SRC}|jq -r '.daemon.service_name')"
	if [ -z "${service_name}" ]; then
		echo "# service_name not defined in service json ...."
		exit 1
	fi

	tempfile=$(mktemp)
	cp ${SRC} ${tempfile}
	if [ -n "${VENDOR_EXTN}" ]; then
		sed -i "s/{BBF_VENDOR_PREFIX}/${VENDOR_EXTN}/g" ${tempfile}
	fi

	install_dir ${DEST}/etc/bbfdm/services
	install_data ${tempfile} ${DEST}/etc/bbfdm/services/${service_name}.json

	if [ -f "${tempfile}" ]; then
		rm ${tempfile}
	fi
	exit 0
fi

if [ "${MICRO_SERVICE}" -eq "1" ]; then
	if [ -z "${DATA}" ]; then
		echo "# service_name[${DATA}] not provided"
		exit 1
	fi

	if [ "${PLUGIN}" -ne "1" ]; then
		extn="$(basename ${SRC})"
		install_dir ${DEST}/${BBFDM_BASE_DM_PATH}/micro_services
		bbfdm_install_dm ${SRC} ${DEST}/${BBFDM_BASE_DM_PATH}/micro_services/${DATA}.${extn##*.}
	else
		install_dir ${DEST}/${BBFDM_BASE_DM_PATH}/micro_services/${DATA}
		bbfdm_install_dm ${SRC} ${DEST}/${BBFDM_BASE_DM_PATH}/micro_services/${DATA}/$(printf "%02d" ${EXTRA_DATA})$(basename ${SRC})
	fi
else
	if [ "${PLUGIN}" -eq "1" ]; then
		echo "# WARNING: BBFDM_INSTALL_CORE_PLUGIN macro will be deprecated soon. Please use BBFDM_INSTALL_MS_PLUGIN macro instead, specifying 'core' as micro-service name #"
		priority="${DATA:-0}"
		install_dir ${DEST}/${BBFDM_BASE_DM_PATH}/micro_services/core

		if [ "${priority}" -gt "0" ]; then
			# install with priority if defined
			bbfdm_install_dm ${SRC} ${DEST}/${BBFDM_BASE_DM_PATH}/micro_services/core/${priority}_$(basename ${SRC})
		elif [ "${priority}" -eq "0" ]; then
			bbfdm_install_dm ${SRC} ${DEST}/${BBFDM_BASE_DM_PATH}/micro_services/core/$(basename ${SRC})
		else
			echo "# Priority should be an unsigned integer"
			exit 1
		fi
	fi
fi

