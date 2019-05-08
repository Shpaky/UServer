#!/usr/bin/perl
	
	package CHECKER;

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

	use SERVER;
	use CONFIG;
	use Getopt::Long;

	our $logger;
	our $notice;


	my $result = GetOptions ( 'check|c=s' => \$check, 'debug|d+' => \$d, 'timeout=i' => \$timeout ) or die;

	{
		$check eq 'server' and &check_server and last; 
	}
	
	sub check_server
	{
		&SERVER::init_log();
		&SERVER::notice();

		my $pipe = $CONFIG::path->{'pipe'};
		my $lock = $CONFIG::path->{'lock'};


		if ( my $pid = &read_value_ff($lock) ) 
		{
			say $pid;
			if ( &SERVER::kill_pid('USR1',$pid) ) 
			{
				my $time = time;
				sleep 1;
				if ( my $child = open STDIN, '-|' )
				{
					local $SIG{CHLD} = 'IGNORE';
					my $resp;
					sleep 1;
					&SERVER::kill_pid('TERM',$child);
					$resp = <STDIN>;
					unless ( $resp ) 
					{
						my $txt_1 = 'Не удалось получить ответ на канал ';
						my $txt_2 = ' от процесса';

						$notice->warn($txt_1.'|'.$CONFIG::path->{'pipe'}.'|'.$txt_2.'|'.$pid.'|');
					}
					if ( $d )
					{
						say 'Send:'.$time;
						say 'Recieve:'.$resp;
						say 'Current:',time;
					}
						
					say time - $resp > 3 ? 0 : 1;
				}	
				else
				{
					my $resp = &read_value_ff($pipe);
					print $resp;
				}
			}
			else
			{
				my $txt = 'Не удалось отправить сигнал на процесс';
				$notice->warn($txt.'|'.$pid.'|');
				say 0;
			}
		}
		else
		{
			my $txt = 'Не найден pid-файл';
			$notice->warn($txt.'|'.$CONFIG::path->{'lock'}.'|');
			say 0;
		} 
	}

	sub read_value_ff
	{
		my $path = shift;
		my $v;
		open RP, $path; $v .= $_ for <RP>; close RP;
		
		return $v;
	}

	sub determine_timeout
	{
		my $date = shift;

		$date->[0] >= 2 and $date->[0] <= 6 and return 10;

		return 1;
	}
