#!/bin/bash

	kill -9 `ps aux | grep "server.pl" | grep -v grep | tr -s ' ' '+' | cut -d+ -f2` 2> /dev/null
	kill -9 `ps aux | grep "check.pl" | grep -v grep | tr -s ' ' '+' | cut -d+ -f2`  2> /dev/null
	rm -f /tmp/server-unix-socket/lock;
	rm -f /tmp/server-unix-socket/pipe;
	/bin/echo `/bin/date` $* >> /home/solenkov.v/SUNIXS/launch/restart
	/home/solenkov.v/SUNIXS/server.pl &
