#!/usr/bin/perl
	
	use 5.010;
	BEGIN
	{	my $q;
		my $path = $ENV{'PWD'};
		until ( -d $path.'/'.'lib' )
		{
			$path .= '/../';
			++$q > 10 and die 'Ошибка, возможно неверная структура каталогов приложения!';
		}
		chdir($path);
		use lib qw|lib|;
	}

	package USERVER;

	use Getopt::Long;
	use Data::Dumper;	
	use SERVER;
	use CONFIG;
	use POSIX;


	my $result = GetOptions ( 'debug|d+' => \$d, 'check|c:i' => \$cc, ) or die;

	&SERVER::init_log();
	&SERVER::get_logs();

	&SERVER::locked_open($CONFIG::path->{'lock'});
	&SERVER::init_server();
	&SERVER::init_sig_handler(['CHLD','INT','USR1','USR2']);
	&SERVER::check_hand_type() and &SERVER::init_application();


	$USERVER::q = 0;
	$USERVER::children = 0;


	while ( 1 )
	{
		sleep 1;
		&SERVER::check_childs;
		for (my $i = $USERVER::children; $i < $CONFIG::prefork; $i++ )
		{
			&make_new_child();
		}
	}

	sub make_new_child
	{
		my $sigset = POSIX::SigSet->new(SIGINT);
		sigprocmask(SIG_BLOCK, $sigset) or die "Не удалось заблокировать 'SIGINT' для форка: $!\n";
		die "Форк: $!" unless defined ( my $pid = fork );

		if ($pid)
		{
			sigprocmask(SIG_UNBLOCK, $sigset) or die "Не удалось разблокировать 'SIGINT' для форка: $!\n";
			$logger->info('Порождён потомок, процесс сервер!'.'|'.$pid.'|');
			$USERVER::childrens->{$pid} = 1;
			$USERVER::children++;
			return;
		}
		else
		{
			&SERVER::reset_sig_handler(['CHLD','INT','USR1','USR2']);
			sigprocmask(SIG_UNBLOCK, $sigset) or die "Не удалось разблокировать 'SIGINT' для форка: $!\n";

			&SERVER::check_hand_type() or &SERVER::init_application();
			while ( &SERVER::accept_request() )
			{
				my $request = &SERVER::fetch_request();
				$logger->info('Принят запрос, процесс '.'|'.$$.'|'.', запрос '.'|'.++$USERVER::q.'|');
				&SERVER::call_application($request);
				&SERVER::check_apps_mode() and &SERVER::init_log();
			}
		}
	}
