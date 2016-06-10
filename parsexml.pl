#!/usr/bin/perl -w
use strict;
use warnings;
use LWP::Simple;
use HTML::TreeBuilder;
use URI;
use Encode;
@ARGV = "http://share.zte.com.cn/tech/jsp/showVoteEnrollDetail?vid=8aa906b647a5f90f0147d2887df74636";
die '请输入URL地址!!!'
  unless ( scalar @ARGV );    #如果没有指定URL，退出

my $base_seed = $ARGV[0];

my $content = get($base_seed);
warn "不能获取网页内容，网速过慢或者URL无效:$!\n"
  unless defined $content;
my $tree = HTML::TreeBuilder->new_from_content($content);
my %urls;
foreach my $node ( $tree->find_by_tag_name('a') ) {
	$urls{ $node->attr('href') }++ if $node->attr('href');

}
$tree = $tree->delete;
foreach my $rel_url ( sort keys %urls ) {
	$rel_url = encode( 'GBK', $rel_url );

	my $filename = $1 if $content =~ m#\Q$rel_url\E.*?>(.*?)</a>#si;
	next unless defined $filename;
	$filename = encode( 'GBK', $filename );

	print "*******************$filename***********************\n";

}

