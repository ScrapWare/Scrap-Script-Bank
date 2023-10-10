#!/usr/bin/perl

use strict;
use warnings;

# USAGE:
#
# Set base local directory in the first time.
my $locd = "/home/gfkari";
#
# argument is numbers for gfkari.gamedbs.jp/girl/details/[number]
#

sub cropcards($){

  my $num = shift;
  my $dir = "$locd/$num/card";
  my $new = "$locd/$num/card_crop";
  
  `mkdir -p "$new"` if(! -d $new);

  opendir(DIR, $dir); foreach my $i(readdir(DIR)){
    if($i =~ /\.(avif|gif|jpe?g|png|webp)$/){
      my $cmd = qq|convert \x22$dir/$i\x22 -crop +102+20 -crop -64-80 \x22$new/$i\x22|;
      print STDOUT "$cmd\n";
      `$cmd`;
    }
  }; closedir(DIR);

}

foreach my $args(@ARGV){
  if($args =~ /^[0-9]+$/){
    (-d "$locd/$args/card")? cropcards($args) : print STDERR "cropcards: Could not found $locd/$args/card";
  }
}

__END__
