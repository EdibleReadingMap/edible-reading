#!/usr/bin/env perl

use strict;
use warnings;

use Struct::Dumb 'struct';
use IO::Socket::SSL 1.84;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::UserAgent;
use Mojo::URL;

die "Please set Google API key in GOOGLE_API_KEY environment variable.\n"
  if not $ENV{GOOGLE_API_KEY};

struct Review => [qw/ name address score website date review tags lat long /],
  named_constructor => 1;

while (<>) {
    my $data = decode_json $_ or next;
    my $r = Review( %$data, lat => undef, long => undef );
    my $p = google_get($r);

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
      tags    => (encode_json $r->tags),
      lat     => $r->lat,
      long    => $r->long,
      gdata   => (encode_json $p),
    };
    print "\n";

    sleep 1;
}

sub google_get {
  my $r = shift;
  my $ua = Mojo::UserAgent->new;
  my ($gapi, $res);

  unless ($r->address) {
    print STDERR sprintf "error: no address for %s\n", $r->name;
    exit 1;
  }

  (my $a = $r->address) =~ s/\s+/+/g;
  $gapi = Mojo::URL->new('https://maps.googleapis.com/maps/api/geocode/json');
  $gapi->query({ key => $ENV{GOOGLE_API_KEY}, address => $a });
  $res = $ua->get($gapi)->res;

  if ($res->json->{status} and $res->json->{status} eq 'OVER_QUERY_LIMIT') {
    print STDERR "error: exceeded quota with google api\n";
    exit 1;
  }

  if ($res->json->{status} and $res->json->{status} eq 'REQUEST_DENIED') {
    print STDERR "error: request denied\n";
    use DDP; p $res->json;
    exit 1;
  }

  unless ($res->json->{results}->[0]->{geometry}->{location}->{lat}) {
    print STDERR sprintf "warning: didn't find geocode for %s, falling back to placesearch\n", $r->name;

    (my $q = join ',', $r->name, $r->address) =~ s/\s+/+/g;
    $gapi = Mojo::URL->new('https://maps.googleapis.com/maps/api/place/textsearch/json');
    $gapi->query({ key => $ENV{GOOGLE_API_KEY}, query => $q });
    $res = $ua->get($gapi)->res;
  }

  return $res->json->{results}->[0];
}

