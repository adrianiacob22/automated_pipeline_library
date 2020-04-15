#!/usr/bin/bash
set -x

##Updated to use jenkins user instead of root
gateway="cmschef1"
sudo grep -q ${gateway} /etc/hosts || echo "9.42.41.250 ${gateway}" | sudo tee --append /etc/hosts
alias ssh='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
n=$(sudo su -c "ssh jenkins@"${gateway}" sudo ip a | grep POINTOPOINT | awk '{print \$2}' | sed 's/://g' |  awk '{print substr(\$0,length,1)}' | sort | tail -1")
x=$(perl -e "print $n+1")
export x="${x}"
interface=tun"${x}"
local_int=tun11
routeslist=$(ssh jenkins@"${gateway}" 'sudo ip route | grep 101' | awk '{print $1}')
#export LC_openvpncfg="/etc/openvpn/client/amm-ibmaiacob1.ovpn"
#export LC_openvpncfg="/etc/openvpn/client/sceptest.ovpn"
export LC_openvpncfg="/home/erica/ericaclient.ovpn"


##Check if there are routes through openvpn to 3.x environment from the gateway server
if [[ ! -z "${routeslist}" ]]; then
	echo 'Openvpn client is running on "${gateway}"'
else
 	echo "Openvpn client is not running on ${gateway}"
  exit 1
fi

echo "Checking if ssh tunnel is already connected to ${gateway}"
ssh_stat=$(ps -ef | grep ssh | grep "${gateway}" || true)

if [[ ! -z "${ssh_stat}" ]]; then
	echo "ssh tunnel is connected to ${gateway}"
else
	echo "Connecting ssh tunnel"
  export BUILD_ID=dontkillme && sudo -E su -c "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f -w 11:${x} root@${gateway} sudo ifconfig ${interface} 192.168.${x}.1/24 up "
	PID=$(ps -ef | grep ${gateway} | grep -v grep | awk '{print $2}')
	echo "ssh connection to ${gateway} is started with PID: $PID"
	ssh jenkins@${gateway} sudo firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -o tun0 -j MASQUERADE || true

    sudo -E ifconfig "${local_int}" 192.168."${x}".2/24 up

    for route in ${routeslist}
    do
    sudo -E /sbin/ip route add "${route}" metric 101 via 192.168."${x}".2
    done
    ssh jenkins@"${gateway}" sudo firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i "${interface}" -o tun0 -j ACCEPT
	  ssh jenkins@"${gateway}" sudo firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i "${interface}" -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
fi
