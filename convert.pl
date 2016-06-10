use strict;
use Spreadsheet::ParseExcel::SaveParser;
use Encode;
#$ARGV[0] = "C:\\Users\\SUNJUN\\workspace\\WebCrawler\\";
#$ARGV[1] = "C:\\Users\\SUNJUN\\workspace\\WebCrawler\\codecheck\\";
print "source file:",$ARGV[0],"\n";
print "dest file:",$ARGV[1],"\n";
die 'please input the source path and dest path' if (scalar @ARGV !=2); 
my $inputpath = $ARGV[0];
my $outputpath = $ARGV[1];
opendir DIR, $inputpath or die "can not open the file\n";
mkdir $outputpath unless(-d $outputpath);
my @absinputpath;
my @absoutputpath;
my @filename =readdir(DIR);
close(DIR);

chomp(@filename);
for (@filename) {
    if($_ =~ m/\.xlsx$/)
    {
        push @absinputpath,$_;	
        push @absoutputpath,$_  if s#x$##;
    }
 
}
 @absinputpath = map { $inputpath.$_} @absinputpath;
 @absoutputpath = map {$outputpath.$_} @absoutputpath;

 for(my $idx = 0; $idx <= $#absinputpath; $idx++)
 {
    my $input = $absinputpath[$idx];
     my $output = $absoutputpath[$idx];
     my $cmd = "\"${inputpath}convertxlsx\\convertxlsx.exe\" /f \"$input\" \"$output\"\n";
     print "run cmd:", $cmd, "\n"; 
 	 system("$cmd");
 }
 sleep(5); #停顿5s
 
my $xls6100;
my $xlscss;
my $xlstime;
for (@absoutputpath)
{
	$xls6100 = $_ if m#6100.*xls$#;
	$xlscss = $_ if m#(css|CSS).*xls$#;
	$xlstime = $_ if m#(time|TIME).*xls$#;
}

 ###############################################################
 #6100项目中TIME代码变更文件
my $parser1 = Spreadsheet::ParseExcel->new();
my $workbook1 = $parser1->parse($xls6100);
if ( !defined $workbook1 ) {
 die $parser1->error(), ".\n";
}
#CSS项目中TIME代码变更文件
my $parser2 = Spreadsheet::ParseExcel->new();
my $workbook2 = $parser2->parse($xlscss);
if ( !defined $workbook2 ) {
 die $parser2->error(), ".\n";
}
#TIME项目代码文件
my $parser3 = Spreadsheet::ParseExcel::SaveParser->new();
my $workbook3 = $parser3->Parse( $xlstime);
if ( !defined $workbook3 ) {
 die $parser3->error(), ".\n";
}
 
my $worksheet3  = $workbook3->worksheet(4);
 


my $worksheet1  = $workbook1->worksheet(4);
 my ( $row_min, $row_max ) = $worksheet1->row_range();
 my ( $col_min, $col_max ) = $worksheet1->col_range();

for my $row ($row_min.. $row_max){

  my $cell = $worksheet1->get_cell( $row, 0 );
  next unless $cell;
  
  if ($cell->value() eq decode('GBK',"时钟平台"))
  {
  	 for my $col ( $col_min .. $col_max ) {
  	 	$cell = $worksheet1->get_cell( $row, $col);
#  	    print "Row, Col    = ($row, $col)\n";
#        print "Value       = ",encode('GBK', $cell->value()), "\n";
#        print "\n";
        # Overwrite the string in cell A1
        $worksheet3->AddCell( 3, $col, decode('GBK',encode('GBK', $cell->value())));
    }
  }
}

my $worksheet2  = $workbook2->worksheet(4);
( $row_min, $row_max ) = $worksheet2->row_range();
( $col_min, $col_max ) = $worksheet2->col_range();

for my $row ($row_min.. $row_max){

  my $cell = $worksheet2->get_cell( $row, 0 );
  next unless $cell;
  
  if ($cell->value() eq decode('GBK',"时钟平台"))
  {
  	 for my $col ( $col_min .. $col_max ) {
  	 	$cell = $worksheet2->get_cell( $row, $col);
#  	    print "Row, Col    = ($row, $col)\n";
#        print "Value       = ",encode('GBK', $cell->value()), "\n";
#        print "\n";
        # Overwrite the string in cell A1
        $worksheet3->AddCell( 4, $col, decode('GBK',encode('GBK', $cell->value())));
        
    }
  }
}

$worksheet3->AddCell(5, 0, decode('GBK','总计'));
my $loop = 1;
for my $col ('B'..'N')
{
	
	my $row1 = "${col}4";
	my $row2 = "${col}5";
	$worksheet3->AddCell(5, $loop, "=$row1+$row2");
	$loop++;
}

$workbook3->SaveAs($xlstime);
sleep(2);#停顿2s
 
my $rarcmd = "7z.exe a -y  ${inputpath}codecount_result.rar  ${outputpath}*.xls";
system($rarcmd);
 
 
 