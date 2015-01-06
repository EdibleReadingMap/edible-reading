#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class;
use XML::Writer;
use Mojo::JSON 'to_json';
use Mojo::Asset::File;

use lib qw( ../lib lib );
use ER::Schema;

my $s = ER::Schema->connect('dbi:SQLite:dbname=./edread.db');
my $rs = $s->resultset('Review');

my @features = ();
while (my $r = $rs->next) {
    push @features, {
        type => 'Feature',
        id => $r->review,
        geometry => {
            type => 'Point',
            coordinates => [ $r->long, $r->lat ],
        },
        properties => {
            Title => $r->name,
            'marker-symbol' => 'restaurant',
            Rating => $r->score,
            Website => $r->website,
            Review => $r->review,
        },
    };
}

my $data = {
    type => 'FeatureCollection',
    features => \@features,
};

my $json = Mojo::Asset::File->new;
$json->add_chunk( to_json( $data ) );
$json->move_to('./edread.geojson');

my $kml = IO::File->new('>html/edread.kml');
my $writer = XML::Writer->new(
  OUTPUT => $kml,
  DATA_MODE => 1,
  DATA_INDENT => 2,
);
$writer->xmlDecl("UTF-8");
$writer->startTag('kml',
  xmlns => 'http://www.opengis.net/kml/2.2');

$rs->reset;
while (my $r = $rs->next) {
    $writer->startTag('Placemark');

    $writer->startTag('name');
    $writer->characters( $r->name );
    $writer->endTag('name');

    $writer->startTag('description');
    $writer->characters( $r->score );
    $writer->endTag('description');

    $writer->startTag('Point');
    $writer->startTag('coordinates');
    $writer->characters( $r->long .','. $r->lat );
    $writer->endTag('coordinates');
    $writer->endTag('Point');

    $writer->endTag('Placemark');
}

$writer->endTag('kml');
$writer->end;
$kml->close;
