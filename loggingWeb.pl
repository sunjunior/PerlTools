#! /usr/bin/perl -w
use LWP::UserAgent;
use HTTP::Cookies;
use HTML::TreeBuilder;
use Encode;
use strict;

my $cookie = HTTP::Cookies->new(
	file     => "./cookies",
	autosave => 1,
);

my $request = new LWP::UserAgent;
$request->cookie_jar($cookie);
$request->timeout(10);
$request->default_header( 'Host' => 'www.renren.com' );
$request->default_header( 'User-Agent' =>
"Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:45.0) Gecko/20100101 Firefox/45.0"
);
$request->default_header('Connection' => 'keep-alive');
$request->default_header('Accept' => 'image/png,image/*;q=0.8,*/*;q=0.5');
$request->default_header('Accept-Language' => '	en-US,en;q=0.5');
$request->default_header('Accept-Encoding' => '	gzip, deflate');
$request->default_header('Referer' => 'http://www.renren.com/');
$request->default_header('Connection' => 'keep-alive');
push @{ $request->requests_redirectable }, 'POST';

my $url = 'http://www.renren.com/PLogin.do';
my $response = $request->post($url, [
'email' => 'xxxxxxx@xxx.com',
'autoLogin' => 'true',
'domain' => 'renren.com',
'captcha_type' => 'web_login',
'password' => 'xxxxxxx',
]);

print $response->status_line;
if ($response->is_success)
{
	print encode('UTF-8', $response->decoded_content);
}



