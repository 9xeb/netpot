#!/usr/bin/python3
import socket, sys, threading, time, syslog
import os, pwd, grp
import concurrent.futures	# provide ThreadPoolExecutor and other support function for working with thread pools
import threading

HOST = "0.0.0.0"
threads_lock = threading.Lock()			# acquired when threads are accessing a global shared resource (for example printf to stderr)

def drop_privileges(target_username='nobody', target_groupname='nogroup'):
	if os.getuid() != 0:	# if effective user id is not root then there are no privileges to drop
		return

	# get uid/gid from username
	target_uid = pwd.getpwnam(target_username).pw_uid
	target_gid = grp.getgrnam(target_groupname).gr_gid

	# remove all current groups
	os.setgroups([])

	# try setting the target uid/gid
	os.setgid(target_gid)	# setgid first, before setuid, otherwire permission denied happens
	os.setuid(target_uid)

	# set a very conservative mask
	os.umask(0o077)


def listen_to_socket(sock):
	# Accepts one incoming connection, immediately close it, print remote IP to stdout and log the event
	sock.listen()
	while True:
		conn, addr = sock.accept()
		conn.close()
		with threads_lock:
			print(addr[0], flush=True)
			syslog.syslog("[NETPOT] %s" % addr[0])

def bind_to_socket(port):
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	for attempt in range(5):	# retry to bind at most 5 times
		try:
			with threads_lock:	# syntactic sugar for threads_lock.acquire() <-> threads_lock.release()
				print("netpot: trying to bind to port %d" % port, file=sys.stderr)
			s.bind((HOST,port))
			with threads_lock:
				print("netpot: listening on port %d" % port, file=sys.stderr)
			return s
		except OSError: 	# raised when port binding fails
			continue
			#time.sleep(2) 	# wait 2 seconds before retrying to bind socket
	return		# return None if could not bind to port

def start_honeypot(ports):
	with concurrent.futures.ThreadPoolExecutor() as executor:	# NOTE: max_workers=N can be used to set a custom number of worker threads in the pool
									# by default it is (number of processors * 5)
		sockets = [ bind_to_socket(port) for port in ports ]	# bind to all sockets
		drop_privileges()					# drop privileges after binding to all ports and before actually listening on them
		futures = [ executor.submit(listen_to_socket, sock=socket) for socket in sockets if socket is not None ]	# enqueue one server task for each port
																# if binding to that specific port succeded
		for future in concurrent.futures.as_completed(futures):
			# here for each completed task in the thread pool
			try:
				result = future.result()	# may trigger async exception if function bound to thread did so
			except OSError as oserror:
				print("netpot: %s" % oserror, file=sys.stderr)

def validate_port_arguments(args):
	# look for invalid port arguments
	for port in args:
		if ((int(port) < 1) or (int(port) > 65535)):
			raise ValueError('Invalid port '+port)

	if len(sys.argv) < 2:
		raise ValueError('Need at least one argument')

	for port in sys.argv[1:]:
		if ((int(port) < 1) or (int(port) > 65535)):
			raise ValueError('Invalid port %s' % port)

if len(sys.argv) < 2:
	# if user does not provide a list of ports then a default one is chosen
	default_ports = [ 21, 22, 80, 139, 443, 445, 8080 ] # FTP, SSH, SMB, HTTP, HTTPS as default honeypot ports
	start_honeypot(default_ports)
else:
	try:
		validate_port_arguments(sys.argv[1:])	# can throw a ValueError if user provided invalid arguments
		start_honeypot([ int(argument) for argument in sys.argv[1:] ])
	except ValueError:
		print("At least one given port is invalid")
		exit(1)
