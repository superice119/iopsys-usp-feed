#!/bin/sh

CTRUST_RESET_FILE="/etc/obuspa/ctrust_reset"
VENDOR_PREFIX_FILE="/etc/obuspa/vendor_prefix"
FW_DEFAULT_ROLE_DIR="/etc/users/roles"
SECURE_ROLES=""

CTRUST_RESET_FILE_TEMP="/tmp/obuspa/ctrust_reset"

mkdir -p /tmp/obuspa/

# include jshn.sh
if [ -f "/usr/local/share/libubox/jshn.sh" ]; then
	. /usr/local/share/libubox/jshn.sh
else
	. /usr/share/libubox/jshn.sh
fi

db_add()
{
	local param value

	param="${1}"
	shift
	value="$*"

	if [ -n "${param}" ] && [ -n "${value}" ]; then
		echo "${param} \"${value}\"">>${CTRUST_RESET_FILE_TEMP}
	else
		echo >>${CTRUST_RESET_FILE_TEMP}
	fi
}

get_param_permission()
{
	local input rinst pinst path prefix
	local pperm operm cperm iperm

	pperm="----"
	operm="----"
	cperm="----"
	iperm="----"

	path="${1}"
	shift
	rinst="${1}"
	shift
	pinst="${1}"
	shift
	input="${@}"

	for p in ${input}; do
		case ${p} in
		PERMIT_GET)
			pperm="r${pperm:1:4}"
		;;
		PERMIT_SET)
			pperm="${pperm:0:1}w${pperm:2:4}"
		;;
		PERMIT_SUBS_VAL_CHANGE)
			pperm="${pperm:0:3}n"
		;;
		PERMIT_OBJ_INFO)
			operm="r${operm:1:4}"
		;;
		PERMIT_ADD)
			operm="${operm:0:1}w${operm:2:4}"
		;;
		PERMIT_SUBS_OBJ_ADD)
			operm="${operm:0:3}n"
		;;
		PERMIT_GET_INST)
			iperm="r${iperm:1:4}"
		;;
		PERMIT_DEL)
			iperm="${iperm:0:1}w${iperm:2:4}"
		;;
		PERMIT_SUBS_OBJ_DEL)
			iperm="${iperm:0:3}n"
		;;
		PERMIT_CMD_INFO)
			cperm="r${cperm:1:4}"
		;;
		PERMIT_OPER)
			cperm="${cperm:0:2}x${cperm:3:4}"
		;;
		PERMIT_SUBS_EVT_OPER_COMP)
			cperm="${cperm:0:3}n"
		;;
		PERMIT_NONE)
			pperm="----"
			iperm="----"
			cperm="----"
			operm="----"
		;;
		PERMIT_ALL)
			pperm="rw-n"
			iperm="rw-n"
			operm="rw-n"
			cperm="r-xn"
		;;
		esac
	done

	if [ -f "${VENDOR_PREFIX_FILE}" ]; then
		prefix="$(cat ${VENDOR_PREFIX_FILE})"
	else
		prefix="X_IOPSYS_XX_"
	fi

	path="${path//\{i\}/*}"
	path="${path//\{BBF_VENDOR_PREFIX\}/${prefix}}"

	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Permission.${pinst}.Alias cpe-${pinst}
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Permission.${pinst}.Enable 1
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Permission.${pinst}.Order ${pinst}
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Permission.${pinst}.Targets ${path}
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Permission.${pinst}.Param ${pperm}
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Permission.${pinst}.Obj ${operm}
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Permission.${pinst}.InstantiatedObj ${iperm}
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Permission.${pinst}.CommandEvent ${cperm}
}

configure_permission()
{
	local obj inst name rinst

	obj="${1}"
	inst="${2}"
	name="${3}"
	rinst="${4}"

	if [ -z "${inst}" ]; then
		return 0
	fi

	json_select ${inst}

	json_get_var path object
	json_get_values perm perm

	get_param_permission "${path}" "${rinst}" "${inst}" "${perm}"
	db_add

	json_select ..
}


configure_roles()
{
	local rinst rname is_secure

	if [ "$#" -ne 2 ]; then
	    echo "Illegal number of parameters"
	    exit 1
	fi

	json_select $2
	json_get_var rname name
	json_get_var is_secure secure_role

	if [ "${rname}" = "full_access" ]; then
		rinst=1
	elif [ "${rname}" = "Untrusted" ]; then
		rinst=2
	else
		rinst="$2"
	fi

	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Alias cpe-${rinst}
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Enable 1
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Name ${rname}

	if [ "${is_secure}" = "1" ] || [ "${is_secure}" = "true" ]; then
		if [ -z "${SECURE_ROLES}" ]; then
			SECURE_ROLES="Device.LocalAgent.ControllerTrust.Role.${rinst}"
		else
			SECURE_ROLES="${SECURE_ROLES},Device.LocalAgent.ControllerTrust.Role.${rinst}"
		fi
	fi

	json_for_each_item configure_permission permission "${name}" ${rinst}
	json_select ..
}

configure_roles_dir()
{
	local rinst rname is_secure

	if [ "$#" -ne 1 ]; then
	    echo "Illegal number of parameters"
	    exit 1
	fi

	if [ "${1}" = "full_access" ]; then
		rinst=1
		rname="full_access"
	elif [ "${1}" = "Untrusted" ]; then
		rinst=2
		rname="Untrusted"
	else
		json_get_var rname name
		json_get_var rinst instance

		if [ -z "${rname}" ] || [ -z "${rinst}" ]; then
			echo "Deprecated role format ignoring ${1}.json ..."
			return 0
		fi
	fi
	json_get_var is_secure secure_role

	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Alias cpe-${rinst}
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Enable 1
	db_add Device.LocalAgent.ControllerTrust.Role.${rinst}.Name ${rname}

	if [ "${is_secure}" = "1" ] || [ "${is_secure}" = "true" ]; then
		if [ -z "${SECURE_ROLES}" ]; then
			SECURE_ROLES="Device.LocalAgent.ControllerTrust.Role.${rinst}"
		else
			SECURE_ROLES="${SECURE_ROLES},Device.LocalAgent.ControllerTrust.Role.${rinst}"
		fi
	fi

	json_for_each_item configure_permission permission "${name}" "$((rinst))"
	json_select ..
}

configure_ctrust_role()
{
	local num
	local roles_obj

	if [ -f "${CTRUST_RESET_FILE}" ]; then
		return 0
	fi

	mkdir -p /tmp/obuspa/
	SECURE_ROLES=""
	
	if [ -f "${1}" ]; then
		json_init
		json_load_file "${1}"
		json_for_each_item configure_roles roles
	else
		for f in "${FW_DEFAULT_ROLE_DIR}"/*; do
			[ -e "$f" ] || continue
			f="${f##*/}"
			echo "Loading $f ....."
			json_init
			json_load_file "${FW_DEFAULT_ROLE_DIR}/${f}"
			json_select tr181
			configure_roles_dir "${f/.json/}"
		done
	fi

	if [ -n "${SECURE_ROLES}" ]; then
		db_add Device.LocalAgent.ControllerTrust.SecuredRoles "${SECURE_ROLES}"
	fi

	if [ -f "${CTRUST_RESET_FILE_TEMP}" ]; then
		mv -f "${CTRUST_RESET_FILE_TEMP}" "${CTRUST_RESET_FILE}"
	fi
}

# configure_ctrust_role "${@}"
