#!/usr/bin/perl -I perl_modules

use strict;
use warnings;

use Joplin;

# Alfred hands arguments over as UTF-8 bytes.  Decode them here so that
# everything downstream works in characters and accented titles survive.
# utf8::decode is built into the interpreter, so this loads no module.
utf8::decode($_) for @ARGV;

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
