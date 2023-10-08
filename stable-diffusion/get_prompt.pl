#!/usr/bin/perl
 
use strict;
use warnings;

my $pngh = pack 'H*', '89504e470d0a1a0a';
my $ihdr = pack 'H*', '0000000d49484452';

my $emes = '';

sub read_exif($){

  my $f = shift;
  my %e =();
  my $t = '';
  my $w = 0;
  my $h = 0;
  my $d = 0;
  my $p = '';
  my $s = 0;

  open(FH, $f) or $emes = 'Failed Open File!';

  if($emes){
    $emes = $!;
    return;
  }

  # PNG Header
  $emes = 'No PNG';
  read(FH, $t, 8);
  return if($t ne $pngh);
  # IHDR Chunk
  $emes = 'Invalid IHDR';
  read(FH, $t, 8);
  return if($t ne $ihdr);

  $emes = '';

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

  # getChunkSize()
  read(FH, $t, 4);
  $s = unpack('N', $t);

  # check tEXt
  read(FH, $t, 4);
  if($t !~ /^(iTXt|tEXt)$/){
    $emes = "tEXt: $t";
    return %e = ();
  }

  # parameters
  read(FH, $p, $s);

  if($p !~ /parameters/){
    $emes = "tEXt: Not a Stable Diffusion Parameters!";
    return %e = ();
  }

  $p =~ s/^parameters\x00//;
  $e{'parameters'} = $p;

  # CRC
  read(FH, $t, 4);
  $e{'tEXt_CRC'} = unpack('H*', $t);
  close($f);

  %e;

}

foreach my $f(@ARGV){
  if($f =~ /\.(jpe?|pn)g$/){
    $f =~ s/^file\:\/\///;
    $f =~ s/\%([0-9][0-9])/pack('H*', $1)/eg;
    my %e = read_exif($f);
    if(! $e{parameters}){
      my $m = "$f: Failure -> $emes";
      #print STDERR "$m\n";
      #getc;
      `zenity --error --window-icon="warning" --text="$m"`;
    } else{
      my($prmpt, $negtv, $sdopt) = split /\n/, $e{'parameters'};
      $prmpt =~ s/[\|]/\\|/g;
      $prmpt =~ s/[\<]/\&lt;/g;
      $prmpt =~ s/[\>]/\&gt;/g;
      $prmpt =~ s/[\x22]/\&guot;/g;
      my $m = "$prmpt";
      #print STDOUT "$m\n";
      #getc;
      `zenity --info --window-icon="info" --text="$m"`;
    }
  } 
}

__END__
