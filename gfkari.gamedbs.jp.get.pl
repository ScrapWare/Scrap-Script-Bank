#!/usr/bin/perl

use strict;
use warnings;

use LWP::Simple qw(get getstore head);

# USAGE:
#
# Set base local directory in the first time.
my $locd = "/home/gfkari";
#
# argument is numbers for gfkari.gamedbs.jp/girl/details/[number]
#

my $site = "https://gfkari.gamedbs.jp";
my $base = "https://gfkari.gamedbs.jp/girl/detail";

# cid
my $card = "https://gfkari.gamedbs.jp/card/group";
# mid
my $gfms = "https://gfkari.gamedbs.jp/gfmusic/card/group";

sub store($$){

  my($num, $img) = @_;

  $img =~ s/^$site//;

  my $sav = $img;

  $sav =~ s/^\/images//;
  $sav = "$locd/$num$sav";

  my $mkd = $sav;

  $mkd =~ s/\/[^\/]+$//;

  if(!-d $mkd){
    print STDOUT "[mkdir -p $mkd]\n";
    `mkdir -p $mkd`;
  }

  return if(-f $sav);

  print STDOUT "$site$img -> $sav\n";

  getstore("$site$img", $sav);

}

sub getcid($$){

  my($num, $cid) = @_;

  my $htm = get("$card/$cid");

  # CID Image
  while($htm =~ /href=\x22([^\x22]+\.(avif|gif|jpe?g|png|webp))\x22/g){
    store($num, $1);
  }

}

sub getmid($$){

  my($num, $mid) = @_;

  my $htm = get("$gfms/$mid");

  # MID Image
  while($htm =~ /href=\x22(\/images\/[^\x22]+)\x22/g){
    store($num, $1);
  }

}

sub getton($){

  my $num = shift;
  my $url = "$base/$num";

  my $htm = get($url);

  # cid
  while($htm =~ /<a\x20href=\x22[^\x22]+cid=([0-9]+)\x22\x20id=\x22([0-9]+)\x22/g){
    getcid($num, $1);
  }
  while($htm =~ /<a\x20href=\x22[^\x22]+_mid=([0-9]+)\x22\x20data\-cgi=\x22/g){
    getmid($num, $1);
  }

  # Standing Image
  while($htm =~ /class=\x22tc\x20trsb\x20prf\-sw\x22\x20data\-url=\x22([^\x22]+)\x22/g){
    store($num, $1);
  }

  # Thumbnail Image
  while($htm =~ /data\-original=\x22([^\x22]+)\x22/g){
    store($num, $1);
  }

  # Normal Link Image
  while($htm =~ /href=\x22([^\x22]+\.(avif|gif|jpe?g|png|webp))\x22/g){
    store($num, $1);
  }

}

foreach my $args(@ARGV){
  if($args =~ /^[0-9]+$/){
    my @ret = head("$base/$args\.html");
    (scalar @ret)? getton($args) : print STDERR "getton: Could not head $base/$args\.html";
  }
}

__END__
