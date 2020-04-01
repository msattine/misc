#!/usr/bin/perl

use Math::BigInt;
use Getopt::Long;
use List::Util qw/shuffle/;
GetOptions (
	    "size=i",	# Size of DM-Cache
	    "osize=i",	# Size of PM-Cache
	    "seed=i",	# Seed
	    "h"
	);

if(defined $opt_h || defined $opt_help){ usage();exit(0);}

sub print_banner{
	$fh = shift;
	print $fh "/*	This test is dumped by ATG: $0	*/\n";
}

sub usage {
print qq#
>>> Help
           -h/help           	Prints this page
           -size		Size of DM-Cache
           -osize		Size of PM-Cache
	   \n#;
}

exit(0);

