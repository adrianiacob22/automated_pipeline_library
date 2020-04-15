#!/usr/bin/bash
gateway="cmschef1"
export LC_openvpncfg="/etc/openvpn/client/sceptest.ovpn"
logfile="/tmp/openvpn.log"

connect_openvpn () {
	sudo openvpn --config "${LC_openvpncfg}" --log "${logfile}" --daemon
  echo -e "${user}\n${pass}" > auth
  chmod 600 auth
  sudo openvpn --config "${LC_openvpncfg}" --log "${logfile}" --auth-user-pass file.txt --daemon && rm -rf auth
	sleep 5
}

sudo ps -ef | grep openvpn | grep -v grep
if [ $? == 0 ]; then
		echo "Openvpn client is running on ${gateway}"
		exit 0
	else
		echo "Starting openvpn on ${gateway}. Please check ${logfile}"
    connect_openvpn
fi

grep Initialization "${logfile}"
if [ $? == 0 ]; then
		echo "Openvpn client is running on ${gateway}"
	else
		echo "Trying to start openvpn on ${gateway} using another profile"
    export LC_openvpncfg="/etc/openvpn/client/amm-ibmaiacob1.ovpn"
		connect_openvpn
fi
