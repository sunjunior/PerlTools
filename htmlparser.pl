#!/usr/bin/perl -w
use Encode;
$ARGV[0] = "Web\\\\";
die 'please input the path for html documents!!!' unless(scalar @ARGV); 
my $basepath = $ARGV[0];
opendir DIR, $basepath or die "can not open the file\n";
my @abspath;
my @filename =readdir(DIR);
chomp(@filename);
for (@filename) {
 push @abspath,$_  unless $_  eq ".." or $_ eq ".";
}
 @abspath = map { $basepath.$_} @abspath;
 
 open MATCHLIST, "pdfmatchlist" or die "can not open the matchlist\n";#打开PDF文件匹配集
 my @matchtable =<MATCHLIST>;
 chomp(@matchtable);
 my @matchwords; 
 
 for my $matchtable (@matchtable){	
 open MH, $matchtable or die "can not open the $matchtable\n";
    while(my $match =<MH>){
 	 chomp($match);
 	 push @matchwords,$match;
  	  } 
 } 
 	
foreach my $filename (@abspath){
open FH,"$filename" or warn 'can not open the file!';
$text = join('',<FH>);
 close FH;
 unlink $filename;
for my $match (@matchwords) {
   $text=~ s#$match#<font color="\#FF0000" size="+1" ><b>$match</b></font>#sg;	
 	} 
 	
 
 my $savefile = $1.".html" if $text =~ m#<title>(.*?)</title>#si; #保存文件
 print $savefile;
  while (-e "$basepath$savefile"){
		 $savefile = $1 ."1".".html" if $savefile =~ /(.*)\.html/;
	}
 open WH,">$basepath$savefile" or die 'can not create fhe file $savefile!';
 print WH $text;
}
 
