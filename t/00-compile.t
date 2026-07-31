#!/usr/bin/perl

# Every script and module the workflow ships has to compile against the perl
# that Apple ships, using only the bundled modules.

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Find;
use Test::More;

my $root = dirname(__FILE__) . '/..';

my @scripts = sort glob("$root/*.pl");
my @modules;
find(sub { push(@modules, $File::Find::name) if /\.pm$/ }, "$root/perl_modules");
@modules = sort @modules;


ok(scalar(@scripts) >= 4, 'found the workflow scripts');

foreach my $file (@scripts, @modules) {
    (my $name = $file) =~ s{^\Q$root\E/}{};

    my $output = qx{cd "$root" && $^X -I perl_modules -c "$name" 2>&1};

    like($output, qr/syntax OK/, "$name compiles")
        or diag($output);
}

done_testing();
