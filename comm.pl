#!/usr/bin/perl -w
use strict;
use Net::Telnet;
use Net::Telnet::Cisco;
use Net::Ping;

my $welcomeMsg = "*******************************************
ZXCTN 6263 设备线卡版本检测工具                                                                                  
发布时间:2014-10-14  12:00
(c) Copyright ZTE Corp. All rights reserved                            
*******************************************\n";
print $welcomeMsg;

#注意，$prompt是登陆后的命令提示行，如果匹配不上，脚本将会timeout
my $username = 'who';
my $password = 'who';
my $prompt   = '/.+[>#]$/';
my $linecard = 'R16E1F';

print "请输入检测设备IP地址,多个IP请按分号或逗号隔开:\n";
my $hostlist = <STDIN>;    #LocalHost
chomp($hostlist);
my @hostArray = split /[;,]/, $hostlist;

foreach my $host (@hostArray) 
{
	$host =~ s#\s+##g;
	if ($host !~ m/(\d+\.){3}\d+/) 
	{
		print "IP地址${host}输入不正确，进入下一台设备升级boot或退出工具!\n";
		next;
	}
    
	#先看是否能Ping通
	#主机连通性测试, 5次连接，连接不通，进入下一台设备升级或者退出程序
	my $pingcnt = 1;
	my $p       = Net::Ping->new('icmp');
    
	while ($pingcnt <= 5) 
	{
		if ($p->ping($host)) 
		{
			print "$host is reachable.\n";
			$p->close();
			last;
		}
		else 
		{
			print "$host is unreachable.\n";
			$pingcnt++;
		}

	 }
	 
	if ($pingcnt >= 5) 
	{
	    print "$host ping不通，进入下一台设备升级boot或退出工具\n";
		next;
	}

	my $session = Net::Telnet::Cisco->new(
		Timeout    => 15,
		Prompt     => $prompt
	);
	$session->open($host);
	print "$host连接成功\n" if $session->login($username, $password);
	sleep(5);# 加入5s延迟的作用是为了使设备telnet服务能及时响应
	
	$session->enable('zxr10');
	print $session->cmd('show ver');
}