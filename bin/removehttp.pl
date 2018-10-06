#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class;

use lib qw( ../lib lib );
use ER::Schema;

my $s = ER::Schema->connect('dbi:SQLite:dbname=./edread.db');
my $rs = $s->resultset('Review');

while (my $r = $rs->next) {
    my $review = $r->review;
    $review =~ s|^http://||;
    $review =~ s|^https://||;
    $r->update({ review => $review });
}
