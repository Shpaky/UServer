#!/usr/lib/perl

	package Adapter;
	use strict;
	use warnings;

	use Log::Any::Adapter::Util 'make_method';
	use LogNot;
	use base 'Log::Any::Adapter::Base';

	my $pairs = 
	{ 
		log_debug 	=> [qw/debug/],
		log_info 	=> [qw/info inform/],
		log_warn 	=> [qw/warn warning/],
		log_notice 	=> [qw/notice/],
		log_error	=> [qw/err error fatal crit critical alert emergency/], 
		not_error	=> [qw/errnot/],
	}; 		

	while ( my ($function, $methods) = each %$pairs )
	{
		my $code;
		if ( $function eq 'log_error' ) 
		{ 
			$code = <<EOC;
			sub 
			{ 
				shift;
				\@_ = (join '', \@_);
				\&LogNot:\:$function;
				\&LogNot:\:not_error;
			}		 
EOC
		} 
		elsif ( $function eq 'log_notice' )
		{
			$code = <<EOC;
			sub
			{
				shift;
				\@_ = (join '', \@_);
				\&LogNot:\:$function;
				\&LogNot:\:not_notice;
			}
EOC
		}
		else 
		{ 
			$code = <<EOC;
			sub 
			{ 
				shift;
				\@_ = (join '', \@_);
				\&LogNot:\:$function;
			}		 
EOC
		}
		my $sub = eval $code; 
		
		for my $method ( @$methods ) 
		{ 
			make_method( $method, $sub);
		}
	} 
	
	for my $method (Log::Any->detection_methods) 
	{ 
			make_method( $method, sub { 1 } );
	} 
1;	
