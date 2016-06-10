use Net::SMTP;

my $mailhost = "smtp.126.com"; # the smtp host
my $mailfrom = 'sunjunior@126.com'; # your email address
my @mailto = ('sunjunior@163.com'); # the recipient list
my $subject = "标题";
my $text = "正文\n第二行位于此。";

$smtp = Net::SMTP->new($mailhost, Hello => 'localhost', Timeout => 120, Debug => 1);
#$smtp = Net::SMTP->new($mailhost, Hello => 'localhost', Timeout => 120);

# anth login, type your user name and password here
$smtp->auth('sunjunior@126.com','password');

foreach my $mailto (@mailto) {
        # Send the From and Recipient for the mail servers that require it
        $smtp->mail($mailfrom);
        $smtp->to($mailto);

        # Start the mail
        $smtp->data();

        # Send the header
        $smtp->datasend("To: $mailto\n");
        $smtp->datasend("From: $mailfrom\n");
        $smtp->datasend("Subject: $subject\n");
        $smtp->datasend("\n");
        # Send the message
        $smtp->datasend("$text\n\n");
        # Send the termination string
        $smtp->dataend();
}
$smtp->quit;