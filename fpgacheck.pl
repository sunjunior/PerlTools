use strict;
use Net::Telnet;
use Time::HiRes qw(usleep);
use Net::Telnet::Cisco;
my $g_failed_count = 0;
my $welcomeMsg = 
"*******************************************
\tZXCTN  6220 FPGA读写测试工具\t\t
\t发布时间: 2014-10-11 12:00\t\t
\t工具制作者:sunjun\t\t            
*******************************************
请输入检测设备IP地址,多个IP请按分号或逗号隔开:\n";
print $welcomeMsg;

#注意，$prompt是登陆后的命令提示行，如果匹配不上，脚本将会timeout
my $username = 'who';
my $password = 'who';
#my $prompt   = '/.+[>#]$/';
my $hostlist = <STDIN>;    #LocalHost
my @hostArray = split /[;,]/, $hostlist;

print "输入FPGA SSRAM测试次数:\n";
my $count= <STDIN>;
chomp($count);
if ($count < 1)
{
	print "输入FPGA SSRAM测试次数不正确，默认读写一次！\n";
	$count = 1;
}

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
	my @version = $session->cmd('show version');
	my $version = join('', @version);
	my $netEntry = $1 if $version =~ m#ZXCTN\s*(\d+)\s*Software#;
	if($netEntry ne '6220')
	{
		print "$host不为6220设备,工具退出或检测下一台设备\n";
		system("pause");
		print "************************************\n";
		$session->close();
		next;
	}
	print $session->cmd('olleh');
	for(my $num = 0; $num < $count; $num++)
    {
        #写操作步骤
        my @fpgainfo = $session->cmd('diag exe m m c d 0xb0000024');
	    my $fpgainfo = join('',@fpgainfo);	
    	if ($fpgainfo !~ m/00 00 00 00/)
    	{
    		usleep(200_000);
    		redo;
    	}
    	print "diag exe m m c SspFpgaWriteReg 0xb0000020,0x80000000\n";
    	print $session->cmd('diag exe m m c SspFpgaWriteReg 0xb0000020,0x80000000');
    	
    	print "diag exe m m c SspFpgaWriteReg 0xb0000028,0x00000000\n";
        print $session->cmd('diag exe m m c SspFpgaWriteReg 0xb0000028,0x00000000');

        for(my $i = 0xb0200000; $i < 0xb020007c; $i += 4)
	    {
		    my $cmd = sprintf("diag exe m m c SspFpgaWriteReg 0x%x,0xf0f0f0f0\n",$i);
	        print $cmd;
	        $session->cmd($cmd);
	        usleep(50_000);
	    }  
        
        print "diag exe m m c SspFpgaWriteReg 0xb000001c,0x00000001\n";
        print $session->cmd('diag exe m m c SspFpgaWriteReg 0xb000001c,0x00000001');
        usleep(200_000);
        
        print "diag exe m m c d 0xb0000024\n";
        @fpgainfo = $session->cmd('diag exe m m c d 0xb0000024');
        $fpgainfo = join('',@fpgainfo);
        usleep(200_000);
        
        while ($fpgainfo !~ m/00 00 00 01/)
    	{
    		print "PCI_ssram_ack is busy,please wait ...\n";
    		usleep(500_000);
    		@fpgainfo = $session->cmd('diag exe m m c d 0xb0000024');
            $fpgainfo = join('',@fpgainfo);
    	}
        
        print "diag exe m m c SspFpgaWriteReg 0xb000001c,0x00000000\n";
        print $session->cmd('diag exe m m c SspFpgaWriteReg 0xb000001c,0x00000000');
        usleep(200_000);
        
        #读操作步骤
        @fpgainfo = $session->cmd('diag exe m m c d 0xb0000024');
	    $fpgainfo = join('',@fpgainfo);	
        while ($fpgainfo !~ m/00 00 00 00/)
    	{
    		usleep(500_000);
            @fpgainfo = $session->cmd('diag exe m m c d 0xb0000024');
	        $fpgainfo = join('',@fpgainfo);
    	}
    	print "diag exe m m c SspFpgaWriteReg 0xb0000020,0x00000000\n";
    	print $session->cmd('diag exe m m c SspFpgaWriteReg 0xb0000020,0x00000000');
    	usleep(200_000);
    	print "diag exe m m c SspFpgaWriteReg 0xb0000028,0x00000000\n";
        print $session->cmd('diag exe m m c SspFpgaWriteReg 0xb0000028,0x00000000');
        usleep(200_000);
        print "diag exe m m c SspFpgaWriteReg 0xb000001c,0x00000001\n";
        print $session->cmd('diag exe m m c SspFpgaWriteReg 0xb000001c,0x00000001');
        usleep(200_000);
        print "diag exe m m c d 0xb0000024\n";
        @fpgainfo = $session->cmd('diag exe m m c d 0xb0000024');
        $fpgainfo = join('',@fpgainfo);
        usleep(200_000);
        
        while ($fpgainfo !~ m/00 00 00 01/)
    	{
    		print "PCI_ssram_ack is busy,please wait ...\n";
    		usleep(500_000);
    		@fpgainfo = $session->cmd('diag exe m m c d 0xb0000024');
            $fpgainfo = join('',@fpgainfo);
    	}
    	
    	for(my $i = 0xb0200000; $i < 0xb020007c; $i += 4)
	    {
		    my $cmd = sprintf("diag exe m m c d 0x%x\n",$i);
	        print $cmd;
	        @fpgainfo = $session->cmd($cmd);
	        $fpgainfo = join('',@fpgainfo);
	        $g_failed_count++ if ($fpgainfo !~ m/f0 f0 f0 f0/);
	        usleep(50_000);
	    } 
        
    }
     
	print $session->cmd('!');
	$session->close();
	print "$host设备写入ram失败次数总计：$g_failed_count\n";
	print "***************END*********************\n";
	
}
    system("pause");