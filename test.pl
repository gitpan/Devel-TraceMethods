# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Devel::TraceMethods;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package TraceMe;

sub foo {}

sub bar {}

package TraceMe2;

@TraceMe2::ISA = qw ( TraceMe );

sub new {
	bless({}, $_[0]);
}

sub bar {}

package main;

use Devel::TraceMethods qw ( TraceMe );

# this lets us see what's logged
my $result;
Devel::TraceMethods::callback(sub { $result = "Called $_[0]" });

# standard call
TraceMe::foo();
if ($result eq 'Called foo') {
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

# should not be logged or inherited
$result = '';
TraceMe2::bar();
if (!$result) {
	print "ok 3\n";
} else {
	print "not ok 3\n";
}

# should be inherited
my $t2 = TraceMe2->new();
if ($t2->can('foo')) {
	print "ok 4\n";
} else {
	print "not ok 4\n";
}

# inherited call should be logged
$t2->foo();
if ($result eq 'Called foo') {
	print "ok 5\n";
} else {
	print "not ok 5\n";
}

# non-inherited method should not be logged 
$result = '';
$t2->bar();
if (!$result) {
	print "ok 6\n";
} else {
	print "not ok 6\n";
}

# now let's log TraceMe2
Devel::TraceMethods->import( TraceMe2 );

# it should provide a result now
$result = '';
$t2->bar();
if ($result eq 'Called bar') {
	print "ok 7\n";
} else {
	print "not ok 7\n";
}

# let's try replacing the logging sub
Devel::TraceMethods->callback(sub { $result = $_[0] });
$result = '';
$t2->bar();
if ($result eq 'bar') {
	print "ok 8\n";
} else {
	print "not ok 8\n";
}
