#!/usr/bin/perl -w
use strict;  
use warnings;  
use LWP::Simple;
use HTML::TreeBuilder;
use URI;
use Encode;
@ARGV="http://www.c114.net/news/";
my	@index;
die '请输入URL地址!!!' unless(scalar @ARGV);#如果没有指定URL，退出
die '检索词集不能为空，请检查！' if (-z "company" or -z "webmatchlist");
open MH, "wordset" or die  "不能打开检索词集文件:$!\n";
my @matchlist=<MH>;
chomp(@matchlist);
open CH, "company" or die  "不能打开检索词集文件:$!\n";
my @company=<CH>;
chomp(@company);

my $base_seed =$ARGV[0];
print "$base_seed\n";
push @index,$base_seed;

&urlparser(\@index) while @index;
	   
sub urlparser {
 
	my $base_url_ref = shift;
	my $base_url = shift @$base_url_ref;
	my $content = get($base_url);
   warn "不能获取网页内容，网速过慢或者URL无效:$!\n" unless defined $content;
 	my $tree = HTML::TreeBuilder->new_from_content($content);
 	 	my %urls;
 		foreach my $node ($tree->find_by_tag_name('a')) {
 	 	    $urls{ $node->attr('href') }++ if $node->attr('href');
 	 
 	 		}		
    $tree=$tree->delete;
   foreach my $rel_url (sort keys %urls) {
   	    $rel_url = encode('GBK',$rel_url);
   		
   		my $filename = $1  if  $content =~ m#\Q$rel_url\E.*?>(.*?)</a>#si;
 	 	 	    next unless defined $filename; 
 	 	 	   $filename =encode('GBK',$filename);
 	 	 	   
 	 	 	    
 	 	 	   $rel_url = URI->new_abs($rel_url,$base_url)->canonical() if $rel_url =~ /[^http]/;
 	 	 	   
 	 	 	   my $scalar = grep /$rel_url/,@$base_url_ref;
 	 	   		push @$base_url_ref,$rel_url unless $scalar;
 	 	 	 for my $match (@matchlist){
 	  		if ($filename =~ m#$match#) {
	 	        
 	       	print "$rel_url:$filename:$match\n";
    	    system "wget","$rel_url", "-NPWeb";#财经定制网站
 	        last;	
	 	   	 }
 	 	 	     }

 	  }    
        print "*******************结束***********************\n";
    	 	 	    	          
}

