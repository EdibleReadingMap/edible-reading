use strict;
use warnings;

use Data::Printer;
use Struct::Dumb 'struct';
use IO::Socket::SSL 1.84;

use DBIx::Class;
use Mojo::UserAgent;
use Mojo::URL;

use lib 'lib';
use lib '../lib';
use ER::DB;

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
struct Review => [qw/ name address score website date review lat lng tags tags_lc /];

my $seen = {};
my $ua = Mojo::UserAgent->new;
my $list = 'http://ediblereading.com/the-list-alphabetical/';

my @links = (scalar @ARGV == 0)
  ? $ua->get($list)->res->dom->find('div.post-entry a')->each
  : $ARGV[0];

foreach my $link (@links) {
  my $r = get_review($link) or next;
  next if $seen->{$r->name}++;

  (my $q = join ',', $r->name, $r->address) =~ s/\s+/+/g;
  my $gapi = Mojo::URL->new('https://maps.googleapis.com/maps/api/place/textsearch/json');
  $gapi->query({ key => $ENV{GOOGLE_API_KEY}, query => $q, types => 'food' });

  my $res = $ua->get($gapi)->res;
  my $p = $res->json->{results}->[0];

  if (defined $p and scalar @ARGV == 0) {
    $r->name = $p->{name};
    $r->address = $p->{formatted_address};
    $r->lat = $p->{geometry}->{location}->{lat};
    $r->lng = $p->{geometry}->{location}->{lng};
  }
  p $r->name;

  my $s = ER::DB->connect('dbi:Pg:dbname=er;host=127.0.0.1');
  $s->resultset('Review')->find_or_create({
    name => $r->name,
    address => $r->address,
    website => $r->website,
    date => $r->date,
    review => $r->review,
    tags => $r->tags,
    tags_lc => $r->tags_lc,
    gapi => $res->body,
    score => $r->score,
    lat => $r->lat,
    lng => $r->lng,
  });
}

sub get_review {
  my $link = shift;
  $link = $link->attr('href') if ref $link;
  my $page = $ua->get( $link )->res->dom;
  my $r = Review((undef) x 8, [], []);

  return if !defined $page->find('header.post-title h1')->first;
  $r->name = $page->find('header.post-title h1')->first->text;

  $r->review = $link;
  $r->review =~ m!(\d{4}/\d{2}/\d{2})!;
  $r->date = $1;

  foreach my $tag ($page->find('div.post-extras a')->each) {
    push $r->tags, $tag->text;
    push $r->tags_lc, $tag->text if $tag->text =~ m/^[a-z]+$/;
  }

  foreach my $score ($page->find('div.post-entry p > strong, b')->each) {
    next if $score->text !~ m/ \d+\.\d+$/;
    ($r->score = $score->text) =~ s/.+ //;

    # a couple of entries have malformed tags
    $r->address = $score->following('em, i')->first
      ? $score->following('em, i')->first->text
      : $score->parent->text;

    # trim phone number sometimes after post code
    $r->address =~ s/[ 0-9]+$//;

    $r->website = $score->parent->following('p')->first
      ? $score->parent->following('p')->first->children('a')->first
        ? $score->parent->following('p')->first->children('a')->first->attr('href')
        : $score->following('a')->first->attr('href')
      : undef;
    last;
  }

  return $r;
}

