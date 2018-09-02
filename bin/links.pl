#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::UserAgent;

my $seen = {};
my $ua = Mojo::UserAgent->new;
my $list = 'https://ediblereading.com/the-list-alphabetical/';

my @links = $ua->get($list)->res->dom->find('div.post-entry a')->each;

foreach my $l (@links) {
    my $link = $l->attr('href') or next;
    next if $seen->{$link}++;
    next if $link !~ m!/\d{4}/\d{2}/\d{2}/!;
    $link =~ s|^https?://||;
    $link = 'https://' . $link;
    print $link, "\n";
}
