package ER::Schema::Result::Review;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("review");

__PACKAGE__->add_columns(
  "review",
  { data_type => "text", is_nullable => 0 },
  "score",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "address",
  { data_type => "text", is_nullable => 1 },
  "website",
  { data_type => "text", is_nullable => 1 },
  "date",
  { data_type => "date", is_nullable => 1 },
  "lat",
  { data_type => "text", is_nullable => 1 },
  "long",
  { data_type => "text", is_nullable => 1 },
  "tags",
  { data_type => "text[]", is_nullable => 1 },
  "gdata",
  { data_type => "json", is_nullable => 1 },
);

__PACKAGE__->set_primary_key('review');

1;
