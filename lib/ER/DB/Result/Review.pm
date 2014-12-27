package ER::DB::Result::Review;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("review");

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "reviews_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "address",
  { data_type => "text", is_nullable => 1 },
  "website",
  { data_type => "text", is_nullable => 1 },
  "date",
  { data_type => "date", is_nullable => 1 },
  "review",
  { data_type => "text", is_nullable => 1 },
  "lat",
  { data_type => "text", is_nullable => 1 },
  "lng",
  { data_type => "text", is_nullable => 1 },
  "tags",
  { data_type => "text[]", is_nullable => 1 },
  "tags_lc",
  { data_type => "text[]", is_nullable => 1 },
  "gapi",
  { data_type => "json", is_nullable => 1 },
  "score",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key('name');

1;
