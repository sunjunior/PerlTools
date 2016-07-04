use Net::SMTP;
use Encode;
use strict;

my $smtp = Net::SMTP->new('smtp.126.com',
                       Hello => 'mail.126.com',
                       Timeout => 30,
                       Debug   => 1,
                       SSL     => 1,
                      );
die "can not connect:$!" unless $smtp;
my $user = 'sunjunior@126.com';
my $passwd = 'xxxxxxxxx';
my $sender = 'sunjunior@126.com';
my $receiver = 'sunjunior@163.com'; 
$smtp->auth($user, $passwd);
$smtp->mail($sender);
if ($smtp->to($receiver))
{
	$smtp->data();
	$smtp->datasend(encode('GBK', decode('UTF-8', "Subject: 致所有开发测试人员\n")));
	$smtp->datasend(encode('GBK', decode('UTF-8', "From: QA Team\n")));
    $smtp->datasend(encode('GBK', decode('UTF-8', "To: sunjunior\n")));
	$smtp->datasend("\n");
	$smtp->datasend(encode('GBK', decode('UTF-8', "【重要重要】今天下午要准备第三个版本迭代测试了,请将所有测试场景通过后上线！\n")));
	$smtp->dataend();
}
else
{
	print $smtp->message();
}

$smtp->quit;



 