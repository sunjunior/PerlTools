use strict;

my $str = 'border-bottom-color';

while($str =~ m#-(\w)#g)
{
	my $matched = uc($1);
	$str =~ s#$&#$matched#;
}

print ($str);