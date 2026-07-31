#!/usr/bin/perl -I perl_modules -s

use strict;
use warnings;
use vars qw($t);

use Joplin;
use Jundy::AlfredWorkflow::Filter;
use Jundy::AlfredWorkflow::Update;

$t ||= 0; # search titles only

# Alfred hands arguments over as UTF-8 bytes.  Decode them here so that
# everything downstream works in characters and accented searches match.
# utf8::decode is built into the interpreter, so this loads no module.
utf8::decode($_) for @ARGV;

Jundy::AlfredWorkflow::Update::check_in_background();

my $find = join(' ', @ARGV);

my $data = Joplin::get_data(
    ["search"],
    { fields => 'id,title,updated_time', order_by => "updated_time", query => $find, }
);

my %display_data = (
    data   => [],
    empty  => { title => "No notes found", subtitle => "Please try a different search" },
    append => [ Jundy::AlfredWorkflow::Update::notice_item() ],
);
if (exists $data->{items} && @{$data->{items}}) {
    my @items = @{$data->{items}};
    if ($t) { # search only titles
        # \Q so that punctuation in the search is matched literally instead of
        # being compiled as a pattern
        @items = grep { $_->{title} =~ /\Q$find\E/i } @items;
    }
    foreach my $item (@items) {
        push(
            @{$display_data{data}},
            { title => $item->{title}, subtitle => _updated($item->{updated_time}), arg => $item->{id} }
        );
    }
}
elsif (exists $data->{error}) {
    $display_data{empty} = { title => 'Error', subtitle => Joplin::parse_error($data) };
}

Jundy::AlfredWorkflow::Filter::display(\%display_data);

# Results come back newest first, so the date is what tells two similarly named
# notes apart.  Joplin reports milliseconds since the epoch.
sub _updated {
    my $milliseconds = shift or return '';

    my @time = localtime($milliseconds / 1000);

    return sprintf('Updated %04d-%02d-%02d', $time[5] + 1900, $time[4] + 1, $time[3]);
}