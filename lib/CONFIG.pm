#!/usr/lib/perl

	package CONFIG;


	$path =
	{
		'log_dir'	=> '/var/log/userver',
		'lib_dir'  	=> '/usr/lib/userver',
		'con_dir'	=> '/etc/userver',
		'conf_log'	=> '/etc/userver/conf_log',
		'tmp_dir' 	=> '/tmp/userver',
		'socket'  	=> '/tmp/userver/socket',
		'lock'		=> '/tmp/userver/lock',
		'pipe'		=> '/tmp/userver/pipe',
	};

	## parameters in the this block necessary replace to adding by launch 'userver.pl'
	$prefork = 12;
	$mode = 'combat'; 	## force || debug
	$server = 'unix_socket';## inet_socket || fcgi
	$listen = '1000';	## 1000
	$apps_m = 'single';	## multiple

	$handler = 'common';	## common || separate
	$signals =
	{
		'CHLD' => 'allowable',
		'INT'  => 'allowable',
		'USR1' => 'allowable',
		'USR2' => 'allowable'
	};

	$applications =
	{
	#	'HPVF'	=>
	#	{
	#		'module' => 'ROUTING',
	#		'method' => 'navigation',
	#		'catalog'=> '/home/solenkov.v/NHPVF',
	#		'libraly'=> '/home/solenkov.v/NHPVF/HPVF'
	#	},
		'Statistic' =>
		{
			'module' => 'Routing',
			'method' => 'navigation',
			'catalog'=> '/home/solenkov.v/Statistics',
			'libraly'=> '/home/solenkov.v/Statistics/Statistic',
		}
	};

	$navigation =
	{
		'test_multiple_invoke' => 'HPVF',
		're_assemble_project_to_multiple_subprojects' => 'HPVF',
		'assemble_project_by_type_with_multiple_subprojects' => 'HPVF',
		'move_2_home_project' => 'HPVF',
		'publish_project' => 'HPVF',
		'synchronization_project' => 'HPVF',
		'rename_sources_files' => 'HPVF',
		'unpublish_project' => 'HPVF',
		'check_publish_project' => 'HPVF',
		'fetch_main_uuid_from_project' => 'HPVF',
		'create_duplicate_subproject_for_non_drm_broadcasting' => 'HPVF',
		'insert_stat' => 'Statistic',
	};
1;
