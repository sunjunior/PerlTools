#!/usr/bin/perl -w
use strict;
use Net::Telnet;
use Net::Ping;

#die 'input the parameters' unless(scalar @ARGV);#如果没有指定配置参数，退出

my $host     = <STDIN>;
chomp($host);
#注意，$prompt是登陆后的命令提示行，如果匹配不上，脚本将会timeout
my $enpass = 'zxr10';
my $username = 'who';
my $password = 'who';
my $prompt   = '/.+[>#]$/'; 




#主机连通性测试, 5次连接，连接不通，退出程序
my $pingcnt = 1;
my $p = Net::Ping->new("tcp"); 

while($pingcnt <= 5)
{
    if ($p->ping($host))
    {
         print "$host is reachable.\n";   
         $p->close();
         last;	
    }
    else
    {
     print "$host is not reachable.\n";
     if ($pingcnt == 5)
     {
     	print "$host is not reachable,exit the telnet tools";
     	exit;
     }
     $pingcnt++;   	
    }	
	
}   


#连接并登录到服务器
my $conn = new Net::Telnet(
            Timeout     => 15,
            Prompt      => $prompt,
            Dump_Log    => 'Dump_Log.txt',
            Output_log  => 'Output_log.txt'

);
$conn->open($host);

#匹配登录用户名，填写为who
$conn->waitfor('/username/i'); 
$conn->print($username)or die "Login failed: @{[ $conn->errmsg() ]}\n";

#匹配登录密码，填写为who
$conn->waitfor('/password/i');
$conn->print($password) or die "Password failed: @{[ $conn->errmsg() ]}\n";

#等待命令提示行，然后提升到enable权限
$conn->waitfor($prompt);
$conn->print('en');

print $conn->cmd('show version');

#配置输入enable密码提示，并输入密码
$conn->waitfor('/password/i');
$conn->print($enpass);

#先write下，然后进入diag模式，执行diag modexecute mp master agt-cmd a-set-bd-auto
$conn->waitfor($prompt);
$conn->print('write');

$conn->waitfor($prompt);
$conn->print('diag');
$conn->waitfor('/password/i');
$conn->print($enpass);
$conn->waitfor($prompt);

#防止出现配置业务时，有
#%Error 50017: Forbid to config, because the inserted board is not corresponding to the expected board!
$conn->print('diag modexecute mp master agt-cmd a-set-bd-auto'); 
$conn->waitfor($prompt);
$conn->print('end');
sleep(1);
#进入配置模式con t
$conn->waitfor($prompt);
$conn->print('con t');
my @output = $conn->waitfor($prompt);
print "@output";

#执行配置指令
open CLIFH ,"ConfigFile" or die "can not open the configuration file!";
my @clicmds = <CLIFH>;
close CLIFH;

for my $clicmd (@clicmds)
{	
    next if $clicmd =~ m#^\s*$#;
    $conn->print($clicmd);	
    @output = $conn->waitfor($prompt);
    print "@output";

}
$conn->print('end');
@output = $conn->waitfor($prompt);
print "@output";


__END__
 
$conn->print('show ver');
    while(1)
    {
    	 my ($data,$machine) = $conn->waitfor(match=>'/more/i',errmode => 'return');
	     last unless $machine;
	     $conn->print(" ") if $data;	
         $CepSlotNo = $CepSlotNo - 2 if $data =~ m/ZXCTN 6300 Software/;
    	 
    } 	
 
open FH, ">DiagFile";
print FH "
diag modexecute m m toslot$CepSlotNo login,css,2005
diag modexecute m m toslot$CepSlotNo get,pwinfo
diag modexecute m m toslot$CepSlotNo get,tohbytes
diag modexecute m m toslot$CepSlotNo get,clkstatus,1,1
diag modexecute m m toslot$CepSlotNo get,clkstatus,2,1
diag modexecute m m toslot$CepSlotNo get,clkstatus,3,1
diag modexecute m m toslot$CepSlotNo get,clkstatus,4,1
diag modexecute m m toslot$CepSlotNo get,moduletree,all,all
show run
show ip interface b
show interface b\n";
close FH;

#进入Diag模式
$conn->print('diag');
$conn->waitfor('/password/i');
$conn->print($enpass);
@output = $conn->waitfor($prompt);
 print "@output";
#执行cmd命令并输出结果
open DIAFH ,"DiagFile" or die "can not open the diagnose file!";
my @diacmds = <DIAFH>;
close DIAFH;
sleep(1);

for my $diacmd (@diacmds)
{	
    next if $diacmd =~ m#^\s*$#;
    $conn->print($diacmd);
    my $moreflg = 0;
    while(1)
    {
    	 my ($line,$match) = $conn->waitfor(match=>'/more/i',errmode => 'return');
	     last unless $match;
	     $conn->print(" ") if $line;	
         $CepSlotNo = $CepSlotNo - 2 if $line =~ m/ZXCTN 6300 Software/;
         print "##################$CepSlotNo##################\n";
    	 print $line;
    	 $moreflg = 1;
    	 
    } 
	 
	if($moreflg == 0)
	{
	    $conn->print($diacmd);	
	    @output = $conn->waitfor($prompt);
        print "@output";
	} 
   
}   	
 
 
 $conn->close;
