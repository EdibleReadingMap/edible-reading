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
my $rs = $s->resultset('Review')->search(undef, { order_by => 'date' });

my @features = ();
while (my $r = $rs->next) {
    # next if $r->tags =~ m/"closed"/i;
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
            Review => ('https://'. $r->review),
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

my $kml = IO::File->new('>docs/edread.kml');
my $writer = XML::Writer->new(
  OUTPUT => $kml,
  DATA_MODE => 1,
  DATA_INDENT => 2,
);
$writer->xmlDecl("UTF-8");
$writer->startTag('kml',
  xmlns => 'http://www.opengis.net/kml/2.2');
$writer->startTag('Document');

my %pins = (
  lowIcon => 'pink',
  medlowIcon => 'ylw',
  medhighIcon => 'blu',
  highIcon => 'grn',
  hiddenIcon => 'wht',
);

while (my ($id, $pin) = each %pins) {
    $writer->startTag('Style', id => $id);
    $writer->startTag('IconStyle');
    $writer->startTag('Icon');
    $writer->startTag('href');
    $writer->characters("http://maps.google.com/mapfiles/kml/paddle/$pin-blank_maps.png");
    $writer->endTag('href');
    $writer->endTag('Icon');
    $writer->endTag('IconStyle');
    $writer->endTag('Style');
}

$rs->reset;
while (my $r = $rs->next) {
    # next if $r->tags =~ m/"closed"/i;
    $writer->startTag('Placemark');

    $writer->startTag('styleUrl');
    $writer->characters(
      ($r->tags =~ m/"closed"/i) ? '#hiddenIcon' :
      ($r->score >= 8.0) ? '#highIcon' :
      ($r->score >= 7.5) ? '#medhighIcon' :
      ($r->score >= 6.5) ? '#medlowIcon' : '#lowIcon'
    );
    $writer->endTag('styleUrl');

    $writer->startTag('name');
    $writer->characters( $r->name );
    $writer->endTag('name');

    $writer->startTag('description');
    $writer->cdata(sprintf q{
      Score: %s<br/>
      <a href="%s" target="_blank">Review</a><br/>
      <a href="%s" target="_blank">Website</a>
    }, ($r->score || ''), ('https://'. $r->review), ($r->website || ''));
    $writer->endTag('description');

    $writer->startTag('Point');
    $writer->startTag('coordinates');
    if ($r->long and $r->lat) {
      $writer->characters( $r->long .','. $r->lat .',0' );
    }
    else {
      print STDERR sprintf "warning: missing LAT/LONG for %s\n", $r->review;
    }
    $writer->endTag('coordinates');
    $writer->endTag('Point');

    $writer->endTag('Placemark');
}

$writer->endTag('Document');
$writer->endTag('kml');
$writer->end;
$kml->close;
