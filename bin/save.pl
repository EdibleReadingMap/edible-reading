#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class;
use Mojo::JSON 'decode_json';

use lib qw( ../lib lib );
use ER::Schema;

binmode STDOUT, ":encoding(UTF-8)";
my $s = ER::Schema->connect('dbi:SQLite:dbname=./edread.db');

while (<>) {
    my $data = decode_json $_ or next;
    print "saving: ", $data->{name}, "\n";
    $s->resultset('Review')->update_or_create(%$data);
}

