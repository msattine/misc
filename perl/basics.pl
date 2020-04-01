#!/usr/local/bin/perl

#Perl acronymn
	# Practical Extraction and Reporting Language
	# Process text file for usefull info and report
	# Automating
	# simchip.pl and smart_goofy.pl are examples.


#First line

#running script from command line
	#Using perl <script.pl>
	#Using setenv and use the name directly
	#Using name directly if in same directory.
	#Running from another perl script
	# Using perl -e from command line
		# Ex: perl -e '$a = 10; $b = 10; $, = " "; print $a, $b, $a + $b, "\n";'

my $arg1 = shift @ARGV;
sub prpto_ex;

if($arg1 == 1) {
#Types
	#scalar
	my $scalar1; $scalar1 = "perl5";
	my $scalar = 34;
	$scalar2 = 456.7;
	my ($sc1, $sc2, $sc3) = (3,"sc2",5); # $sc1 = 3, $sc2 = "sc2" and $sc3 = 5;
	# operations on scalar string
	# substr EXPR, OFFSET, LENGTH, REPLACEMENT;
	my $string1 = "This is perl script";
	$sub_str1 = substr $string1, 8, 4;
	# concatenation, replication operator

	#array
	my @array = (1,2,"script",3,4);
	#accessing using index
	print $array[2], "\n";
	$array[3] = 34.1;
	push @array, $scalar1;
	push @array, ("stud", "food",3);
	($sc4, @array2) = (1,2,3,5,"many");
	push @array2, @array;
	@array3 = @array[3 .. $#array]; # '$#<array_name>' -> gives index of last element of <array>
	print scalar(@array) , "\n";
	# splice @<array>, OFFSET, LENGTH, REPLACEMENT;
	@array4 = splice @array, 2, 5;
	print scalar(@array) , "\n";
	$val1 = shift @array;
	# Processing entire array
	foreach my $val (@array) { }# processing;
	# Reversing array
	@array1 = reverse @array;
	# sorting array elements
	@array1 = sort {$a <=> $b} @array;  # Numerical sort
	@array2 = sort {$a cmp $b} @array;  # Lexographic sort
	@array3 = (1..100);

	#hash : '% is the prefix used for hashes
	my %student_marks = ('Rajesh', 34, 'Rakesh', 67);
	%score = ( 'Brazil' => 3,
		   'Italy' => 5
		);
	# accessing hash elements
	print $student_marks{'Rajesh'}, "\n";
	print $score{Brazil} . "\n";
	$score{'India'} = 4;
}


elsif ($arg1 == 2){
#subroutines
	#special variables
		#@ARGV, $_, @_., etc
	#parameter passing
	#parameter receiving in function
	#returning
	
}


elsif ($arg1 == 3){
#File handling
	# Default file handlers STDIN, STDOUT, STDERR
	#RO, WO, RW options
	#while loop / foreach loop
	#die option
	#special variables
		# $_, $. ., etc
	open (IN,'<dat1.txt') || die "File dat1.txt is not found\n";
	open ($out,'>', 'dat2.txt') || die " Can't create dat2.txt file in current directory\n";
	while(<IN>){
		chomp; # removes any newline character
		if(m/griffin/){
			print "Found griffin in line $.\n";
			print $out "griffin lite\n";
		}
		$_ =~ s/sharc/sharc11/;
		print $out $_ . "\n";
	}
	close(IN);
	close($out);
	exit(3);

	# Read and write, Append operators
}

#Regular expressions
	#matching, search and replace, translation
	#special variables
	#more examples
 
#Running linux commands
	#Usage example
	#Types available (system, backticks, exec and open)

#Hashes
	#Usage example

#References
	#Usage example

#Modules, Packages
	#Using installed packages
	#Using Packages which are not installed
	#Installing package

	#use <packages>
	#Name spaces
	#Using functions in packages
	#Scope of variables
	#my and our differences
if($arg == 1) {
	my $cmd = "perl /proj/sharc11/pwa/msattine/Execs/perl_session/";
	system("$cmd");
}

#Spreadsheet Package
	#Read example
	#Write example


#Subroutines

sub max_ele {
	# '@_' is a special array variable that gives the list of arguments passed to this subroutine
	my $el1 = $_[0];
	my $el2 = $_[1];
	if($el1 > $el2) { $el1;} # Subroutine with no return statement will return the result of last executed expression in its body
	else{ $el2;}
}


sub max_in_array {
	my $max_so_far = shift @_;
	foreach $var (@_){ $max_so_far = $var if $var > $max_so_far;}
	return $max_so_far;
}

sub protp_ex($;$){
	my ($arg1, $arg2) = @_;
	if(defined $arg2) { print "Only one argument passed : $arg1\n";}
	else { print "Two args passed\n";}
}

sub rand_data($$$){
	my ($max, $min, $num_rand) = @_;
	my @rand_array;
	for($i = 0; $i < $num_rand; $i++){
		push @rand_array, int(rand($max - $min)) + $min;}
	return @array;
}


exit(0);
