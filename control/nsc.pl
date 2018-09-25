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

	use CONFIG;
	use CONNECTOR;

	&CONNECTOR::export_name('kill_pid','read_value_ff');
	&kill_pid('USR2',&read_value_ff($CONFIG::path->{'lock'}));
