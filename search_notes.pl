#!/usr/bin/perl -I .

use strict;
use warnings;

use Joplin;

find_link(@ARGV);

sub find_link {
    my $find = join(' ', @ARGV);

    my $tmpl = '"title":"%s","subtitle":"%s","arg":"%s"';

    my $data = Joplin::get_data(["search"], { "query" => $find });

    if (@{$data->{items}}) {
        my @items = @{$data->{items}};
        print '{"items":[{' . join('},{', map({ sprintf($tmpl, $_->{"title"},$_->{"title"},$_->{"id"}) } @items)) . '}]}';
    }
    else {
        print '{"items":[{"title":"No links found","subtitle":"Please try a different search"}]}';
    }
}