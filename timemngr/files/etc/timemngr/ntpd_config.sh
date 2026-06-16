#!/bin/sh

. /lib/functions.sh

CONF_FILE=/tmp/timemngr/timemngr.conf

trunc() {
	mkdir -p $(dirname ${CONF_FILE})
	chown -R ntp:ntp $(dirname ${CONF_FILE})
	echo -n "" > ${CONF_FILE}
}

emit() {
	echo -e "$@" >> ${CONF_FILE}
}

validate_global_section() {
	uci_validate_section time global global \
	    'enable:bool:1'
}

validate_server_section() {
	uci_validate_section time server server \
		'enable:bool:1'\
		'mode:string:Unicast'\
		'ttl:uinteger:255'\
		'interface:string'
}

validate_client_section() {
	uci_validate_section time client $1 \
		'enable:bool:1'\
		'iburst:bool:1'\
		'version:uinteger:4'\
		'peer:bool:0'\
		'minpoll:uinteger:6'\
		'maxpoll:uinteger:10'\
		'mode:string:Unicast'\
		'server:list(host)'
}

generate_config() {
	local enable
	validate_global_section || {
		return 1
	}

	if [ "$enable" != 1 ]; then
		return 1
	fi

	local enable_client_sec
	enabled_sec=$(uci -q show time | grep enable=\'1\' | cut -d'.' -f 2)
	for sec in $enabled_sec; do
		type=$(uci -q get time.$sec)
		if [ "${type}" == "client" ]; then
			enable_client_sec=$sec
			break
		fi
	done

	local client_mode enable_client
	local enable iburst version peer minpoll maxpoll mode server
	if [ -n "$enable_client_sec" ]; then
		validate_client_section $enable_client_sec || {
			return 1
		}
		client_mode=$mode
		enable_client=$enable
	else
		enable_client=0
	fi

	local server_mode enable_server
	local enable mode ttl interface
	validate_server_section || {
		return 1
	}

	server_mode=$mode
	enable_server=$enable

	[ "$enable_client" = 0 ] && [ "$enable_server" = 0 ] && return

	trunc
	emit "driftfile /tmp/timemngr/ntp.drift\n"

	str1="restrict -4 default noserve"
	str2="restrict -6 default noserve"
	if [ "$enable_server" != 0 ]; then
		str1="restrict default limited kod nomodify notrap"
		str2="restrict -6 default limited kod nomodify notrap"
	fi

	if [ "$enable_client" == 0 ] || [ "$peer" == 0 ]; then
		str1="${str1} nopeer"
		str2="${str2} nopeer"
	fi

	emit "${str1}"
	emit "${str2}"
	emit "restrict source noquery"

	emit "\n# No limits for local monitoring"
	emit "restrict 127.0.0.1"
	emit "restrict -6 ::1\n"

	if [ "$enable_client" != 0 ]; then
		if [ "$client_mode" = "Broadcast" ]; then
			emit "broadcastclient\n"
		elif [ "$client_mode" = "Multicast" ]; then
			emit "multicastclient 224.0.1.1 minpoll $minpoll maxpoll $maxpoll version $version\n"
		elif [ "$client_mode" = "Manycast" ]; then
			emit "manycastclient 224.0.1.1 minpoll $minpoll maxpoll $maxpoll version $version\n"
		else
			for i in $server; do
				str="server $i minpoll $minpoll maxpoll $maxpoll version $version"
				if [ "$iburst" != 0 ]; then
					str="${str} iburst"
				fi
				emit "${str}"
			done

			if [ "$peer" != 0 ]; then
				for i in $server; do
					str="peer $i minpoll $minpoll maxpoll $maxpoll version $version"
					if [ "$iburst" != 0 ]; then
						str="${str} iburst"
					fi
					emit "${str}"
				done
			fi
		fi
	fi

	emit ""
	if [ "$enable_server" != 0 ]; then
		if [ "$server_mode" = "Broadcast" ] && [ -n "$interface" ]; then
			ip=$(ubus call network.interface dump | jsonfilter -e "@.interface[@.interface='$interface']['ipv4-address'][0]['address']")
			mask=$(ubus call network.interface dump | jsonfilter -e "@.interface[@.interface='$interface']['ipv4-address'][0]['mask']")
            
			if [ -n "$ip" ] && [ -n "$mask" ]; then
				pref=$(( $mask / 8 ))
				bcast_ip=$(echo $ip | cut -d. -f1-$pref)
				for i in `seq $pref 3`; do
					bcast_ip=$bcast_ip".255"
				done
                
				str="broadcast $bcast_ip"
				if [ -n "$ttl" ]; then
					str="${str} ttl ${ttl}"
				fi
                
				emit "${str}"
			fi
		elif [ "$server_mode" = "Multicast" ]; then
			str="broadcast 224.0.1.1"
			if [ -n "$ttl" ]; then
				str="${str} ttl ${ttl}"
			fi
			emit "${str}"
		elif [ "$server_mode" = "Manycast" ]; then
			emit "manycastserver 224.0.1.1"
		fi

		emit ""
		if [ -n "$interface" ]; then
			local loopback=$(ubus call network.interface dump | jsonfilter -e "@.interface[@.interface='loopback']['device']")
			local l3_intf=$(ubus call network.interface dump | jsonfilter -e "@.interface[@.interface='$interface']['device']")
			local saw_lo=
			emit "interface listen $l3_intf"
			[ "$l3_intf" = "$loopback" ] && saw_lo=1
			[ -z "$saw_lo" ] && emit "interface listen $loopback"
			emit ""
		fi
	fi

}

create_service() {
	procd_open_instance timemngr
	procd_set_param command "/sbin/ntpd" -g -u ntp:ntp -n -c ${CONF_FILE}
	procd_set_param respawn
	procd_close_instance
}
