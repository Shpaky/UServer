#!/usr/bin/perl

	package CONFIG;


	$path =
	{
		'log_dir'	=> '/var/log/userver',
		'lib_dir'  	=> '/usr/lib/userver',
		'con_dir'	=> '/etc/userver',
		'conf_log'	=> '/etc/userver/conf_log',
		'run_dir' 	=> '/var/run/userver',
		'socket'	=> '/var/run/userver/socket',
		'lock'		=> '/var/run/userver/lock',
		'pipe'		=> '/var/run/userver/pipe',
		'tmp_dir' 	=> '/tmp/userver',
		'socket'  	=> '/tmp/userver/socket',
		'lock'		=> '/tmp/userver/lock',
		'pipe'		=> '/tmp/userver/pipe'
	};

	## parameters in the this block necessary replace to adding by launch 'userver.pl'
	$prefork = 3;
	$mode = 'combat'; 	## force || debug
	$server = 'unix_socket';## inet_socket || fcgi
	$listen = '1000';	## size socket queue
	$apps_m = 'multiple';	## multiple || single

	$handler = 'common';	## common || separate
	$signals =
	{
		'CHLD' => 'allowable',
		'INT'  => 'allowable',
		'USR1' => 'allowable',
		'USR2' => 'allowable'
	};

	$logs =
	{
		'SERVER' =>
		{
			'logger' => 'USSimpleLog',
			'notice' => 'USNoticeLog',
		},
		'USERVER'=>
		{
			'logger' => 'USSimpleLog',
			'notice' => 'USNoticeLog',
		},
		'CHECKER'=>
		{
			'notice' => 'USCheckLog',
		},
		'CUSTOM' =>
		{
			'logger' => 'CustomLog',
		}
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
		'Statistic' =>
		{
			'module' => 'Routing',
			'method' => 'navigation',
			'catalog'=> '/home/solenkov.v/Statistics',
			'libraly'=> '/home/solenkov.v/Statistics/Statistic',
		},
		'Palace' =>
		{
			'module' => 'Routing',
			'method' => 'navigation',
			'catalog'=> '/home/solenkov.v/WE',
			'libraly'=> '/home/solenkov.v/WE/Palace'
		}
	};

	$navigation =
	{
		'test_multiple_invoke' => 'HPVF',
		'rename_sources_files' => 'HPVF',
		'integrity_check_video_files' => 'HPVF',
		'move_2_prepare_project' => 'HPVF',
		'assemble_project_by_type_with_multiple_subprojects' => 'HPVF',
		'move_2_home_project' => 'HPVF',
		'publish_project' => 'HPVF',
		'synchronization_project' => 'HPVF',
		'unpublish_project' => 'HPVF',
		'delete_sources_project' => 'HPVF',
		'check_publish_project' => 'HPVF',
		'delete_specified_subtitles_by_projects_of_multiple_type' => 'HPVF',
		'srt2vtt_specified_subtitles_by_projects_of_multiple_type' => 'HPVF',
		're_assemble_info_json_by_project_of_type_multiple' => 'HPVF',
		're_assemble_info_xml_by_project_of_type_multiple' => 'HPVF',
		're_assemble_ism_mnfst_by_project_of_type_multiple' => 'HPVF',
		're_assemble_project_to_multiple_subprojects' => 'HPVF',
		'check_whole_subtitles_by_specified_projects_of_multiple_type' => 'HPVF',
		'unlink_symlinks_to_video_in_subprojects_by_specified_projects_of_multiple_type' => 'HPVF',
		'create_duplicate_subproject_for_non_drm_broadcasting' => 'HPVF',
		'fetch_main_uuid_from_project' => 'HPVF',
		'insert_stat' => 'Statistic',
	};
1;
