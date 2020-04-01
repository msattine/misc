#!/usr/local/bin/perl

use Spreadsheet::WriteExcel;
my $workbook  = Spreadsheet::WriteExcel->new('san_signals.xls');
my $worksheet = $workbook->add_worksheet();
$worksheet->write(0, 6,  "Module Connections");

my $txt_file;
open(TXT_FILE,'<',"santhu.txt")||die;
@arr1 = <TXT_FILE>;
close(TXT_FILE);

$arr_size = @arr1;
my @tmp_arr1;

for ($i = 0; $i < $arr_size; $i ++){
	$arr1[$i] =~ s/CONN_MAP ://;
	$line = $arr1[$i];
	while($line =~ m/(^.*): (.*); ([^;]+);/){  $l1 = "$1: $3;\n"; push @tmp_arr1, $l1; $line =~ s/(^.*): ([^;]+);(.*);/$1: $2;/;}
	$arr1[$i] = $line;
}

push @arr1, @tmp_arr1;
@arr1 = sort{$a cmp $b} @arr1;
$arr_size = @arr1;
open($tmp,'>',"temp.txt")||die;
for ($i = 0; $i < $arr_size; $i ++){
	if($arr1[$i] =~ m/(^.*)\[([0-9]+)\]:/){
		my %tmp;
		$mcmp = $1;
		$k = $i;
		while($arr1[$i] =~ m/$mcmp\[/){$t1 = $arr1[$i]; $t1 =~ s/(^.*)\[([0-9]+)\]: (.*)$/$2/g; chomp($t1); $t1 =~ s/ //g;
			$tmp{$t1} = $arr1[$i]; $i++;
		}
		foreach $key (sort{$a <=> $b} keys %tmp){$arr1[$k] = $tmp{$key}; $k++;}
		$i = $i - 1;
	}
}

my %signals;
my @comp_arr;
my $prev_mod_i = "NULL";
my $prev_mod_o = "NULL";

$arr_size = @arr1;
my @new_arr;
my $comprsd_size = 0;

#print $out "\nCompressed\n";
for($i = 0; $i < $arr_size; $i++){
	if($arr1[$i] =~ m/(^.*)\[([0-9]+)\]: (.*)\[([0-9]+)\];/){
		$m1 = $1;
		$n1 = $2;
		$m2 = $3;
		$n2 = $4;
		$k1 = $n1; $k2 = $n2;
		while($arr1[$i] =~ m/$m1\[$k1\]: $m2\[$k2\];/){$k1++; $k2++; $i++}
		$k1--; $k2--; $i--;
		$new_arr[$comprsd_size++] = "$m1\[$k1:$n1\]: $m2\[$k2:$n2\];\n";
		#print $out "$new_arr[$comprsd_size -1]";
	}
	elsif($arr1[$i] =~ m/(^.*)\[([0-9]+)\]: UNKNOWN;/){
		$m1 = $1;
		$n1 = $2;
		$k1 = $n1;
		while($arr1[$i] =~ m/$m1\[$k1\]: UNKNOWN;/){$k1++; $i++}
		$k1--; $i--;
		$new_arr[$comprsd_size++] = "$m1\[$k1:$n1\]: UNKNOWN;\n";
		#print $out "$new_arr[$comprsd_size -1]";
	}
	else{
		$new_arr[$comprsd_size++] = $arr1[$i];
		#print $out "$new_arr[$comprsd_size -1]";
	}
}

foreach $v (@new_arr){ print $tmp "$v";}
close($tmp);

open($out,'>',"santhu1.txt")||die;
print $out "Compressed size : $comprsd_size\n";

my %connection, %connected_to_mod, %connected_to_sig, %Num_bits;
$tot_found = 0;
foreach $line (@new_arr){
	chomp($line);
	if($line =~ m/(^.*)\.([^\.]+): (.*)\.([^\.]+);/){
		$m_o = $1; $m_i = $3; $sig_o = $2; $sig_i = $4;
		if($sig_o =~ m/\[([0-9]+):([0-9]+)\]/){
			$num_of_bits = $1 - $2 + 1;
		}
		else{$num_of_bits = 1;}
		if(exists $connection{$m_o}{"OUT"}{$sig_o}){
			$connected_to_mod{$m_o}{"OUT"}{$sig_o} .= ",$m_i";
			$connected_to_sig{$m_o}{"OUT"}{$sig_o} .= ",$sig_i";
			$Num_bits{$m_o}{"OUT"}{$sig_o} .= ",$num_of_bits";
		}
		else{
			$tot_found ++;
			$connection{$m_o}{"OUT"}{$sig_o} = 1;
			$connected_to_mod{$m_o}{"OUT"}{$sig_o} = $m_i;
			$connected_to_sig{$m_o}{"OUT"}{$sig_o} = $sig_i;
			$Num_bits{$m_o}{"OUT"}{$sig_o} = $num_of_bits;
		}
		if(exists $connection{$m_i}{"IN"}{$sig_i}){
			$connected_to_mod{$m_i}{"IN"}{$sig_i} .= ",$m_o";
			$connected_to_sig{$m_i}{"IN"}{$sig_i} .= ",$sig_o";
			$Num_bits{$m_i}{"IN"}{$sig_i} .= ",$num_of_bits";
		}
		else{
			$tot_found ++;
			$connection{$m_i}{"IN"}{$sig_i} = 1;
			$connected_to_mod{$m_i}{"IN"}{$sig_i} = $m_o;
			$connected_to_sig{$m_i}{"IN"}{$sig_i} = $sig_o;
			$Num_bits{$m_i}{"IN"}{$sig_i} = $num_of_bits;
		}
	}
	elsif($line =~ m/(^.*)\.([^\.]+): UNKNOWN;/){
		$m_o = $1; $sig_o = $2;
		if($sig_o =~ m/\[([0-9]+):([0-9]+)\]/){
			$num_of_bits = $1 - $2 + 1;
		}
		else{$num_of_bits = 1;}
		$tot_found ++;
		$connection{$m_o}{"OUT"}{$sig_o} = 0;
		$Num_bits{$m_o}{"OUT"}{$sig_o} = $num_of_bits;
	}
	else{print "Something is wrong $line \n";}
}
print "Total found = $tot_found\n";
my $mkey, $iokey, $sigkey;
my @mkeys = sort keys %connection;
print $out "\n\n To excel sheet\n";
my $current_row = 4, $current_col = 4;
foreach $mkey (@mkeys){
	my @iokeys = sort keys %{$connection{$mkey}};
	foreach $iokey (@iokeys){
		my @sigkeys = sort keys %{$connection{$mkey}{$iokey}};
		foreach  $sigkey (@sigkeys){
			$current_col = 4;
			if($connection{$mkey}{$iokey}{$sigkey} == 1){
				if($connected_to_mod{$mkey}{$iokey}{$sigkey} =~ m/,/){
					$mod_i = $connected_to_mod{$mkey}{$iokey}{$sigkey};
					$sig_i = $connected_to_sig{$mkey}{$iokey}{$sigkey};
					$num_bits = $Num_bits{$mkey}{$iokey}{$sigkey};
					my @mods,@sigs,@numbits;
					while($mod_i =~ m/,/){
						$mod_i =~ s/(^.*),([^,]+)$/$1/; push @mods,$2;
						$sig_i =~ s/(^.*),([^,]+)$/$1/; push @sigs,$2;
						$num_bits =~ s/(^.*),([^,]+)$/$1/; push @numbits,$2;
					}
					push @mods, $mod_i; push @sigs, $sig_i; push @numbits, $num_bits;
					print  $out "$mkey -- $iokey -- $sigkey -- $numbits[0] -- ";
					$worksheet->write($current_row, $current_col,  $mkey);
					$worksheet->write($current_row, $current_col + 1,  $iokey);
					$worksheet->write($current_row, $current_col + 2,  $sigkey);
					$worksheet->write($current_row, $current_col + 3,  $numbits[0]);
					for($i = 0; $i < @mods; $i++){
						if($i == 0) { print $out "$mods[0] -- $sigs[0]\n";
						}
						else{print  $out "					  $mods[$i] -- $sigs[$i]\n";}
						$worksheet->write($current_row + $i, $current_col + 4,  $mods[$i]);
						$worksheet->write($current_row + $i, $current_col + 5,  $sigs[$i]);
					}
					$current_row += @mods;
				}
				else{
					print  $out "$mkey -- $iokey -- $sigkey -- $Num_bits{$mkey}{$iokey}{$sigkey} -- $connected_to_mod{$mkey}{$iokey}{$sigkey} -- $connected_to_sig{$mkey}{$iokey}{$sigkey}\n";
					$worksheet->write($current_row, $current_col,  $mkey);
					$worksheet->write($current_row, $current_col + 1,  $iokey);
					$worksheet->write($current_row, $current_col + 2,  $sigkey);
					$worksheet->write($current_row, $current_col + 3,  $Num_bits{$mkey}{$iokey}{$sigkey});
					$worksheet->write($current_row, $current_col + 4,  $connected_to_mod{$mkey}{$iokey}{$sigkey});
					$worksheet->write($current_row, $current_col + 5,  $connected_to_sig{$mkey}{$iokey}{$sigkey});
					$current_row ++;
				}
			}
			else{
				print $out "$mkey -- $iokey -- $sigkey -- $Num_bits{$mkey}{$iokey}{$sigkey} -- UNKNOWN\n";
				$worksheet->write($current_row, $current_col,  $mkey);
				$worksheet->write($current_row, $current_col + 1,  $iokey);
				$worksheet->write($current_row, $current_col + 2,  $sigkey);
				$worksheet->write($current_row, $current_col + 3,  $Num_bits{$mkey}{$iokey}{$sigkey});
				$worksheet->write($current_row, $current_col + 4,  "UNKNOWN");
				$current_row ++;
			}
		}
	}
}
close($out);

exit(0);
