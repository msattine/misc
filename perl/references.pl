#!/usr/local/bin/perl


#	Reference to array
my @x = (1,2,3,4,5,6);

$xr = \@x; # referencing array
print "$xr\n"; # prints the starting address, where array @x is stored
print scalar(@$xr)."\n"; # Getting length of array with its reference
print "$$xr[3] -- $xr->[3]\n"; # Accessing element of array from its reference

#	Anonymous data
$x = [4,1,6,7];
print "$x\n"; # prints the starting address, where array @x is stored
print "$x->[1] -- $$x[1]\n";

$line = "fed up code";
$line =~ s/[^aeiou]/p/g;
print $line."\n";


# Differences between perl references and C pointers
	#C pointer is just an integer, can add to it, ask to give value pointed at 5 places further 
	#Adding something to a reference, result is a number and not a reference
	#C pointer knows size of each element (Incrementing it by one points to next element)
	#Perl refernce knows how many elements are there at that reference
$y = $x + 1;
$x = $x + 1;
 print "$y -- $y->[2]\n";
 print "$x -- $x->[2]\n";
