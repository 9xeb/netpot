# netpot
Simple multithreading low interaction honeypot written in python3 and bash.
The idea behind it is simple. It waits for incoming TCP connections on a specific set of ports, accepts handshakes and immediately closes incoming connections, logging the remote IP and updating an ipset blacklist.
A very strict apparmor profile is provided, if apparmor tools are available on the system.

First of all make sure ipset is installed, then:

```
# ./install.sh
# systemctl start netpotd
```

You can make sure netpot is listening with:

```
$ ss -tpl
```

### TODO
UDP services (DNS, NTP)
