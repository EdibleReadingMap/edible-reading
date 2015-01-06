#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class;

use lib qw( ../lib lib );
use ER::Schema;

my $s = ER::Schema->connect('dbi:SQLite:dbname=./edread.db');
my $rs = $s->resultset('Review');

my ($minlat, $maxlat, $minlong, $maxlong);

while (my $r = $rs->next) {
    $minlat = $r->lat if !defined $minlat or $minlat >= $r->lat;
    $maxlat = $r->lat if !defined $maxlat or $maxlat <= $r->lat;
    $minlong = $r->long if !defined $minlong or $minlong >= $r->long;
    $maxlong = $r->long if !defined $maxlong or $maxlong <= $r->long;
}

printf "lat: %s <-> %s\nlong: %s <-> %s\n",
  $minlat, $maxlat, $minlong, $maxlong;

printf "midlat: %s, mindlong: %s\n",
  ($minlat + (($maxlat - $minlat) / 2)),
  ($minlong + (($maxlong - $minlong) / 2));
