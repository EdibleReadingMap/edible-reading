#!/usr/bin/env perl

use strict;
use warnings;

use Struct::Dumb 'struct';
use IO::Socket::SSL 1.84;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::UserAgent;
use Mojo::URL;

my $ua = Mojo::UserAgent->new;
struct Review => [qw/ name address score website date review tags lat long /],
  named_constructor => 1;

while (<>) {
    my $data = decode_json $_ or next;
    my $r = Review( %$data, lat => undef, long => undef );
    my ($gapi);

    if ($ENV{DUD}) {
        (my $a = $r->address) =~ s/\s+/+/g;
        $gapi = Mojo::URL->new('https://maps.googleapis.com/maps/api/geocode/json');
        $gapi->query({ key => $ENV{GOOGLE_API_KEY}, address => $a });
    }
    else {
        (my $q = join ',', $r->name, $r->address) =~ s/\s+/+/g;
        $gapi = Mojo::URL->new('https://maps.googleapis.com/maps/api/place/textsearch/json');
        $gapi->query({ key => $ENV{GOOGLE_API_KEY}, query => $q });
    }

    my $res = $ua->get($gapi)->res;
    my $p = $res->json->{results}->[0];

    if (defined $p) {
      $r->name = $p->{name} if exists $p->{name};
      $r->address = $p->{formatted_address};
      $r->lat  = $p->{geometry}->{location}->{lat};
      $r->long = $p->{geometry}->{location}->{lng};
    }

    print encode_json {
      name    => $r->name,
      address => $r->address,
      score   => $r->score,
      website => $r->website,
      date    => $r->date,
      review  => $r->review,
      tags    => $r->tags,
      lat     => $r->lat,
      long    => $r->long,
      gdata   => (encode_json $p),
    };
    print "\n";

    sleep 1;
}

