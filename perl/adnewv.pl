#!/usr/local/bin/perl 

use Getopt::Long;

GetOptions ("fname=s",
	    "mname=s",
	    "tmname=s",
	    "auth=s",
	    "add",
	    "help",	# help
	    "h"
	);

if(defined $opt_h || defined $opt_help){ usage();exit(0);}

   chop(local $sdate = `date +%d-%m-%Y`);
   chop(local $stime = `date +%H:%M:%S`);

$vFileName = $opt_fname;
$vModuleName = $opt_mname;
$vTopModuleName = $opt_tmname;
$authorName = $opt_auth;
$Revision = ' $Revision: 1.1 $ '; #Rev no: written by RCS on checkin
$Revision =~ s/\$//g;    #Discard all except revision number
$Revision =~ s/^.*://;
$cwd = $ENV{PWD};  #$cwd holds current directory
$user = $ENV{USER};


#######START WRITING NEW VERILOG FILE

   open (NEWVFILE, "> temp.v") || die "Failed to create temp.v\n";
   print NEWVFILE "//   (C) Analog Devices India Product development Center\n";
   print NEWVFILE "//                All Rights Reserved\n";
   print NEWVFILE "//   File created by \"adnewv\" script on $sdate; $stime\n";
print NEWVFILE "//*************************************************************\n";
print NEWVFILE "\n";
print NEWVFILE "   //Module Name        : $vModuleName\n";
print NEWVFILE "   //Top Module         : $vTopModuleName\n";
print NEWVFILE "   //Target             : Synthesis\n";

print NEWVFILE "   //Original Authors   : $authorName ($user); $sdate\n";
print NEWVFILE "   //Revised By         : \n";
print NEWVFILE "   //Revised By         : \n\n";

print NEWVFILE "//\$Header: /sos_db/ada4574/ada4574_sos.rep/TEMP/sujeshp_1456145140/digital#bin#adnewv,v 1.1 $sdate $stime $user Exp $ \n\n";
print NEWVFILE "//Revision History: See File Trailer\n";
print NEWVFILE "//*****************\n\n";

print NEWVFILE "//Functional Description:\n";
print NEWVFILE "//***********************\n";

print NEWVFILE "\n//Known Bugs:\n";
print NEWVFILE "//**********\n\n";

print NEWVFILE "//Unregistered outputs/ Other notes:\n";
print NEWVFILE "//**********************************\n\n";

print NEWVFILE
"//**********************************************************************\n";
print NEWVFILE "//            START OF CODE\n";
print NEWVFILE
"//**********************************************************************\n\n";

if(defined $opt_add){
   	open (INPF, "< $vFileName") || die "Failed to open $vFileName\n";
	while(<INPF>){
		print NEWVFILE $_;
	}
	close(INPF);
}
else{
	print NEWVFILE "module $vModuleName (\n";
	#print NEWVFILE "   //Enter port names here, one per line";
	#print NEWVFILE "\n   //Follow the order: inputs first, then outputs, then inouts\n\n";
	#print NEWVFILE ");\n\n\n   //Enter Signal declarations in the order:\n";
	#print NEWVFILE "   //inputs outputs inouts wires regs\n\n";
	print NEWVFILE ");\n\nendmodule   // $vModuleName\n\n";
}

print NEWVFILE "//**********************************************************************\n";
print NEWVFILE "//            REVISION HISTORY\n";
print NEWVFILE
"//**********************************************************************\n\n";

print NEWVFILE "   //\$Log\$\n";
close(NEWVFILE);

`mv temp.v $vFileName`;

sub usage {
print qq#
>>> Help
           -h/help           	Prints this page
           -fname		Verilog file name
           -mname		Verilog Module design name
           -tmname		Top Module design name
           -auth		Author name
Sample Usage: ./adnewv.pl -auth Mohan -fname dp_top.v -mname dp_top -tmname digital_top --> to generate new file with headers
	      ./adnewv.pl -fname dp_top.v -add -auth Mohan -mname dp_top -tmname digital_top --> to add header to the existing verilog file
	   \n#;
}


exit;



   
################################################################
# Revision History:
################################################################
#
#    $Log: digital#bin#adnewv,v $
#    Revision 1.1  2016-06-13 22:27:26-07  sujeshp
#    Script to create new verilog files with basic information ( legacy PDSP script)
#

