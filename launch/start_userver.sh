#!/bin/bash

	kill -9 `ps aux | grep "userver.pl" | grep -v grep | tr -s ' ' '+' | cut -d+ -f2` 2> /dev/null
	kill -9 `ps aux | grep "check.pl" | grep -v grep | tr -s ' ' '+' | cut -d+ -f2`  2> /dev/null
	rm -f /tmp/userver/lock;
	rm -f /tmp/userver/pipe;
	/bin/echo `/bin/date` $* >> /home/solenkov.v/UServer/launch/restart
	/home/solenkov.v/UServer/userver.pl &
