#!/cad/adi/apps/gnu/linux/x86_64/5u5/bin/perl -w

use Verilog::Netlist;
use Verilog::Getopt;
use Getopt::Long;
GetOptions (
	    "cnfg=s"
	);

if(!defined $opt_cnfg){
	print "Enter valid config path\n";
	exit(0);
}

my $opt = new Verilog::Getopt;
$opt->define("RESET_DEFINE", 0);
$opt->parameter("+incdir+verilog", "-y", "verilog",);

my $top_dir = "$opt_cnfg/digital/design";
my $mod_rtl_dir = "fault_inj";
my $inc_list;
my $rtl_list;
my $top_module;
my $fault_list;
my %modified_file_dict;
my %module_net_dict;
my %flt_inj_dict;

my %orig_rtl_dict;

foreach $j (`cat change/file.list`){
	chomp($_);
	$fname = $_;
	$fname =~ s/^(.*)\///;
	$orig_rtl_dict{$fname} = $_;
}

foreach $j (`ls $top_dir/sub_blocks_p/ | grep -v tempsense_p`){
	chomp($j);
	foreach $fname(`ls $top_dir/sub_blocks_p/$j/rtl/`){
		chomp($fname);
		if(!exists($orig_rtl_dict{$fname})){ $orig_rtl_dict{$fname} = "$top_dir/sub_blocks_p/$j/rtl/$fname";}
	}
}
foreach $j (`ls $top_dir/sub_blocks_s/ | grep -v saradc_s`){
	chomp($j);
	foreach $fname(`ls $top_dir/sub_blocks_s/$j/rtl/`){
		chomp($fname);
		if(!exists($orig_rtl_dict{$fname})){ $orig_rtl_dict{$fname} = "$top_dir/sub_blocks_s/$j/rtl/$fname";}
	}
}
foreach $fname(`ls $top_dir/digital_top_p/rtl/`){
	chomp($fname);
	if(!exists($orig_rtl_dict{$fname})){ $orig_rtl_dict{$fname} = "$top_dir/digital_top_p/rtl/$fname";}
}
foreach $fname(`ls $top_dir/digital_top_s/rtl/`){
	chomp($fname);
	if(!exists($orig_rtl_dict{$fname})){ $orig_rtl_dict{$fname} = "$top_dir/digital_top_s/rtl/$fname";}
}

`rm -rf $mod_rtl_dir/*`;

my $mod_file_list = "$mod_rtl_dir/modified_rtl.list";
open(MODFILES, '>', $mod_file_list);

#else{
#	$rtl_list = "glob_rtl_file.list";
#	$inc_list = "glob_inc.list";
#}

my $n1 = new Verilog::Netlist(options=>$opt);
# Include directories
foreach $j(`find $top_dir/ -name include -type d -maxdepth 3`){
	chomp($j);
	$opt->incdir($j);
}

# read all rtl files
my %file_module_dict;
foreach $key(keys %orig_rtl_dict){
	$n1->read_file(filename => $orig_rtl_dict{$key});
	$mname = $key;
	$mname =~ s/\.sv//;
	$mname =~ s/\.v//;
	$file_module_dict{$mname} = $orig_rtl_dict{$key};
}

$n1->link();
$n1->lint();

# Parse rtl files to inject mux for fault injection
$num = 0;
$top_module = "ada4574_digtop_p";
foreach $j(`cat prim_fault.list`){
	chomp($j);
	$opt_hname = $j;
	print parse_node($num, $top_module, $opt_hname) . "\n";
	$num = $num + 1;
}
$top_module = "ada4574_digtop_s";
foreach $j(`cat sec_fault.list`){
	chomp($j);
	$opt_hname = $j;
	print parse_node($num, $top_module, $opt_hname) . "\n";
	$num = $num + 1;
}
$top_module = "lptc_dig_pvdd";
foreach $j(`cat lptc_fault.list`){
	chomp($j);
	$opt_hname = $j;
	print parse_node($num, $top_module, $opt_hname) . "\n";
	$num = $num + 1;
}

