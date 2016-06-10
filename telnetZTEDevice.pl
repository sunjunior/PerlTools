#!/usr/bin/perl -w
use strict;
use Net::Telnet;
use Net::Telnet::Cisco;

my $welcomeMsg = 
"*******************************************
      ZXCTN 6263 设备健康检查工具特别版本                                      
      mcc-vlanid配置检测                                                     
                  发布时间:2014-09-18 18:00                
*******************************************
请输入检测设备IP地址,多个IP请按分号或逗号隔开:\n";
print $welcomeMsg;

#注意，$prompt是登陆后的命令提示行，如果匹配不上，脚本将会timeout
my $username = 'xxx';
my $password = 'xxx';
#my $prompt   = '/.+[>#]$/';
my $hostlist = <STDIN>;    #LocalHost

my @hostArray = split /[;,]/, $hostlist;

foreach my $host (@hostArray) {
	$host =~ s#\s+##g;
	if($host !~ m/(\d+\.){3}\d+/)
    {
	    print "IP地址${host}输入不正确，退出程序!\n";
	    system("pause");
	    exit(0);
    }
	my $session = Net::Telnet::Cisco->new( Host => $host );
	$session->login( $username, $password );
    if($session)
    {
    	print "$host连接成功\n";
    }

	# Execute a command
	$session->enable('zxr10');
	$session->cmd('cd cfg');
	my @showrunconfig = $session->cmd('more startrun.dat');
	$session->close; 
	my $runconfig = join( '', @showrunconfig );
	open WH, '>', "${host}.txt" or die "Cannot reopen STDOUT: $!";
	print "设备${host}配置mcc-vlanid信息：\n";
	print WH "设备${host}配置mcc-vlanid信息：\n";
	my @interfacege;
	for ( my $panelno = 1 ; $panelno <= 12 ; $panelno++ )
	{
		my @interfacege = ();
		push @interfacege, $&
		  while (
			$runconfig =~ m/^interface\s+x?gei_${panelno}\/\d+(.*?)!/smg );
		next unless @interfacege;
		
		print WH @interfacege;
		print @interfacege;
		
		my $mccvlanid = grep( /mcc-vlanid\s*(\d+)/, @interfacege );
		if ($mccvlanid) {
			print WH "\n槽位  ${panelno} 配置正常\n";
			print "\n槽位  ${panelno} 配置正常\n";
			print WH "*********************\n";
			print "*********************\n";
		}
		else {
			print WH "\n槽位  ${panelno} 配置异常\n";
			print "\n槽位  ${panelno} 配置异常\n";
			print WH "*********************\n";
			print "*********************\n";
		}
	}
	print "设备${host} mcc-vlanid配置诊断完成\n";
	print WH "设备${host} mcc-vlanid配置诊断完成\n";
	close WH;
	
	sleep(2);
	
}
    system("pause");
