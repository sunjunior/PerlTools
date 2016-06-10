use strict;
use Cwd;
use Spreadsheet::ParseXLSX;
use Win32::OLE;
use Encode;
$Win32::OLE::Warn = 3;


my $inputpath = getcwd;

opendir DIR, $inputpath or die "can not open the file\n";

my @filename =readdir(DIR);
close(DIR);

chomp(@filename);

my $xlstime;
my $xls6100;
my $xlscss;


for (@filename) {
    $xls6100 = $_ if m#6100-.*xlsx$#;
	$xlscss = $_ if m#(css|CSS)-.*xlsx$#;
	$xlstime = $_ if m#(time|TIME)-.*xlsx$#; 
}

die 'can not find all the xlsx file!' if !defined $xlstime 
                                  || !defined $xls6100 || !defined $xlscss;

$xlstime = "$inputpath/$xlstime";
$xls6100 = "$inputpath/$xls6100";
$xlscss = "$inputpath/$xlscss";

print $xlstime."\n";
print $xls6100."\n";
print $xlscss."\n";

 ###############################################################

#TIME项目代码文件
my $parsertime = Win32::OLE->GetActiveObject('Excel.Application');
die "Excel not installed" if $@;

unless (defined $parsertime) {
    $parsertime = Win32::OLE->new('Excel.Application', sub {$_[0]->Quit;})
            or die "Oops, cannot start Excel";
}
                                                       # application or open new
my $workbooktime = $parsertime->Workbooks->Open($xlstime); # open Excel file
if ( !defined $workbooktime ) {
 die $parsertime->error(), ".\n";
}

my $worksheettime = $workbooktime->Worksheets(5);

 #6100项目中TIME代码变更文件
my $parser6100 = Spreadsheet::ParseXLSX->new();
my $workbook6100 = $parser6100->parse($xls6100);
if ( !defined $workbook6100 ) {
 die $parser6100->error(), ".\n";
}


#CSS项目中TIME代码变更文件
my $parsercss = Spreadsheet::ParseXLSX->new();
my $workbookcss = $parsercss->parse($xlscss);
if ( !defined $workbookcss ) {
 die $parsercss->error(), ".\n";
}


my $worksheet6100  = $workbook6100->worksheet(4); #spreadsheet index start from 0
 my ( $row_min, $row_max ) = $worksheet6100->row_range();
 my ( $col_min, $col_max ) = $worksheet6100->col_range();

for my $row ($row_min.. $row_max){

  my $cell = $worksheet6100->get_cell( $row, 0 );
  next unless $cell;
  
  if ($cell->value() eq decode('GBK',"时钟平台"))
  {
  	 for my $col ( $col_min .. $col_max ) {
  	 	$cell = $worksheet6100->get_cell( $row, $col);
  	 	$worksheettime->Cells(4,$col+1)->{Value} = encode('GBK', $cell->value());
   }
  }
}

my $worksheetcss  = $workbookcss->worksheet(4);
( $row_min, $row_max ) = $worksheetcss->row_range();
( $col_min, $col_max ) = $worksheetcss->col_range();

for my $row ($row_min.. $row_max){

  my $cell = $worksheetcss->get_cell( $row, 0 );
  next unless $cell;
  
  if ($cell->value() eq decode('GBK',"时钟平台"))
  {
  	 for my $col ( $col_min .. $col_max ) {
  	 	$cell = $worksheetcss->get_cell( $row, $col);
        $worksheettime->Cells(5,$col+1)->{Value} = encode('GBK', $cell->value());   
    }
  }
}

$worksheettime->Range("A6")->{'Value'}=[["总计"]];#设置单元格的值
for my $col ('B'..'N')
{	
	my $rowtime = "${col}6";
	$worksheettime->Range($rowtime)->{FormulaR1C1}= "=SUM(R[-2]C:R[-1]C)";
}

$workbooktime->Save;
$workbooktime->Close;
$parsertime->quit;


