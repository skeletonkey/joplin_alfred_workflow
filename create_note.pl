#!/usr/bin/perl -I .

use strict;
use warnings;

use Joplin;

my $folder_id = $ARGV[0];

my $ret = Joplin::post_data(
    ['notes'],
    {},
    {
        title     => '',
        body      => '',
        parent_id => $folder_id,
    }
);

print $ret->{id};