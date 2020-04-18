#!/bin/bash
########################################################################
# This bash script will create a socksifying router and pass all subnet
# traffic through
# a socks5 proxy. As the script is now written, local traffic is not
# proxied, however, make the change noted below and it will be.
#
# Assumptions here are that you are using a laptop with an internet
# connection on wlan0, and an additional wired ethernet port eth0.
#
# The script requires that a dhcp server be running using the
# isc-dhcp-server package on ubuntu, or equivalent on other O/S varieties.
# This dhcp server will serve addresses on eth0 to nodes trying to
# connect.  Either that or all of the subnet clients have to have static
# addresses. To configure dhcpd, add the following to /etc/dhcp/dhcpd.conf
# (changing the subnet address as appropriate):
#
#subnet 192.168.1.0 netmask 255.255.255.0 {
#  range 192.168.1.10 192.168.1.100;
#  range 192.168.1.150 192.168.1.200;
#  option routers 192.168.1.254;
#  option broadcast-address 192.168.1.255;
#}
#
# Also, the script requires the redsocks, openssh-client, and iptables
# packages be installed as well.
#
# Finally, you need to edit /etc/sysctl.conf as follows:
#
# Uncomment the next line to enable packet forwarding for IPv4
# net.ipv4.ip_forward=1
########################################################################

########################################################################
# Define various configuration parameters.
########################################################################

SOCKS_PORT=1080
REDSOCKS_TCP_PORT=$(expr $SOCKS_PORT + 1)
TMP=/tmp/subnetproxy ; mkdir -p $TMP
REDSOCKS_LOG=$TMP/redsocks.log
REDSOCKS_CONF=$TMP/redsocks.conf
SUBNET_INTERFACE=eth1
SUBNET_PORT_ADDRESS="192.168.2.1" #can't be the same subnet as eth1
INTERNET_INTERFACE=eth0

########################################################################
#standard router setup - sets up subnet SUBNET_PORT_ADDRESS/24 on eth0
########################################################################

# note - if you just want a standard router without the proxy/tunnel
# business, you only need to execute this block of code.

sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo ifconfig eth1 $SUBNET_PORT_ADDRESS netmask 255.255.255.0
sudo iptables -A FORWARD -o eth0 -i eth1 -s $SUBNET_PORT_ADDRESS/24 \
     -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED \
     -j ACCEPT
sudo iptables -A POSTROUTING -t nat -j MASQUERADE

########################################################################
#redsocks configuration
########################################################################

cat >$REDSOCKS_CONF <<EOF
base {
  log_info = on;
  log = "file:$REDSOCKS_LOG";
  daemon = on;
  redirector = iptables;
}
redsocks {
  local_ip = 0.0.0.0;
  local_port = $REDSOCKS_TCP_PORT;
  ip = 127.0.0.1;
  port = $SOCKS_PORT;
  type = socks5;
}
EOF

# To use tor just change the redsocks output port from 1080 to 9050 and
# replace the ssh tunnel with a tor instance.

########################################################################
# start redsocks
########################################################################

sudo redsocks -c $REDSOCKS_CONF -p /dev/null

########################################################################
# proxy iptables setup
########################################################################

# create the REDSOCKS target
sudo iptables -t nat -N REDSOCKS

# don't route unroutable addresses
sudo iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
#sudo iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

# redirect statement sends everything else to the redsocks
# proxy input port
sudo iptables -t nat -A REDSOCKS -p tcp -j REDIRECT \
     --to-ports $REDSOCKS_TCP_PORT

# if it came in on eth0, and it is tcp, send it to REDSOCKS
sudo iptables -t nat -A PREROUTING -i $SUBNET_INTERFACE \
     -p tcp -j REDSOCKS

# Use this one instead of the above if you want to proxy the local
# networking in addition to the subnet stuff. Redsocks listens on
# all interfaces with local_ip = 0.0.0.0 so no other changes are
# necessary.
#sudo iptables -t nat -A PREROUTING -p tcp -j REDSOCKS

# don't forget to accept the tcp packets from eth0
sudo iptables -A INPUT -i eth1 -p tcp --dport $REDSOCKS_TCP_PORT \
     -j ACCEPT
