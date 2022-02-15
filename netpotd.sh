#!/bin/bash

# This daemon script exists for separation of privileges:
# netpot.py exposes ports and drops privileges to reduce attack surface
# netpotd.sh runs as root and interacts directly with iptables and ipset
# they are linked by a pipe through which remote IPs are written when a connection happens

# TODO: ipset persistent and iptables persistent
# NOTE: this runs as root to be able to work with iptables and ipset (TODO: maybe only NET_ADMIN is required, test it!).

if [ ! -x /usr/sbin/ipset ] && [ ! -x /sbin/ipset ]
then
	echo "netpotd: ipset is not installed, will not blacklist IPs"
else
        # relative names instead of absolute paths are used here for better portability
        # this is not a security risk unless the SUID bit is set on this script
	ipset create netpot hash:ip hashsize 4096

	# Delete possible previous blacklist rules
	iptables -D INPUT -m set --match-set netpot src -j DROP
	iptables -D FORWARD -m set --match-set netpot src -j DROP

	# Insert blacklist rules (so that they are matched first)
	iptables -I INPUT -m set --match-set netpot src -j DROP || { echo "Iptables failed"; exit 1; }
	iptables -I FORWARD -m set --match-set netpot src -j DROP || { echo "Iptables failed"; exit 1; }
fi

# Start netpot daemon
echo "netpotd: Starting daemon..."

if [[ -x /usr/bin/netpot ]]
then
	/usr/bin/netpot | \
	{
                # each new line from netpot triggers one loop cycle
		while [ true ]
		do
                        # read one line (an IPV4 address is expected)
			read ip
			if [[ "$ip" == "" ]]; then 	# netpot crashed or misbehaved
				>&2 echo "netpotd: It seems like netpot crashed"
				exit 1
			fi
			if [[ -x /usr/sbin/ipset ]]
			then
                                # add the IP to the ipset blacklist
                                # if it is already present, nothing happens
                                # if it is not a valid IP, we let ipset handle it
				/usr/sbin/ipset add netpot "$ip"
			fi
		done;
	}
	exit 0
else
	echo "netpotd: cannot execute /usr/bin/netpot"
	exit 1
fi
