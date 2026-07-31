#!/usr/bin/perl -I perl_modules

use strict;
use warnings;

use Encode qw(decode_utf8);

use Joplin;

# Alfred hands arguments over as UTF-8 bytes.  Decode them here so that
# everything downstream works in characters and accented titles survive.
@ARGV = map { decode_utf8($_) } @ARGV;

my $folder_id = $ARGV[0];
my $title     = $ARGV[1];

my $ret = Joplin::post_data(
    ['notes'],
    {},
    {
        title     => $title,
        body      => '',
        parent_id => $folder_id,
    }
);

print $ret->{id};
