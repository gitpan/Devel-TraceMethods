package Devel::TraceMethods;

use strict;
use Carp qw ( carp croak );
use vars qw($VERSION);

$VERSION = '0.50';

sub import {
	my $package = shift;

	for my $caller (@_) {
		my $src;

		# get the calling package symbol table name
		{
			no strict 'refs';
			$src = \%{$caller . '::'};
		}
	
		# loop through all symbols in calling package, looking for subs
		foreach my $symbol (keys %$src) {
			my ($sub, @slots);

			# get all code references, make sure they're valid
			$sub = *{$src->{$symbol}}{CODE};
			next unless (defined $sub and defined &$sub);

			# save all other slots of the typeglob
			foreach my $slot (qw( SCALAR ARRAY HASH IO FORMAT )) {
				my $elem = *{ $src->{$symbol} }{$slot};
				next unless defined $elem;
				push @slots, $elem;
			}

			# clear out the source glob 
			# 	undef &{ *{$src->{$symbol}} } didn't work for some reason
			undef $src->{$symbol};

			# replace the sub in the source
			$src->{$symbol} = sub {
				logCall->($symbol, @_);
				return $sub->(@_);
			};

			# replace the other slot elements
			foreach my $elem (@slots) {
				$src->{$symbol} = $elem;
			}
		}
	}
}

{

	my $logger = \&Carp::carp;

	# set a callback sub for logging
	sub callback {
		# should allow this to be a class method :)
		shift if @_ > 1;

		my $coderef = shift;
		croak("$coderef is not a code reference!") 
			unless (ref($coderef) eq 'CODE' and defined(&$coderef));	
		$logger = $coderef;
	}

	# where logging actually happens
	sub logCall {
		$logger->(@_);
	}
}


1;

__END__
=head1 NAME

Devel::TraceMethods - Perl module for tracing module calls

=head1 SYNOPSIS

  use Devel::TraceMethods qw ( PackageOne PackageTwo );

=head1 DESCRIPTION

Devel::TraceMethods allows you to attach a subroutine of your choosing to all
of the methods and functions within multiple packages or classes.  You can use
this to trace execution.  It even respects inheritance.

To enable logging, simply pass the name of the packages you wish to trace on
the line where you use Devel::TraceMethods.  It will automatically install
logging for all functions in the named packages.

You can also call C<import()> after you have C<use()>d the module if you want
to log functions and methods in another package.

By default, Devel::TraceMethods will use C<Carp::carp()> to log a method call.
You can change this with the C<callback()> function.  Simply pass a subroutine
reference as the only argument, and all subsequent calls to logged methods will
use the new subroutine reference instead of C<carp()>.

The first argument to the logging subroutine is the name of the logged method.  
(I wish that sentence were clearer.)  The rest of the arguments are those being
passed to the logged method.  If you really really need to modify them, you can.
If you do and it breaks your program, try to be more careful next time.  You
should probably just print or ignore them.

=head1 TODO

=over

=item Attach to calling package if nothing is specified in @_?  Something like:

	push @_, scalar caller() unless @_;

=item Attach only to specified methods.

=item Add ability to disable logging on certain methods.

=item Allow multiple logging subs.

=item Allow per-method logging sub?

=item Don't copy other slots of typeglob?  (Could be tricky, an internals
wizard will have to look at this.)

=back

=head1 AUTHOR

 13 June 2001
 chromatic, chromatic@wgz.org

based on a suggestion by tye at PerlMonks, enhanced with a callback suggestion
by grinder at PerlMonks.

=head1 SEE ALSO

perl(1).

=cut
