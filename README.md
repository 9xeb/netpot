# NetPot
This is NetPot, a multithreaded minimal interaction honeypot written in python3.
NetPot is intended to run on internal networks, where incoming connections on certain ports always signify an anomaly or an intrusion.
The idea behind it is simple. It waits for incoming TCP connections on a specific set of ports, accepts handshakes and immediately closes incoming connections, logging the remote IP to syslog. It then proceeds to listen for the next incoming connection.

It is up to the administrator what to do with logged IPs. Logs can can be easily parsed by your preferred collector.
A very strict apparmor profile is provided, if apparmor tools are available on the system. In any case root privileges are dropped right before listening.

Install
```bash
 $ git clone https://github.com/9xeb/netpot
 $ cd netpot
 # ./install.sh
```

Run
```bash
 # systemctl <status|start|stop|restart|enable|disable> netpot
```

### TODO:
 - UDP support (DNS, NTP)
