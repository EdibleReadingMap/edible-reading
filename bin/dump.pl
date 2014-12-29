#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class;
use Mojo::JSON 'encode_json';
use Mojo::Asset::File;

use lib qw( ../lib lib );
use ER::Schema;

binmode STDOUT, ":encoding(UTF-8)";
my $s = ER::Schema->connect('dbi:Pg:dbname=er;host=127.0.0.1');
my $rs = $s->resultset('Review');

my @features = ();
while (my $r = $rs->next) {
    push @features, {
        type => 'Feature',
        id => $r->review,
        geometry => {
            type => 'Point',
            coordinates => [ $r->lat, $r->long ],
        },
        properties => {
            title => $r->name,
            'marker-symbol' => 'restaurant',
            rating => $r->score,
            website => $r->website,
        },
    };
}

my $data = {
    type => 'FeatureCollection',
    features => \@features,
};

my $file = Mojo::Asset::File->new;
$file->add_chunk( encode_json( $data ) );
$file->move_to('./edread.geojson');

