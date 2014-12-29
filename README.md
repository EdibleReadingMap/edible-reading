# Edible Reading Map

[Edible Reading](http://ediblereading.com/) is a blog of restaurant/cafe food reviews on venues in the area of Reading, Berkshire, UK.
The code in this repo scrapes info from the website, put it into a database, then produces a [GeoJSON](http://en.wikipedia.org/wiki/GeoJSON) map.

Github kindly renders the GeoJSON [map](https://github.com/ollyg/edible-reading/blob/master/edread.geojson) (desktop browsers only).

# Workflow

Something like the following:

````
$ cd bin
$ links.pl > links
$ cat links | parse.pl | google.pl | save.pl
$ cd ..
$ bin/dump.pl
````

Yes, the `cat` is intentional; forces correct encoding.

# Google Locations and Places

The `google.pl` script makes use of the Google Locations and Places APIs to geolocate the venues. You'll need an API key.

# Database

At home I used PostgreSQL but I've included an SQLite3 copy of the database in the repo. The scripts are set up to use the SQLite3 copy.

# Dependencies

I think you'll need [Mojolicious](https://metacpan.org/pod/Mojolicious) and [DBIx::Class](https://metacpan.org/pod/DBIx::Class). Might rewrite it in Python one day, but I wanted to play with Mojo and this was a good excuse.

# Author

[Oliver Gorwits](mailto:oliver@cpan.org)

With thanks to Edible Reading!
