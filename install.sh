#!/bin/bash

# unused
copy_script() {
	echo "Copying "$1" to /usr/bin ..."
	cp ./$1 /usr/bin/$1 || remove
	chmod 750 /usr/bin/$1 | remove
}

failure()
{
	echo "Failed install"
	exit 1
}

copy()
{
	echo "Copying scripts to /usr/bin..."
	cp ./netpot.py /usr/bin/netpot || remove
        chmod 750 /usr/bin/netpot || remove

	cp ./netpotd.sh /usr/bin/netpotd || remove
        chmod 750 /usr/bin/netpotd || remove

	echo "Loading apparmor profile for exposed netpot listener..."
	cp ./apparmor/usr.bin.netpot /etc/apparmor.d/ || remove
	chmod 640 /etc/apparmor.d/usr.bin.netpot || remove
	/usr/sbin/apparmor_parser -r /etc/apparmor.d/usr.bin.netpot || remove

	echo "Setting up systemd unit configuration file..."
	cp ./systemd/netpotd.service /etc/systemd/system/ || remove
	/usr/bin/systemctl daemon-reload
}

create_system_user()
{
	echo "Creating netpot system user for privilege separation..."
	useradd --system --shell /usr/sbin/nologin netpot || remove
}

remove()
{
	rm /usr/bin/netpot.py
	rm /usr/bin/netpotd.sh
	rm /etc/apparmor.d/usr.bin.netpot
	rm /etc/systemd/system/netpotd.service
	deluser netpot
	failure
}

echo "[?] Checking dependencies"
dpkg-query -l ipset &&
{
	echo "[*] Installing netpotd low interaction honeypot"
	copy
	create_system_user
	echo "[*] Installation complete. Run 'systemctl <status|start|stop|restart|enable|disable> netpotd' for managing netpotd."
}
