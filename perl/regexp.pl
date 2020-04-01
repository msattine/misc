#!/usr/local/bin/perl

#Regular expressions

# Use '==', '<', '>', '<=', '>=' and '!=' only with numericals
# Use 'eq', 'gt'. 'lt', 'le', 'ge', 'ne' with strings
$x = 233;
if($x == 233) { print "Dec X = 233\n";}
if($x eq '233') { print "Str X = 233\n";}

$x = 'str1';
$y = 'xr2';
if($x == $y) { print "Dec X = 233\n";}
if($x eq $y) { print "Str X = 233\n";}
$x = int('str1');
$y = int('23xr2');

print "x = $x and y = $y\n";


# Matching at beginning
my $line = "Matching at beginning";
if($line =~ /^at/){ print "It is starting with digit\n";}
elsif($line =~ /^Mat/){ print "It is starting with M\n";}

my $line = "Matching at end";
if($line =~ /en$/){ print "Ending with a digit\n";}
elsif($line =~ /end$/){ print "Ending with end\n";}
# Matching at end of line

# Different patterns

exit(0);
