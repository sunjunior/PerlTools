use strict;
use Net::Telnet;
use Net::Telnet::Cisco;

my $welcomeMsg = 
"*******************************************
      ZXCTN 6263 设备健康检查工具特别版本                                      
      startrun启动检测                                                     
                  发布时间:2014-09-25 18:00                
*******************************************
请输入检测设备IP地址,多个IP请按分号或逗号隔开:\n";
print $welcomeMsg;

#注意，$prompt是登陆后的命令提示行，如果匹配不上，脚本将会timeout
my $username = 'who';
my $password = 'who';
#my $prompt   = '/.+[>#]$/';
my $hostlist = <STDIN>;    #LocalHost

my @hostArray = split /[;,]/, $hostlist;

foreach my $host (@hostArray) 
{
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
	my @version = $session->cmd('show system-configuration recoverset');
	my $version = join('', @version);
	print $version;
	if ($version =~ m#agent#)
	{
		print "当前启动模式为agent模式\n";
	}
	else
	{
		print "当前启动模式为startrun模式\n";
	}
	
	
	
	
	print "************************************\n";
}



