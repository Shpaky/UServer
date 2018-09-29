#!/usr/lib/perl

	package CONFIG;


	$path =
	{
		'log_dir'	=> '/var/log/server_unix_socket',
		'lib_dir'  	=> '/usr/lib/server-unix-socket',
		'con_dir'	=> '/etc/server_unix_socket',
		'conf_log'	=> '/etc/server_unix_socket/conf_log',
		'tmp_dir' 	=> '/tmp/server-unix-socket',
		'socket'  	=> '/tmp/server-unix-socket/socket',
		'lock'		=> '/tmp/server-unix-socket/lock',
		'pipe'		=> '/tmp/server-unix-socket/pipe',
	};

	## parameters in the this block necessary replace to adding by launch 'server.pl'
	$prefork = 3;
	$mode = 'combat'; 	## force || debug
	$server = 'unix_socket';## inet_socket

	$signals =
	{
		'CHLD' => 'allowable',
		'INT'  => 'allowable',
		'USR1' => 'allowable',
		'USR2' => 'allowable'
	};

	$applications =
	{
		'HPVF'	=>
		{
			'module' => 'ROUTING',
			'method' => 'navigation',
			'catalog'=> '/home/solenkov.v/NHPVF',
			'libraly'=> '/home/solenkov.v/NHPVF/HPVF'
		},
	};

	$navigation =
	{
		'test_multiple_invoke' => 'HPVF',
		're_assemble_project_to_multiple_subprojects' => 'HPVF',
	};
1;