foreach $mod_name(keys %flt_inj_dict){
	$file = $file_module_dict{$mod_name};
	$file =~ s/^.*\///;
	open(INFILE, '<', "$mod_rtl_dir/$file");
	open(OUTFILE, '>', "$mod_name.v");
	while(<INFILE>){
		if($_ =~ m/^(\s*?)endmodule/){
			$end_line = $_;
			print OUTFILE "`ifdef FPGA_FI\n";
			@net_names = keys %{$flt_inj_dict{$mod_name}};
			$num_flts = @net_names;
			$num_flts = $num_flts - 1;
			print OUTFILE "logic [$num_flts:0] f_s, f;\n";
			$flt_num = 0;
			foreach $net_name(@net_names){
				print OUTFILE "assign $net_name = f_s[$flt_num] ? f[$flt_num] : ${net_name}_wqf;\n";
				$flt_num = $flt_num + 1;
			}
			$flt_num = 0;
			print OUTFILE "\n\nsyn_hyper_source i_syn_hyper_source(\n";
			foreach $net_name(@net_names){
				$fnum = $flt_inj_dict{$mod_name}{$net_name};
				if($flt_num == $num_flts){print OUTFILE "\t\t\t\t.f${fnum}_s(f_s[$flt_num]),\n\t\t\t\t.f$fnum(f[$flt_num]));\n";}
				else {print OUTFILE "\t\t\t\t.f${fnum}_s(f_s[$flt_num]),\n\t\t\t\t.f$fnum(f[$flt_num]),\n";}
				$flt_num = $flt_num + 1;
			}
			print OUTFILE "defparam i_syn_hyper_source.tag = \"amr\";\n`else\n";
			foreach $net_name(@net_names){
				print OUTFILE "assign $net_name = ${net_name}_wqf;\n";
			}
			print OUTFILE "`endif\n";

			print OUTFILE $end_line;
		}
		else{ print OUTFILE $_;}
	}
	close(INFILE);
	close(OUTFILE);
	`mv $mod_name.v $mod_rtl_dir/$file`;
}

foreach $j (keys %modified_file_dict){
	print MODFILES "$file_module_dict{$j} : $modified_file_dict{$j}\n";
}
close(MODFILES);

sub parse_node{ # To find all the involved modules for a given fault signal from top module
	my $fnum = shift;
	my $modname = shift;
	my $chname = shift;
	my $cinst_name;
	my $cmod = $n1->find_module($modname);
	if(defined $cmod){
		if($chname !~ m/\./){
			#$dcount --;
			my $cnet = $cmod->find_net($chname);
			if(defined $cnet){
				$nreg = $cnet->data_type();
				$is_reg = 1;
				if($nreg ne "reg"){
					$nreg = "wire";
					$is_reg = 0;
				}
				my $cnet_name = $cnet->name();
				if($cnet->name() eq $chname){ 
					$port = $cmod->find_port($chname);
					$is_port = 0;
					if(defined $port){ $is_port = 1;}
					inject_fault_mux($fnum, $file_module_dict{$modname}, 0, " ", $modname, $cnet_name, $is_port, $is_reg, 0);
					return $chname . "-$nreg";
				}
				else{ return "$chname Not found1";}
			}
			else{ 
				if($modname =~ m/SPI_TOP/){
					inject_fault_mux($fnum, $file_module_dict{$modname}, 0, " ", $modname, $chname, 0, 0, 1);
					return $chname . "-wire";
				}
				else {return "$chname Not found2";}
			}
		}
		else{
			$chname =~ s/^([^\.]+)\.//;
			$cinst_name = $1;
			my $cinst_cell = $cmod->find_cell($cinst_name);
			#if($chname !~ m/\./){ $cnnet = $cinst_cell->find_pin($chname); if(defined $cnnet){$nnet = $cnnet->net; print $cnnet->name . "::"; if (defined $nnet){ print "-N-".$nnet->name . "\n";}else{$nport = $cnnet->port;if(defined $nport){print "-P-".$nport->name . "\n";}}}else{print "$cinst_name.$chname :: NOT FOUND\n";}}
			if(!defined $cinst_cell){ return "$cinst_name.$chname Not found3";}
			my $cinst_modname = $cinst_cell->submodname();
			if(!defined $cinst_modname){ return "$cinst_name.$chname Not found4";}
			my $nmod = $n1->find_module($cinst_modname);
			if(!defined $nmod){ return "$cinst_name.$chname Not found5";}
			my $nres = parse_node($fnum, $cinst_modname, $chname);
			#if($dcount >= 0) { print $hnlist $nmod->verilog_text() . "\n";}
			#$dcount --;
			if(exists($file_module_dict{$cinst_modname})) {
				#inject_fault_mux($file_module_dict{$modname}, 1, $cinst_name, $cinst_modname, "", 0, 0);
				return "$cinst_modname($cinst_name)<--" . $nres;
			}
			else{
				return "File Not Found $cinst_modname($cinst_name)<--" . $nres;
			}
		}
	}
	else {return "$chname Not found0";}
}

