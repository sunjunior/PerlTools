#!/usr/bin/perl -w
use strict;

my $ipinfo = `ifconfig`;
my @process = split("\n", $ipinfo);
for my $cmd (@process)
{
	chomp($cmd);
	print "ip: $cmd \n";
}








