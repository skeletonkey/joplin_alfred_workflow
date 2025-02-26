#!/usr/bin/perl -I perl_modules

use strict;
use warnings;

use Joplin;

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