sub inject_fault_mux{
	my $fnum = shift;
	my $file = shift;
	my $type = shift;
	my $inst_name = shift;
	my $mod_name = shift;
	my $net_name = shift;
	my $is_port = shift;
	my $is_reg = shift;
	my $decl = shift;
	open(INFILE, '<', $file);
	my $ftop = "fpga_top.fault_cntrl";
	my $flag = ""; #"// FPGA fault injection hack";
	my $flag1 = ""; #"/*FPGA fault injection hack*/";

	$file_name = $file;
	$file_name =~ s/^.*\///;
	if(!exists($modified_file_dict{$mod_name})){
		`cp $file $mod_rtl_dir/$file_name`;
		`chmod u+w $mod_rtl_dir/$file_name`;
	}

	while(<INFILE>){
		chomp($_);
		while(<INFILE>){last if($_ =~ m/^(\s*?)module/);}
		while(<INFILE>){ last if ($_ =~ m/\);/ && $_ !~ m/^\(\s*?\/\//);}
		$l1 = $.;
		$l2 = $l1 + 1;
		while(<INFILE>){
			if($_ =~ m/^(\s*?)input/ || $_ =~ m/^(\s*?)output/){ $l2 = $. + 1;}
		}
	}
	close(INFILE);

	open(OUTFILE, '>', "$mod_name.v");
	open(INFILE, '<', "$mod_rtl_dir/$file_name");
	while(<INFILE>){
		if($. == $l2){
			if($decl){ print OUTFILE "\nwire $net_name; $flag\n";}
			if($is_reg) {print OUTFILE "\nreg ${net_name}_wqf; $flag\n";}
			else {print OUTFILE "\nwire ${net_name}_wqf; $flag\n";}
			print OUTFILE $_;
		}
		else{ 
			if($_ =~ m/^(\s*?)endmodule/ && $type == 0){
				#print OUTFILE "assign ${net_name} = $ftop.fault${fnum}_cntrl ? $ftop.fault${fnum}_drv : ${net_name}_wqf; $flag\n";
				$flt_inj_dict{$mod_name}{$net_name} = $fnum;
			}
			elsif($_ =~ m/reg(\s*?)$net_name/){
				$_ =~ s/reg(\s*?)$net_name(\s*?)([;,\n])/wire$1$net_name$2$flag1$3/;
			}
			elsif($. > $l2 && $type == 0){
				$net_name_qr = qr/\b$net_name\b/;
				if($_ =~ m/\.$net_name/){ $_ =~ s/\((\s*?)$net_name(\s*?)\)/\($1${net_name}_wqf$2$flag1\)/;}
				elsif($_ !~ m/^(\s*?)wire/) {$_ =~ s/$net_name_qr/${net_name}_wqf$flag1/g;}
			}
			print OUTFILE $_;
		}
	}
	
	close(INFILE);
	close(OUTFILE);
	`mv $mod_name.v $mod_rtl_dir/$file_name`;
	if(!exists($modified_file_dict{$mod_name})){
		$modified_file_dict{$mod_name} = 1;
	}
	else{
		$modified_file_dict{$mod_name} = 1 + $modified_file_dict{$mod_name};
	}

	if(exists($module_net_dict{$mod_name}{$net_name})){ print "$mod_name -- $net_name ALREADY EDITED -- multiple instances of same module\n";}
	else{$module_net_dict{$mod_name}{$net_name} = 1;}
}

exit(0);
