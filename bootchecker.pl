#!/usr/bin/perl -w
use strict;
use Net::Telnet;
use Net::Telnet::Cisco;
use Net::Ping;

my $welcomeMsg = "*******************************************
ZXCTN 6263 设备线卡boot升级版本检测工具                                                                                  
发布时间:2014-10-14  12:00
(c) Copyright ZTE Corp. All rights reserved                            
*******************************************\n";
print $welcomeMsg;

#注意，$prompt是登陆后的命令提示行，如果匹配不上，脚本将会timeout
my $username = 'who';
my $password = 'who';
my $prompt   = '/.+[>#]$/';
my $linecard = 'R16E1F';
my $bootimg  = 'e1te.bin';
my $totalslots = 12;#6300设备最多有12个槽位

print "请输入升级boot目标版本(以V或v开头,比如最新版本V3.14):\n";
my $bootrom = <STDIN>;
chomp($bootrom);
if ($bootrom !~ m#^[Vv]\d\.\d{2}$#) 
{
	print "输入boot版本格式不正确，退出程序!\n";
	system("pause");
	exit(0);
}
$bootrom = uc($bootrom);

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
    
    #打开文件，写入Log信息
    open my $wh, '>', "${host}.txt" or die "Cannot reopen STDOUT: $!";
    my ($year,$mon,$day,$hour,$min,$sec) = gettime();
    
    printf("设备${host} boot升级log(%.4d-%.2d-%.2d %.2d:%.2d:%.2d):\n", $year, $mon, $day,$hour, $min, $sec);
    printf $wh "设备${host} boot升级log(%.4d-%.2d-%.2d %.2d:%.2d:%.2d):\n",
                                   $year,$mon,$day,$hour,$min,$sec;
    
	#先看是否能Ping通
	#主机连通性测试, 5次连接，连接不通，进入下一台设备升级或者退出程序
	my $pingcnt = 1;
	my $p       = Net::Ping->new('icmp');
    
	while ($pingcnt <= 5) 
	{
		if ($p->ping($host)) 
		{
			print "$host is reachable.\n";
			print $wh  "$host is reachable.\n";
			$p->close();
			last;
		}
		else 
		{
			print "$host is unreachable.\n";
			print $wh "$host is unreachable.\n";
			$pingcnt++;
		}

	 }
	 
	if ($pingcnt > 5) 
	{
	    print "$host ping不通，进入下一台设备升级boot或退出工具\n";
	    print $wh "${host} ping不通，进入下一台设备升级boot或退出工具\n";
	    close $wh;
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
    
    #检查img文件夹下是否存在 boot.bin文件，若不存在，直接进入下一台设备
	print $session->cmd('cd /img');
	$session->print('dir');
	my @bootbin = $session->waitfor($prompt);
	my $bootbin = join('', @bootbin);
	print "$bootbin\n";
	print $wh "$bootbin\n";
	if ($bootbin !~ m#$bootimg#smg) 
	{
		print "设备${host}不存在${bootimg}文件，请先上传该文件到当前设备img目录下！\n";
		print $wh "设备${host}不存在${bootimg}文件，请先上传该文件到当前设备img目录下！\n";
		close $wh;
		next;
	}
    
	#获取单板所在槽位，方便后面boot升级
	my @version = $session->cmd('show version');
	my $version = join('', @version);
	print "$version\n";
	print $wh "$version\n";
	#获取软件版本号V1.1版本与V2.0/V2.1 boot升级命令和返回不一样
	my $softver = $2 if $version =~ m#Version\s*ZXCTN\s*(.*?)(V\d.\d)(.*?)RELEASE\s*SOFTWARE#;
	print "当前设备${host}系统软件版本:$softver\n";
	print $wh "当前设备${host}系统软件版本:${softver}\n";
	my $matchcmd = "";
	my $bootflag = "";
	if($softver eq  "V2.1")
	{
		$matchcmd = "bin-mode";
		$bootflag = "successful"
	}
	elsif($softver eq "V1.1")
	{
		$matchcmd = "";
		$bootflag = "successfully";
	}
	else
	{
		 print "设备${host}不支持V2.1和V1.1以外版本！\n";
		 print $wh "设备${host}不支持V2.1和V1.1以外版本\n";
	     close $wh;
       	 next;
	}

	my @linecardslots = ();

	for (my $panel = 1; $panel <= $totalslots; $panel++)    
	{
		my $boardtype = $2 if $version =~ m#\[NPCI, panel ${panel}\](.*?)Board Type(.*?)Main CPLD Version#sm;
		if (defined $boardtype && $boardtype =~ m/$linecard/) 
		{
			push @linecardslots, $panel;
			print "线卡$linecard:槽位$panel\n";
			print $wh "线卡${linecard}:槽位${panel}\n";
		}
	}

	#进入olleh隐藏模式，进行boot升级

	print $session->cmd('olleh');

	for my $linecardslot (@linecardslots) 
	{
		my $cmd = "bootrom update npc $linecardslot $matchcmd";
		print "$cmd\n";
		print $wh "${cmd}\n";
		my $failed_cnt = 0;
		while ($failed_cnt < 3) 
		{
			$session->print($cmd);
			$session->errmode("return");
			print "boot正在升级中...\n";
			print $wh "boot正在升级中...\n";
			sleep(45);
			my @successflag = $session->waitfor($prompt);
			my $successflag = join('', @successflag);
			print "$successflag\n";
			print $wh "$successflag\n";
			if ($successflag =~ m/\b$bootflag\b/) 
			{
				print "槽位${linecardslot}:线卡${linecard} boot升级成功!\n";
			    print $wh "槽位${linecardslot}:线卡${linecard} boot升级成功!\n";
				last;
			}
			$failed_cnt++;
		}
		if ($failed_cnt == 3) 
		{
			print "槽位${linecardslot}:线卡${linecard} boot升级失败!\n";
			 print $wh "槽位${linecardslot}:线卡${linecard} boot升级失败!\n";
		}
	}
	print $session->cmd('!');
	sleep(1);
	my @bootcheck = $session->cmd('show bootrom');
	my $bootcheck = join('', @bootcheck);
	print "$bootcheck\n";
	print $wh "$bootcheck\n";
	for my $linecardslot (@linecardslots) 
	{
		my $version = $2 if $bootcheck =~ m#\[NPCI, panel ${linecardslot}\](.*?)Bootrom Version(.*?)Creation Date#sm;
		if ($version =~ m/$bootrom/) 
		{
			print "槽位${linecardslot}:线卡${linecard} boot升级后与目标版本匹配\n";
			print $wh "槽位${linecardslot}:线卡${linecard} boot升级后与目标版本匹配!\n";
		}
		else 
		{
			print "槽位${linecardslot}：线卡${linecard} boot升级后与目标版本不匹配\n";
			print $wh "槽位${linecardslot}:线卡${linecard} boot升级后与目标版本不匹配\n";
			
		}
	}
	$session->close();
	
	print "***************END*********************\n";
	print $wh "***************END*********************";
	close $wh;
}
system("pause");

sub gettime
{
    my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime();    
    $year += 1900;    
    $mon++; 
    return ($year,$mon,$day,$hour,$min,$sec);
}
