use File::Spec;
$ARGV[0]="DiagFile";
die 'input the pkt file!' unless(scalar @ARGV);#如果没有指定file，退出

my $path_curf = File::Spec->rel2abs(__FILE__);
my ($vol, $dirs, $file) = File::Spec->splitpath($path_curf);

$inputFile = $ARGV[0];

open FH, $inputFile;
$outputFile = $dirs.'result.txt';
print "Save Format result to $vol\\$outputFile\n\n\n";
open WH, ">$outputFile";
@lines =<FH>;

close FH;

for $line (@lines)
{
	print "\n\n\n" if $line =~ m#^rx packet cos#;
	print WH "\n\n\n" if $line =~ m#^rx packet cos#;
	next unless $line =~ m#^recv data#;
	chomp($line);
	$line =~ s#^recv data.*:\s+##;
	$line =~ s#[0-9a-f]{2}#$& #g;
    $line =~ s#\s+$##;
    print $line."\n";
    
	print WH $line."\n";
}

close FH;
close WH;