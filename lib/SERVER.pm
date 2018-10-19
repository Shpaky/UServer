	package SERVER;

	use 5.10.0;

	use JSON;
	use POSIX;
	use Fcntl qw|:flock|;
	use Scalar::Util qw|blessed|;

	use IO::Socket;
	use IO::Socket::UNIX;
	use IO::Handle;

	use Log::Any::Adapter;
	Log::Any::Adapter->set('+Adapter');
	use Log::Any '$log';




	$SERVER::EXPORT =
	{
		'kill_pid' => 'subroutine',
		'read_value_ff'	=> 'subroutine',
	};


	sub export_name
	{
		my $pack = caller;
		map { $SERVER::EXPORT->{$_} and local *myglob = eval('$'.__PACKAGE__.'::'.'{'.$_.'}'); *{$pack.'::'.$_} = *myglob } @_;
	}
	sub new 
	{ 
		my $class = shift;
		my $self = bless \{}, $class;
		return $self;
	}
	sub init_server
	{
		given ( $CONFIG::server )
		{
			when ('unix_socket')
			{
				my $pack = caller();
				unlink $CONFIG::path->{'socket'};
				${$pack.'::'.'server'} = IO::Socket::UNIX->new
				(
					Type => SOCK_STREAM(),
					Local => $CONFIG::path->{'socket'},
					Listen => 1000
				);
				chmod 0777, $CONFIG::path->{'socket'};
			}
			when ('inet_socket') {1}
		}
	}
	sub init_sig_handler
	{
		my $pack = caller();
		map { $SIG{$_} = \&{'SERVER'.'::'.$_} } grep { &check_allowable_signals($_) } @{$_[0]};
	}
	sub check_allowable_signals
	{
		return $CONFIG::signals->{$_[0]};
	}
	sub init_application
	{
		my $pack = caller();
		map {
			(
			  &SERVER::connect_module($CONFIG::applications->{$_}) and
			  lc(ref(\&{$CONFIG::applications->{$_}->{'module'}.'::'.$CONFIG::applications->{$_}->{'method'}})) eq 'code' and
			  $SERVER::applications->{$_} = \&{$CONFIG::applications->{$_}->{'module'}.'::'.$CONFIG::applications->{$_}->{'method'}}
			)
			? ( $log->info('Приложение '.'|'.$_.'|'.' подключено, процесс'.'|'.$$.'|') )
			: ( $log->warn('Не удалось подлючить приложение '.'|'.$_.'|'.', процесс'.'|'.$$.'|') )
		} grep { $log->info('Подключение приложения '.'|'.$_.'|'.', процесс'.'|'.$$.'|') } keys %$CONFIG::applications;
	}
	sub connect_module
	{
		push @INC, $_[0]->{'catalog'};
		push @INC, $_[0]->{'libraly'};

		$_[0]->{'module'} !~ /^[a-z0-9:_\-]+$/i and $log->warn('Не допустимое имя модуля'.'|'.$_[0]->{'module'}.'|') and return;

		my $module = $_[0]->{'module'};
		while ( $module =~ /(.*)(::[a-z0-9_\-]+)|[a-z0-9_\-]+$/i )
		{
			my $up_pack = $1;

			my $filename = $module;
			$filename =~ s|::+|/|g;
			$filename =~ /\.pm$/ or $filename .= '.pm';

			exists($INC{$filename}) or ( -f $_[0]->{'catalog'}.'/'.$filename && eval('require '.$module.';') ) or ( delete($INC{$filename}), $log->warn('Ошибка подключения файла модуля'.'|'.$filename.'|'.', ошибка'.'|'.$!.':'.$@.'|'), return );
			$module = $up_pack;
		}
		return !$module;
	}
	sub call_application
	{
		given ($CONFIG::navigation->{decode_json($_[0])->{'route'}})
		{
			when ('HPVF')
			{
				chdir($CONFIG::applications->{'HPVF'}->{'catalog'});
				$log->info('Выполнена маршрутизация на приложение '.'|'.$CONFIG::navigation->{decode_json($_[0])->{'route'}}.'|'.', по запросу '.'|'.decode_json($_[0])->{'route'}.'|'.', процесс'.'|'.$$.'|');
				$SERVER::applications->{'HPVF'}->(decode_json($_[0]))
			}
		}
	}
	sub init_log
	{
		my $log = $_[0] || $CONFIG::path->{'conf_log'};
		Log::Log4perl->init($log);
	}
	sub REAPER
	{
		while (( $UNIX_SOCKET::pid = waitpid(-1,WNOHANG)) > 0)
		{
			$log->error('Уничтожен потомок, процесс сервер упал!'.'|'.$UNIX_SOCKET::pid.'|');
	#		last;
		}
		$UNIX_SOCKET::SIG{CHLD} = \&REAPER;
	}
	sub INT
	{
		$log->warn('Получен сигнал '.'|'.$_[0].'|'.' завершения работы сервера, процесс'.'|'.$$.'|');
		local($SIG{CHLD}) = 'IGNORE';
		map { delete $UNIX_SOCKET::childrens->{$_} and $UNIX_SOCKET::children-- and $log->warn('Уничтожен потомок, процесс сервер завершён'.'|'.$_.'|') } grep { kill_pid(2, $_) } keys %$UNIX_SOCKET::childrens;
		$log->warn('Процесс сервер остановлен, процесс'.'|'.$$.'|');
		exit;
	}
	sub CHLD
	{
		my $sigset = POSIX::SigSet->new($_[0]);
		sigprocmask(SIG_BLOCK, $sigset) or die "Не удалось заблокировать '$_[0]' для обработчика: $!\n";

		$UNIX_SOCKET::SIG{CHLD} = 'IGNORE';
		&REAPER;

		sigprocmask(SIG_UNBLOCK, $sigset) or die "Не удалось разблокировать '$_[0]' для обработчика: $!\n";
	}
	sub USR1
	{
		$_[1] > 0 || ( my $sigset = POSIX::SigSet->new($_[0]) and sigprocmask(SIG_BLOCK, $sigset) or die "Не удалось заблокировать '$_[0]' для обработчика: $!\n" );

		local $SIG{PIPE} = &PIPE;
		$_[1] > 0 || $log->info('Получен сигнал от мониторинга, процесс'.'|'.$$.'|');
		if ( -p $CONFIG::path->{'pipe'} )
		{
			if ( &write_pipe($CONFIG::path->{'pipe'},time) )
			{
				$log->info('Отправлен ответ на запрос от мониторинга, процесс'.'|'.$$.'|');
			}
			else
			{
				$_[1] > 0 || &USR1($_[0],1);
			}
		}
		else
		{
			if ( &create_pipe($CONFIG::path->{'pipe'},0700) )
			{
				$log->info('Создан именованный канал '.'|'.$CONFIG::path->{'pipe'}.'|'.', процесс'.'|'.$$.'|');
				$_[1] > 1 || &USR1($_[0],2);
			}
			else
			{
				$log->error('Не удалось создать именованный канал '.'|'.$CONFIG::path->{'pipe'}.'|'.', процесс'.'|'.$$.'|');
			}
		}

		$_[1] > 0 || sigprocmask(SIG_UNBLOCK, $sigset) or die "Не удалось разблокировать '$_[0]' для обработчика: $!\n";
	}
	sub PIPE
	{
		local $SIG{PIPE} = 'IGNORE';
		local $SIG{PIPE} = 'DEFAULT';
	}
	sub USR2
	{
		my $sigset = POSIX::SigSet->new($_[0]);
		sigprocmask(SIG_BLOCK, $sigset) or die "Не удалось заблокировать '$_[0]' для обработчика: $!\n";

		$log->warn('Получен сигнал об изменении конфигурации сервера, процесс'.'|'.$$.'|');
		$UNIX_SOCKET::SIG{CHLD} = 'IGNORE';
		no CONFIG;
		map { delete $UNIX_SOCKET::childrens->{$_} and $UNIX_SOCKET::children-- and $log->warn('Уничтожен потомок, процесс сервер завершён'.'|'.$_.'|') } grep {  kill_pid(2, $_) } keys %$UNIX_SOCKET::childrens;
		use CONFIG;

		sigprocmask(SIG_UNBLOCK, $sigset) or die "Не удалось разблокировать '$_[0]' для обработчика: $!\n";
	}
	sub loop 
	{
		
		if ( $UNIX_SOCKET::pid && kill_pid(0,$UNIX_SOCKET::pid) )
		{   	
			$log->info('Проверка потомка, процесс чекер-соединений существует'.'|'.$UNIX_SOCKET::pid.'|');
			return;
		} 
		else 
		{
			$log->warn('Проверка потомка, процесс чекер-соединений не существует!'.'|'.$UNIX_SOCKET::pid.'|');
			if ( $UNIX_SOCKET::pid = fork() ) 
			{ 

				$log->info('Порожден потомок, процесс чекер-соединений!'.'|'.$UNIX_SOCKET::pid.'|');
				return; 
			} 
			else   
			{
				while ( 1 )
				{
					sleep 1;
					&SERVER::check_connects($_) for (0..9);
				}
#				eval{exit;};
			}
		}
	}
	sub kill_pid
	{ 
		my ( $sig, $pid ) = @_;
			
		kill $sig => $pid;	
	}
	sub check_childs
	{
		map { delete $UNIX_SOCKET::childrens->{$_} and $UNIX_SOCKET::children-- and $log->error('Проверка процесса-потомка, процесс сервер не отвечает!'.'|'.$_.'|') } grep { ! kill_pid(0, $_) } keys %$UNIX_SOCKET::childrens;
	}
	sub get_dates
	{
		my $c = shift if $_[0] eq __PACKAGE__ || ref($_[0]) eq __PACKAGE__;
		my $t = shift;

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t);

		return
		([
			$wday,
			sprintf('%02d%02d%02d',$year%100,$mon+1,$mday),
			sprintf('%02d.%02d.%02d %02d:%02d:%02d',$mday,$mon+1,$year%100,$hour,$min,$sec),
			sprintf('%04d-%02d-%02d %02d:%02d:%02d',$year+1900,$mon+1,$mday,$hour,$min,$sec),
			sprintf('%04d%02d%02d',$year+1900,$mon,$mday),
			[ $hour, $mday, $mon, $year, $wday, $yday ],
		]);
	}
	sub locked_open
	{
		my ( $path ) = @_;

		if ( sysopen OL, $path, O_WRONLY|O_CREAT|O_TRUNC|O_EXCL )
		{
			flock ( OL, LOCK_EX );
			print OL $$;
			$log->info('Запуск приложения, сервер запущен, процесс '.'|'.$$.'|');
		}
		else
		{
			open RL, $path; my $pid = <RL>; close RL;
			$log->error('Запуск приложения, процесс '.'|'.$$.'|'.' ошибка запуска - сервер уже запущен, процесс '.'|'.$pid.'|');
			die;
		}
	}
	sub write_pipe
	{
		my ( $pipe, $data ) = @_;

		open  WP,'>',$pipe;
		print WP $data;
		close WP;

#		return $! ? undef : 1;
	}
	sub create_pipe
	{
		my ( $path, $mode ) = @_;

		POSIX::mkfifo($path, $mode);
	}
	sub write_data
	{
		my ( $path, $data ) = @_;

		open  WD, '>>', $path;
		print WD Data::Dumper->Dump([$data],['data']);
		close WD;
	}
	sub read_value_ff
	{
		my $path = shift;
		my $v;
		open RP, $path; $v .= $_ for <RP>; close RP;

		return $v;
	}
	1;
