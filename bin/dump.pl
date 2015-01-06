#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class;
use XML::Writer;
use Mojo::JSON 'to_json';
use Mojo::Asset::File;
use IO::File ();

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
$writer->startTag('Document');
$writer->startTag('Style',
  id => 'restaurantIcon');
$writer->startTag('IconStyle');
$writer->startTag('Icon');
$writer->startTag('href');
$writer->characters('http://maps.google.com/mapfiles/kml/pal2/icon32.png');
$writer->endTag('href');
$writer->endTag('Icon');
$writer->endTag('IconStyle');
$writer->endTag('Style');

$rs->reset;
while (my $r = $rs->next) {
    $writer->startTag('Placemark');

    $writer->startTag('styleUrl');
    $writer->characters('#restaurantIcon');
    $writer->endTag('styleUrl');

    $writer->startTag('name');
    $writer->characters( $r->name );
    $writer->endTag('name');

    $writer->startTag('description');
    $writer->cdata(sprintf q{
      <ul>
      <li>Score: %s</li>
      <li><a href="%s">Review</a></li>
      <li><a href="%s">Website</a></li>
      </ul>
    }, $r->score, $r->review, $r->website);
    $writer->endTag('description');

    $writer->startTag('Point');
    $writer->startTag('coordinates');
    $writer->characters( $r->long .','. $r->lat .',0' );
    $writer->endTag('coordinates');
    $writer->endTag('Point');

    $writer->endTag('Placemark');
}

$writer->endTag('Document');
$writer->endTag('kml');
$writer->end;
$kml->close;
