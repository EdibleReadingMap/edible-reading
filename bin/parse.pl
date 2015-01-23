#!/usr/bin/env perl

use strict;
use warnings;

use Struct::Dumb 'struct';
use Mojo::JSON 'encode_json';
use Mojo::UserAgent;
$ENV{MOJO_MAX_REDIRECTS} = 2;

my $ua = Mojo::UserAgent->new;
struct Review => [qw/ name address score website date review tags /];

while (<>) {
    my $link = $_ or next;

    my $page = $ua->get( $link )->res->dom;
    my $r = Review((undef) x 6, []);

    next unless defined $page->find('header.post-title > h1')->first;
    $r->name = $page->find('header.post-title > h1')->first->text;

    ($r->review = $link) =~ s/\s+//g;
    $r->review =~ m!(\d{4}/\d{2}/\d{2})!;
    $r->date = $1;

    foreach my $tag ($page->find('div.post-extras a')->each) {
      push @{$r->tags}, ($tag->text);
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

    print encode_json {
      name    => $r->name,
      address => $r->address,
      score   => $r->score,
      website => $r->website,
      date    => $r->date,
      review  => $r->review,
      tags    => $r->tags,
    };
    print "\n";
}

