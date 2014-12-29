#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class;

use lib qw( ../lib lib );
use ER::Schema;
use Data::Dumper;

my $in = ER::Schema->connect('dbi:Pg:dbname=er;host=127.0.0.1');
my $out = ER::Schema->connect('dbi:SQLite:dbname=./edread.db');

my $rsin = $in->resultset('Review');
my $rsout = $out->resultset('Review');

while (my $r = $rsin->next) {
    $rsout->create({
        name => $r->name,
        address => $r->address,
        website => $r->website,
        date => $r->date,
        review => $r->review,
        score => $r->score,
        lat => $r->lat,
        long => $r->long,
        gdata  => $r->gdata,
        tags => Dumper ($r->tags),
    });
}
