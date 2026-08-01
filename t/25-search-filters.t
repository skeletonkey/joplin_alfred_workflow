#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

require './search_notes.pl';

my $default_fields = 'id,title,updated_time';

my $plain_filters = _get_filters();

is($plain_filters->{fields}, $default_fields);