#!/usr/bin/perl -w
use strict;
use Net::Telnet;
use Net::Telnet::Cisco;
use Net::Ping;

my $welcomeMsg = "*******************************************
ZXCTN 6263 设备线卡boot升级版本检测工具(html版)                                                                                   
发布时间:2014-10-23  12:00
(c) Copyright ZTE Corp. All rights reserved                            
*******************************************\n";
print $welcomeMsg;

#注意，$prompt是登陆后的命令提示行，如果匹配不上，脚本将会timeout
my $username = 'who';
my $password = 'who';
my $prompt   = '/.+[>#]$/';
my $linecard = 'R16E1F';
my $bootimg  = 'e1te.bin';

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
    open WH, '>', "${host}.html" or die "Cannot reopen STDOUT: $!";
    print WH "<html>
              <head><title>${host}日志信息页面</title></head>
              <body>
              <h1 align=\"center\"> 设备${host} boot升级log:</h1>";
    
	#先看是否能Ping通
	#主机连通性测试, 5次连接，连接不通，退出程序
	my $pingcnt = 1;
	my $p       = Net::Ping->new('icmp');
    
	while ($pingcnt <= 5) 
	{
		if ($p->ping($host)) 
		{
			print "$host is reachable.\n";
			print WH  "<p>$host is reachable.</p>";
			$p->close();
			last;
		}
		else 
		{
			print "$host is unreachable.\n";
			print WH "<p>$host is unreachable.</p>";
			$pingcnt++;
		}

	 }
	 
	if ($pingcnt >= 5) 
	{
	    print "$host ping不通，进入下一台设备升级boot或退出工具\n";
	    print WH "<p><font color=\"red\">${host} ping不通，进入下一台设备升级boot或退出工具</font></p>";
	    print WH "</body>
	              </html>";
	    close WH;
		next;
	}

	my $session = Net::Telnet::Cisco->new(
		Timeout    => 15,
		Prompt     => $prompt
	);
	$session->open($host);
	print "$host连接成功\n" if $session->login($username, $password);
	sleep(5);
	# Execute a command
	$session->enable('zxr10');
    
    #检查img文件夹下是否存在 boot.bin文件，若不存在，直接进入下一台设备
	print $session->cmd('cd /img');
	$session->print('dir');
	my @bootbin = $session->waitfor($prompt);
	my $bootbin = join('', @bootbin);
	print "$bootbin\n";
	if ($bootbin !~ m#$bootimg#smg) 
	{
		print "设备${host}不存在${bootimg}文件，请先上传该文件到当前设备img目录下！\n";
		print WH "<p> <font color=\"red\">
		设备${host}不存在${bootimg}文件，请先上传该文件到当前设备img目录下！</font></p>";
        print WH "</body>
	              </html>";
		close WH;
		next;
	}
    
	#获取单板所在槽位，方便后面boot升级
	my @version = $session->cmd('show version');
	my $version = join('', @version);
	print "$version\n";
	#获取软件版本号V1.1版本与V2.0/V2.1 boot升级命令和返回不一样
	my $softver = $2 if $version =~ m#Version\s*ZXCTN\s*(.*?)(V\d.\d)(.*?)RELEASE\s*SOFTWARE#;
	print "当前设备${host}系统软件版本:$softver\n";
	print WH "<p>当前设备${host}系统软件版本:${softver}</p>";
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
		 print WH "<p><font color=\"red\">
		                     设备${host}不支持V2.1和V1.1以外版本！</font></p>";
         print WH "</body>
	               </html>";
	     close WH;
       	 next;
	}

	my @linecardslots = ();

	for (my $panel = 1; $panel <= 12; $panel++)    #6300设备最多有12个槽位
	{
		my $boardtype = $2 if $version =~ m#\[NPCI, panel ${panel}\](.*?)Board Type(.*?)Main CPLD Version#sm;
		if (defined $boardtype && $boardtype =~ m/$linecard/) 
		{
			push @linecardslots, $panel;
			print "线卡$linecard:槽位$panel\n";
			print WH "<p>线卡${linecard}:槽位${panel}</p>";
		}
	}

	#进入olleh隐藏模式，进行boot升级

	print $session->cmd('olleh');

	for my $linecardslot (@linecardslots) 
	{
		my $cmd = "bootrom update npc $linecardslot $matchcmd";
		print "$cmd\n";
		print WH "<p> ${cmd} </p>";
		my $failed_cnt = 0;
		while ($failed_cnt < 3) 
		{
			$session->print($cmd);
			$session->errmode("return");
			print "boot正在升级中...\n";
			print WH "<p> boot正在升级中... </p>";
			sleep(45);
			my @successflag = $session->waitfor($prompt);
			my $successflag = join('', @successflag);
			print "$successflag\n";
			print WH "<p> $successflag </p>";
			if ($successflag =~ m/\b$bootflag\b/) 
			{
				print "槽位${linecardslot}:线卡${linecard} boot升级成功!\n";
			    print WH "<p><font color=\"red\">
		                        槽位${linecardslot}:线卡${linecard} boot升级成功!</font></p>";
				last;
			}
			$failed_cnt++;
		}
		if ($failed_cnt == 3) 
		{
			print "槽位${linecardslot}:线卡${linecard} boot升级失败!\n";
			 print WH "<p><font color=\"red\">
		                     槽位${linecardslot}:线卡${linecard} boot升级失败!</font></p>";
		}
	}
	print $session->cmd('!');
	sleep(1);
	my @bootcheck = $session->cmd('show bootrom');
	my $bootcheck = join('', @bootcheck);
	for my $linecardslot (@linecardslots) 
	{
		my $version = $2 if $bootcheck =~ m#\[NPCI, panel ${linecardslot}\](.*?)Bootrom Version(.*?)Creation Date#sm;
		if ($version =~ m/$bootrom/) 
		{
			print "槽位${linecardslot}:线卡${linecard} boot升级后与目标版本匹配\n";
			print WH "<p> 槽位${linecardslot}:线卡${linecard} boot升级后与目标版本匹配!</p>";
		}
		else 
		{
			print "槽位${linecardslot}：线卡${linecard} boot升级后与目标版本不匹配\n";
			print WH "<p><font color=\"red\">
			                  槽位${linecardslot}:线卡${linecard} boot升级后与目标版本不匹配</font></p>";
			
		}
	}
	$session->close();
	
	print "***************END*********************\n";
	print WH "<p>***************END*********************</p>";
    print WH "</body>
	          </html>";
	close WH;
}
system("pause");
