#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use TestWorkflow;

# Requiring the script runs it, not just its subs: it searches and prints the
# result.  TestWorkflow keeps that off the network, and swallowing STDOUT keeps
# the Alfred JSON - which has no trailing newline - out of the TAP stream.
my $workflow = TestWorkflow->new;
$workflow->respond('{"items":[]}');

# require needs a variable here; anything that starts with a bareword is
# parsed as a module name instead of a path.
my $script = TestWorkflow::root() . '/search_notes.pl';

do {
    local *STDOUT;
    open(STDOUT, '>', \my $ignored) or die $!;
    require $script;
    close(STDOUT);
};

my $default_fields = 'id,title,updated_time';
my $default_query = 'test';

my $plain_filters = _get_filters($default_query);

is($plain_filters->{fields}, $default_fields);
is($plain_filters->{query}, $default_query);
ok(!exists($plain_filters->{order_by}));
ok(!exists($plain_filters->{order_dir}));

my $search_order_by = 'updated_time';
my $search_order_dir = 'DESC';
$ENV{search_order_by} = $search_order_by;
$ENV{search_order_direction} = $search_order_dir;

my $search_filters = _get_filters($default_query);

is($search_filters->{fields}, $default_fields);
is($search_filters->{query}, $default_query);
ok(exists($search_filters->{order_by}));
ok(exists($search_filters->{order_dir}));
is($search_filters->{order_by}, $search_order_by);
is($search_filters->{order_dir}, $search_order_dir);
