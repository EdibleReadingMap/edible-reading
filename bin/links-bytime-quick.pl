#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::UserAgent;

my $seen = {};
my $ua = Mojo::UserAgent->new;

foreach my $year (19) {
  foreach my $month ('07' .. '12') {
    my $list = "https://ediblereading.com/20$year/$month/";
    my $page = $ua->get($list) or next;
    my @links = $page->res->dom->find('h1.entry-title a')->each;

    foreach my $l (@links) {
        my $link = $l->attr('href') or next;
        next if $seen->{$link}++;
        next if $link !~ m!/\d{4}/\d{2}/\d{2}/!;

        my $review = $ua->get($link) or next;
        my $cat = $review->res->dom->find('span.cat-links a')->first;
        next unless $cat and $cat->text eq 'Reviews';

        $link =~ s|^https?://||;
        print $link, "\n";
    }
  }
}
