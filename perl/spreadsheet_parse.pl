#!/usr/local/bin/perl

use Spreadsheet::ParseExcel;
my $parser    = Spreadsheet::ParseExcel->new();
my $workbook  = $parser->parse('san_signals.xls');

if(!defined $workbook){ print "Workbook not found\n"; die;}

my $txt_file;
open(TXT_FILE,'>',"santhu_parse.txt")||die;
for my $worksheet ($workbook->worksheets()){
	my($row_min, $row_max) = $worksheet->row_range();
	my($col_min, $col_max) = $worksheet->col_range();
	for my $row ($row_min..$row_max){
		for my $col ($col_min..$col_max){
			my $cell = $worksheet->get_cell($row,$col);
			next unless $cell;
			my $val = $cell->value();
			print TXT_FILE "$val"."\n";
		}
	}
}
close(TXT_FILE);

exit(0);
