use Tk;
use strict;

my ( $size, $step ) = ( 400, 10 );
# Create MainWindow and configure:
my $mw = MainWindow->new;
$mw->configure( -width=>$size, -height=>$size );
$mw->resizable( 0, 0 ); # not resizable in any direction
# Create and configure the canvas:
my $canvas = $mw->Canvas( -cursor=>"crosshair", -background=>"white",
              -width=>$size, -height=>$size )->pack;
# Place objects on canvas:
$canvas->createRectangle( $step, $step, $size-$step, $size-$step, -fill=>"red" );
for( my $i=$step; $i<$size-$step; $i+=$step ) {
  my $val = 255*$i/$size;
  my $color = sprintf( "#%02x%02x%02x", $val, $val, $val );
  $canvas->createRectangle( $i, $i, $i+$step, $i+$step, -fill=>$color );
}
MainLoop;