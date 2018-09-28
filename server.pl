#!/usr/bin/perl
	
	use 5.010;
	BEGIN
	{	my $q;
		my $path = $ENV{'PWD'};
		until ( -d $path.'/'.'lib' )
		{
			say $path;
			$path .= '/../';
			++$q > 10 and die 'Ошибка, возможно неверная структура каталогов приложения!';
		}
		chdir($path);
		use lib qw|lib|;
	}

	package UNIX_SOCKET;

	use feature qw|say switch|;

	use Getopt::Long;
	use Data::Dumper;	
	use SERVER;
	use CONFIG;
	use POSIX;

	use Log::Any::Adapter;
	Log::Any::Adapter->set('+Adapter');
	use Log::Any '$log';


	my $result = GetOptions ( 'debug|d+' => \$d, 'check|c:i' => \$cc, ) or die;


	&SERVER::locked_open($CONFIG::path->{'lock'});
	&SERVER::init_server();
	&SERVER::init_sig_handler(['CHLD','INT','USR1','USR2']);
	&SERVER::init_application();

	$UNIX_SOCKET::q = 0;
	$UNIX_SOCKET::children = 0;

	while ( 1 )
	{
		sleep 1;
		&SERVER::check_childs;
		for (my $i = $UNIX_SOCKET::children; $i < $CONFIG::prefork; $i++ )
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
			$log->info('Порождён потомок, процесс сервер!'.'|'.$pid.'|');
			$UNIX_SOCKET::childrens->{$pid} = 1;
			$UNIX_SOCKET::children++;
			return;
		}
		else
		{
			$SIG{INT} = 'DEFAULT';
			sigprocmask(SIG_UNBLOCK, $sigset) or die "Не удалось разблокировать 'SIGINT' для форка: $!\n";

			while ( $conn = $server->accept() )
			{
				my $request = <$conn>;
				$log->info('Принят запрос, процесс '.'|'.$$.'|'.', запрос '.'|'.++$UNIX_SOCKET::q.'|');
				&SERVER::call_application($request);
			}
		}
	}
