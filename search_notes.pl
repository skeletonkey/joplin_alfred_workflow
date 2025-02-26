#!/usr/bin/perl -I perl_modules -s

use strict;
use warnings;
use vars qw($t);

use Joplin;
use Jundy::AlfredWorkflow::Filter;

$t ||= 0; # search titles only

my $find = join(' ', @ARGV);

my $data = Joplin::get_data(
    ["search"],
    { fields => 'id,title', order_by => "updated_time", query => $find, }
);

my %display_data = (
    data  => [],
    empty => { title => "No notes found", subtitle => "Please try a different search" },
);
if (exists $data->{items} && @{$data->{items}}) {
    my @items = @{$data->{items}};
    if ($t) { # search only titles
        @items = grep { $_->{title} =~ /$find/i } @items;
    }
    map { push(@{$display_data{data}}, { title => $_->{title}, subtitle => $_{title}, arg => $_->{id} }) } @items;
}
elsif (exists $data->{error}) {
    my @lines = split(/\n/, $data->{error});
    $lines[0] =~ s/"/'/g;
    $display_data{empty} = { title => 'Error', subtitle => Joplin::parse_error($data) };
}

Jundy::AlfredWorkflow::Filter::display(\%display_data)