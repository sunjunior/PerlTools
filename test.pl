my @lines = <DATA>;

for my $line (@lines)
{
	$line =~ s#}\.?#}\n\.#g;
	print $line;
	 
	
	
}

__DATA__
