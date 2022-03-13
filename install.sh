#!/bin/bash

failure()
{
	echo "[!] Failed install"
	exit 1
}

copy()
{
	echo "[*] Copying scripts to /usr/bin..."
	cp ./netpot.py /usr/bin/netpot || remove
        chmod 750 /usr/bin/netpot || remove

	#cp ./netpotd.sh /usr/bin/netpotd || remove
        #chmod 750 /usr/bin/netpotd || remove

	echo "[*] Loading apparmor profile for exposed netpot listener..."
	cp ./apparmor/usr.bin.netpot /etc/apparmor.d/ || no_apparmor
	chmod 640 /etc/apparmor.d/usr.bin.netpot || no_apparmor
	/usr/sbin/apparmor_parser -r /etc/apparmor.d/usr.bin.netpot || no_apparmor

	echo "[*] Setting up systemd unit configuration file..."
	cp ./systemd/netpot.service /etc/systemd/system/ || remove
	/usr/bin/systemctl daemon-reload || /bin/systemctl daemon-reload
}

no_apparmor()
{
	echo "[/] Some apparmor packages are missing, installed without apparmor support"
}

create_system_user()
{
	echo "[*] Creating netpot system user for privilege separation..."
	/usr/bin/id netpot || /usr/sbin/useradd --system --shell /usr/sbin/nologin netpot || remove
}

remove()
{
	rm /usr/bin/netpot &> /dev/null
	rm /usr/bin/netpotd &> /dev/null
	rm /etc/apparmor.d/usr.bin.netpot &> /dev/null
	rm /etc/systemd/system/netpot.service &> /dev/null
	deluser netpot &> /dev/null
	failure
}

echo "[?] Checking dependencies"
dpkg-query -l ipset &&
{
	echo "[*] Installing netpotd low interaction honeypot"
	copy
	create_system_user
	echo "[*] Installation complete. Run 'systemctl <status|start|stop|restart|enable|disable> netpot' for managing netpot."
}
