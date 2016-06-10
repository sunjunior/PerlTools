#!/usr/bin/perl -w
use strict;
use IO::Dir;
use IO::File;
use File::Path qw(remove_tree rmtree);
#按照系统版本、设备类型、项目源码路径三项参数输入
#@ARGV = ('D:\ZAR\SVNV2.1Code', '6130xgs', '');

exit(0) if (3 != scalar @ARGV);

my $basepath   = $ARGV[0];
my $choosetype = $ARGV[1];
my $sysver     = $ARGV[2];



my $versioncfgpath = "$basepath\\SW_PT\\SRC_PRJ\\make";
my $imgversionfile = "$basepath\\SW_PT\\IMG\\imgversion.txt";

my $install_prj_version_str     = "ZXCTN 620063006220 V2.10.00";
my $install_prj_version         = "ZXCTN 620063006220 V2.10.00";
my $install_iptn_prj_version    = "ZXCTN 620063006220 V2.10.00";
my $install_copyright           = "2001-2014";
my $logo_product_type           = "6263";
my $install_engineering_version = "1";

if ( $sysver =~ m/^\s*$/ ) {
	print "系统版本号为空，按照每日构建版本处理!\n";
	$sysver = "";
}

if ( $choosetype eq '6263' ) {
	$logo_product_type        = "6263";
	$install_prj_version_str  = "ZXCTN 620063006220 V2.10.00$sysver";
	$install_prj_version      = $install_prj_version_str;
	$install_iptn_prj_version = $install_prj_version_str;
	print "$install_prj_version_str\n";
}
elsif ( $choosetype eq '6130xgs' ) {
	$logo_product_type        = "6130xgs";
	$install_prj_version_str  = "ZXCTN 6130XG-S V2.10.00$sysver";
	$install_prj_version      = $install_prj_version_str;
	$install_iptn_prj_version = $install_prj_version_str;
	print "$install_prj_version_str\n";
}
elsif ( $choosetype eq '6130' ) {
	$logo_product_type        = "6130";
	$install_prj_version_str  = "ZXCTN 6130 V2.10.00$sysver";
	$install_prj_version      = $install_prj_version_str;
	$install_iptn_prj_version = $install_prj_version_str;
	print "$install_prj_version_str\n";
}
else {
	print "输入设备类型不支持，请重新选择！\n";
	exit(1);
}

my @cfgfiles;
my $dh = IO::Dir->new($versioncfgpath);
while ( defined( $_ = $dh->read ) ) {
  next if $_ eq '.' or $_ eq '..';
  push @cfgfiles, "$versioncfgpath\\$_"
	if $_ =~ m/version.*\.cfg/;    #保存绝对路径
}
$dh->close();

#将imgversion.txt文件路径也保存起来
push @cfgfiles, $imgversionfile;

foreach my $cfgfile (@cfgfiles) {
  my $fh = new IO::File " <$cfgfile";
  print "$cfgfile\n";
  my @cfginfo = <$fh> if ( defined $fh );
  $fh->close;
  my $cfginfo = join( '', @cfginfo );
  $cfginfo =~ s{INSTALL_PRJ_VERSION_STR\s+=(.*?)$}
	{INSTALL_PRJ_VERSION_STR   = $install_prj_version_str}m;

  $cfginfo =~ s{INSTALL_PRJ_VERSION\s+=(.*?)$}
	{INSTALL_PRJ_VERSION   = $install_prj_version}m;

  $cfginfo =~ s{INSTALL_IPTN_PRJ_VERSION\s+=(.*?)$}
	{INSTALL_IPTN_PRJ_VERSION   = $install_iptn_prj_version}m;

  $cfginfo =~ s{INSTALL_COPYRIGHT\s+=(.*?)$}
	{INSTALL_COPYRIGHT         = $install_copyright}m;

  $cfginfo =~ s{LOGO_PRODUCT_TYPE\s+=(.*?)$}
	{LOGO_PRODUCT_TYPE          = $logo_product_type}m;

  $cfginfo =~ s{INSTALL_ENGINEERING_VERSION\s+=(.*?)$}
	{INSTALL_ENGINEERING_VERSION = $install_engineering_version}m;

  $cfginfo =~ s{\@ZXCTN(.*?)$}
	{\@$install_prj_version_str}m;

  print $cfginfo;

  my $wh = new IO::File " >$cfgfile";
  if ( defined $wh ) {
	  $wh->write($cfginfo);
	  $wh->close;
  }

  print "#####################################\n";
}

my @deletefiles = ( '\SRC_IOS\Ros\Include\zxr10ver.h',
  '\SW_PT\TARGET\mp\MP8541\bsp\Zxr10ver.h',
  '\OBJ_6900\MP\mp8541\OBJ_IOS\oam\execute',
  '\OBJ_6900\MP\mp8541\OBJ_IOS\ros',
  '\OBJ_6900\MP\mp8541\OBJ_PRJ\ros',
  '\SW_PT\TARGET\mp\MP2010\bsp\zxr10ver.h',
  '\OBJ_6900\MP\mp2010\OBJ_IOS\oam\execute',
  '\OBJ_6900\MP\mp2010\OBJ_IOS\ros',
  '\OBJ_6900\MP\mp2010\OBJ_PRJ\ros',
  '\SW_PT\TARGET\mp\MP8347\bsp\zxr10ver.h',
  '\OBJ_6900\MP\mp8347\OBJ_IOS\oam\execute',
  '\OBJ_6900\MP\mp8347\OBJ_IOS\ros',
  '\OBJ_6900\MP\mp8347\OBJ_PRJ\ros' );

my @abspath = map { $basepath . $_ } @deletefiles;

for my $file (@abspath) {
  print $file, "\n";
  if ( -e -f $file ) {
	  unlink($file);
  }
  elsif ( -e -d $file ) {
	  rmtree( $file, 1, 0 );
  }
}
