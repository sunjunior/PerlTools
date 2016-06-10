#!/usr/bin/perl -w
use strict;
use Net::Telnet;
use Net::Ping;
use Net::FTP;
use Archive::Zip;

use Time::HiRes qw(usleep);
use constant MAX_COUNT => 500;

#注意，$prompt是登陆侯的命令提示行，如果匹配不上，脚本将会timeout
my $username = 'deviceuser';
my $password = 'devicepassword';
my $port = 23;
my $prompt = '/(.+[>#\]]$|\]:}/';
my @hostlist = ('10.2.2.3','2.3.4.5');

#获取当前时间
sub getSysTime
{
    my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday,$isdst)= localtime();
    $year += 1900;
    $mon++;
    return ($year, $mon, $day, $hour, $min, $sec);	
}


sub getDeviceState
{
	my $hostAddr = shift;
	my $pingcnt = 1;
	my $p = Net::Ping->new('icmp');
	my $isAvailableFlag = 0;
	while ($pingcnt <= MAX_COUNT) 
	{
		if ($p->ping($hostAddr))
		{
			$p->close();
			return 1;
		}
		else
		{
			if ($pingcnt == MAX_COUNT)
			{
				return 0;
			}
			print "尝试第$pingcnt次连通主机$hostAddr\n";
			$pingcnt++;
		}
	}
}

#判断是否有日志异常
sub getExceptionInfo
{
	my ($session, $host) = @_;
	return if !$session;
	$session->print('system'); #进入系统配置模式
	$session->waitfor($prompt);
	$session->print('diagnose'); #进入诊断模式
	$session->waitfor($prompt);
	my @isisinfo = ();
	my $isisinfo = undef;
	for (my $uiloop = 0; $uiloop < MAX_COUNT; $uiloop++)
	{
		$session->print('disp XXX'); 
	    $session->waitfor($prompt);
	    print @isisinfo;
	    $isisinfo = join('', @isisinfo);
	    $isisinfo = $1 if $isisinfo =~ m#ucIpv4Enable:\s*(\d+)#smg;
	    if (defined $isisinfo && $isisinfo =~ m/00/)
	    {
	    	return 0; #有异常
	    }
	    usleep(200_000);
	    $isisinfo = undef;
	    $session->print('disp XXX');
	    @isisinfo = $session->waitfor($prompt);
	    $isisinfo = join('', @isisinfo);
	    if (defined $isisinfo && $isisinfo =~ m/State\s*:Ready/smg)
	    {
	    	print "准备OK\n";
	    	return 1;
	    }
	}
	
	return 1; #没有异常
}

sub getLogFile
{
	my ($session, $host) = @_;
	return if !$session;
	#在诊断模式下收集日志
	$session->print('collect diagnostic information');
	$session->waitfor($prompt);
	$session->cmd('quit');
	$session->cmd('quit');
	$session->print('disp users');
	my @ftpserver = $session->waitfor($prompt);
	print @ftpserver;
	my $ftpserver = join('', @ftpserver);
	if ($ftpserver =~ m/^\+\s+\d+\s+VTY.*?((\d+\.){3}\d+)/smg)
	{
		$ftpserver = $1;
		my $ftp = Net::FTP->new($ftpserver, Timeout => 50) or die "本地ftp服务器没有开启，退出";
	}
	else
	{
		print "设备获取不到本地ftp服务器ip";
		next;
	}
	#如果输出结果等待时间较长的，建议用print&&waitfor组合而不用cmd
    #登陆到ftp服务器,下载文件到本地
    $session->print("ftp $ftpserver");
    $session->waitfor('/Enter password/i');
    $session->print('a');
    print $session->waitfor($prompt);
    my ($year, $mon, $day, $hour, $min) = getSysTime();
    my $logname = sprintf("%s_diagnostic_information%.4d%.2d%.2d%.2d%.2d.zip",
    $host, $year, $mon, $day, $hour, $min);
    $session->print("put diagnostic_information.zip $logname");
    $session->waitfor($prompt);
}

do 
{
    for my $host (@hostlist)
    {
    	$host =~ s#\s+##g;
    	my ($year, $mon, $day, $hour, $min, $sec) = getSysTime();
    	printf("设备$host登陆log(%.4d-%.2d-%.2d%.2d:%.2d:%.2d):\n",
    	$year, $mon, $day, $hour, $min, $sec);
    	my $isConnected = getDeviceState($host);
    	if ($isConnected)
    	{
    		print "$host is reachable\n";
    		
    	}
    	else
    	{
    		print "$host is not reachable\n";
    		next;
    	}
    	my $session = new Net::Telnet(Timeout => 60,
    	                              Prompt => $prompt,
    	                              Port => $port,
    	                              Dump_Log => "$host.log");
    	$session->open($host);
    	$session->waitfor('/Username:/i');
    	$session->print($username);
    	$session->waitfor('/Password:/i');
    	$session->print($password);
    	$session->waitfor($prompt);
    	$session->cmd('N');
    	$session->errmode(sub{ return if $_[0] =~ /eof/}); 
    	my $flag = getExceptionInfo($session, $host);
    	if ($flag == 0)
    	{
    		getLogFile($session, $host);
    		$session->close();
    		exit;
    	}  
    	
    	$session->print('system');
    	$session->waitfor($prompt);
    	$session->print('reboot');
    	$session->print($prompt);
    	$session->print('Y');
    	print $session->waitfor($prompt);
    	                          
    }
    sleep(300);	
}while(1);
