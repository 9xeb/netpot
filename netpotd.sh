#!/bin/bash

# TODO: ipset persistent and iptables persistent

if [[ ! -x /usr/sbin/ipset ]]
then
	echo "netpotd: ipset is not installed, will not blacklist IPs"
else
	/usr/sbin/ipset create netpot hash:ip hashsize 4096

	# Delete possible previous blacklist rules
	/usr/sbin/iptables -D INPUT -m set --match-set netpot src -j DROP
	/usr/sbin/iptables -D FORWARD -m set --match-set netpot src -j DROP

	# Insert blacklist rules
	/usr/sbin/iptables -I INPUT -m set --match-set netpot src -j DROP || { echo "Iptables failed"; exit 1; }
	/usr/sbin/iptables -I FORWARD -m set --match-set netpot src -j DROP || { echo "Iptables failed"; exit 1; }
fi


#IPV4_REGEX="^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

#NETPOT="/usr/bin/netpot.py"

# Check arguments
#if [[ $# -lt 1 ]]; then echo "netpotd: Need at least one port"; exit 1; fi
#for arg in $@
#do
#	if [[ arg -lt 1 || arg -gt 65535 ]]; then echo "netpotd: Invalid port"; exit 1; fi
#done

# Start netpot daemon
echo "netpotd: Starting daemon..."

# NOTE: sterr is shared even inside { }, we show debugging info using >&2, redirecting to stderr
if [[ -x /usr/bin/netpot ]]
then
	/usr/bin/netpot | \
	{
		while [ true ]
		do
			read ip
			if [[ "$ip" == "" ]]; then 	# if netpot crashes we catch it here
				>&2 echo "netpotd: It seems like netpot crashed"
				exit 1
			fi
			if [[ -x /usr/sbin/ipset ]]
			then
				/usr/sbin/ipset add netpot "$ip"
			fi

			printf "IP: %s" $ip
		done;
	}
	exit 0
else
	echo "netpotd: cannot execute /usr/bin/netpot.py"
	exit 1
fi