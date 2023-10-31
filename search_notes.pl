#!/usr/bin/perl -I .

use strict;
use warnings;

use Joplin;

my $find = join(' ', @ARGV);

my $tmpl = '"title":"%s","subtitle":"%s","arg":"%s"';

my $data = Joplin::get_data(["search"], { "query" => $find });

if (exists $data->{items} && @{$data->{items}}) {
    my @items = @{$data->{items}};
    print '{"items":[{' . join('},{', map({ sprintf($tmpl, $_->{"title"},$_->{"title"},$_->{"id"}) } @items)) . '}]}';
}
elsif (exists $data->{error}) {
    my @lines = split(/\n/, $data->{error});
    $lines[0] =~ s/"/'/g;
    print '{"items":[{' . sprintf($tmpl, 'Error', Joplin::parse_error($data), 0) . '}]}';
}
else {
    print '{"items":[{"title":"No notes found","subtitle":"Please try a different search"}]}';
}