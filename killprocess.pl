#!/usr/bin/perl -w

# 创建STDOUT句柄的一个副本，之后可以关闭STDOUT
open my $oldout, '>&', \*STDOUT or die "Cannot dup STDOUT: $!";
# 重新将STDOUT打开为文件output.txt的句柄
# 在打开文件之前，Perl会将原来保存在STDOUT中的句柄关闭
open STDOUT, '>', 'cmd.txt' or die "Cannot reopen STDOUT: $!";
# 接下来的默认输出将会写入到output.txt
system " tasklist /nh /fi \"IMAGENAME eq cmd.exe\"";
# 从原有的STDOUT副本中恢复默认的STDOUT
open STDOUT, '>&', $oldout or die "Cannot dup \$oldout: $!";

open FH, "cmd.txt";
@process = <FH>;
print @process;
close FH;
unlink("cmd.txt");
for my $process (@process)
{
	chomp($process);
	my ($pro, $pid) = split(/\s+/, $process) if ($process);
	print "kill $pid for $pro... \n";
    system "ntsd -c q -p $pid";#强制杀死所有进程
	
}

unlink(STDOUT);







