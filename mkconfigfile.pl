#!/usr/bin/perl -w
use strict;

die 'input the parameters' unless(scalar @ARGV);#如果没有指定配置参数，退出

my $host     =  $ARGV[0];
my $loopbackIP = $ARGV[1];
my $peerloopbackIP = $ARGV[2];
my $vlanIP = $ARGV[3];
my $peervlanIP = $ARGV[4];
my $peerMacAddr = $ARGV[5];#对端设备MAC，最后位加1，用show lacp sys-id可得到
my $CepSlotNo = $ARGV[6];  #CEP线卡所在槽位号
my $CepPortNo = $ARGV[7];  #CEP业务绑定端口号
my $GeSlotNo = $ARGV[8];   #GE线卡所在槽位
my $GePortNo = $ARGV[9];   #隧道绑定GE线卡端口
my $payloadsize = 783;     #CEP业务净荷大小
#根据需求配置指定的业务条数
open FH, ">ConfigFile";

print FH "no tunnel 100
interf loopback1 
ip add $loopbackIP 255.255.255.255
ex
vlan 100
ex
interface gei_$GeSlotNo/$GePortNo
switchport mode trunk
switchport trunk vlan 100
exit
interface vlan 100
ip address $vlanIP 255.255.255.0
set arp per $peervlanIP $peerMacAddr
! 
mac add per $peerMacAddr interface gei_$GeSlotNo/$GePortNo vlan 100
mpls traffic-eng tunnels
tunnel 100
tu mode tr static
tu static type bi role ingress
tu static ingress $loopbackIP egress $peerloopbackIP out-port gei_$GeSlotNo/$GePortNo out-label 1000100 next-hop $peervlanIP
tu static ingress $peerloopbackIP egress $loopbackIP in-port gei_$GeSlotNo/$GePortNo in-label 1000100
tu enable
exit\n";

    print FH "no cip 10$CepPortNo\n";
    print FH "no vll 10$CepPortNo\n";
    print FH "no pw  10$CepPortNo\n";  
    
    print FH "controller stm1_$CepSlotNo/$CepPortNo\n";
    print FH "framing sdh\n"; 
    print FH "!\n";
    
	print FH "pw 10$CepPortNo\n";
	print FH "pwtype cep-packet\n";
	print FH "mode s\n";
	print FH "peer $peerloopbackIP vcid 10$CepPortNo local-label 100010$CepPortNo remote-label 100010$CepPortNo\n";
    print FH "tunnel 100\n";
    print FH "apply pw-class 1:0:0\n";
    print FH "encapsulated-delay 32\n";
    print FH "sequence enable\n";
    print FH "cep type basic\n";
    print FH "payload $payloadsize\n";
    print FH "exit\n";
    
    print FH "vll 10$CepPortNo\n";
    print FH "service-type tdm\n";
    print FH "mpls xconnect pw 10$CepPortNo\n";
    print FH "exit\n";
    
    print FH "cip 10$CepPortNo\n";
    print FH "service-type tdm cep stm1_$CepSlotNo/$CepPortNo vc4 1\n";    
    print FH "xconnect 10$CepPortNo\n";
    print FH "exit\n";
    
close FH;