#!/usr/bin/perl
 
use strict;
use warnings;

my $pngh = pack 'H*', '89504e470d0a1a0a';
my $ihdr = pack 'H*', '0000000d49484452';

sub read_exif($){

  my $f = shift;
  my %e;
  my $t = '';
  my $w = 0;
  my $h = 0;
  my $d = 0;
  my $p = '';
  my $s = 0;

  open(FH, $f) or return;

  # PNG Header
  read(FH, $t, 8);
  return if($t ne $pngh);
  # IHDR Chunk
  read(FH, $t, 8);
  return if($t ne $ihdr);

  $e{'PNG'} = 1;

  # Width
  read(FH, $t, 4);
  $e{'width'} = unpack('N', $t);
  # Height
  read(FH, $t, 4);
  $e{'height'} = unpack('N', $t);
  # Pixel Depth
  read(FH, $t, 1);
  $e{'depth'} = unpack('N', $t);
  # Color Type
  read(FH, $t, 1);
  $e{'color'} = unpack('C', $t);
  # Compression Method
  read(FH, $t, 1);
  $e{'compression'} = unpack('C', $t);
  # Filter Type
  read(FH, $t, 1);
  $e{'filter'} = unpack('C', $t);
  # Interlace
  read(FH, $t, 1);
  $e{'interlace'} = unpack('C', $t);
  # CRC
  read(FH, $t, 4);
  $e{'CRC'} = unpack('H*', $t);

  $e{'parameters_Pos'} = tell FH;

  # getChunkSize()
  read(FH, $t, 4);
  $s = unpack('N', $t);
  # Size of parameters
  $e{'parameters_Size'} = $s;

  # check tEXt
  read(FH, $t, 4);
  if($t ne 'tEXt' && $t ne 'iTXt'){
    print STDOUT "tEXt: $t\n;";
    return undef;
  }

  # parameters
  read(FH, $p, $s);
  $e{'parameters'} = $p;

  if($p !~ /parameters/){
    print STDOUT "tEXt: Not a Stable Diffusion Parameters!\n;";
    return undef;
  }

  # CRC
  read(FH, $t, 4);
  $e{'tEXt_CRC'} = unpack('H*', $t);
  close($f);

  %e;

}

# Like simple `mogrify -strip "$n"` for @ARGV, not same `cmp -b A B`; from mogrify results;;;

foreach my $f(@ARGV){
  if($f =~ /\.(jpe?g|png)$/ && -f $f){
    my %e;
    next if(! (%e = read_exif($f)));
    next if($e{'parameters'} !~ /^parameters/);
    my $n = $f;
    my $m = $f;
    $n =~ s/\.(jpe?g|png)$/\.noexif\.$1/;
    $m =~ s/\.(jpe?g|png)$/\.mogrify\.$1/;
    print STDOUT "$f -> $n\n";
    open(IFH, "<$f");
    binmode IFH;
    my $if = '';
    read(IFH, $if, (-s $f));
    close(IFH);
    my $s = substr($if, $e{'parameters_Pos'}, 4, '');
    my $t = substr($if, $e{'parameters_Pos'}, 4, '');
    my $p = substr($if, $e{'parameters_Pos'}, $e{'parameters_Size'}, '');
    my $c = substr($if, $e{'parameters_Pos'}, 4, '');
    print STDOUT "$e{'parameters_Pos'}($e{'parameters_Size'}): $p\n";
    open(OFH, ">$n");
    binmode OFH;
    print OFH $if;
    close(OFH);
  }
}

__END__
