#!/usr/bin/perl

# Filter::display produces the JSON Alfred reads.  Alfred shows nothing at all
# if the shape is wrong, so the structure is checked rather than the text.

use strict;
use warnings;

use Test::More;

use JSON;
use Jundy::AlfredWorkflow::Filter;

sub display {
    my $output = '';

    do {
        local *STDOUT;
        open(STDOUT, '>', \$output) or die $!;
        Jundy::AlfredWorkflow::Filter::display(@_);
        close(STDOUT);
    };

    return decode_json($output);
}

my $result = display({ data => [ { title => 'One', subtitle => 'first', arg => '1' } ] });
is(scalar(@{ $result->{items} }), 1, 'one result gives one item');
is($result->{items}[0]{title}, 'One', 'title is carried through');
is($result->{items}[0]{subtitle}, 'first', 'subtitle is carried through');
is($result->{items}[0]{arg}, '1', 'arg is carried through');

$result = display({ data => [], empty => { title => 'Nothing', subtitle => 'try again' } });
is(scalar(@{ $result->{items} }), 1, 'no results falls back to the empty item');
is($result->{items}[0]{title}, 'Nothing', 'the empty item is used');

$result = display({ data => [ { title => 'One' } ] });
is($result->{items}[0]{subtitle}, '', 'a missing subtitle becomes an empty string');
is($result->{items}[0]{arg}, '', 'a missing arg becomes an empty string');

# append is how the update notice reaches the user, and it has to survive both
# the populated and the empty case.
$result = display({
    data   => [ { title => 'One' } ],
    append => [ { title => 'Update' } ],
});
is(scalar(@{ $result->{items} }), 2, 'appended items are added to results');
is($result->{items}[-1]{title}, 'Update', 'the appended item comes last so it cannot steal the selection');

$result = display({
    data   => [],
    empty  => { title => 'Nothing' },
    append => [ { title => 'Update' } ],
});
is(scalar(@{ $result->{items} }), 2, 'appended items survive the empty case');
is($result->{items}[0]{title}, 'Nothing', 'the empty item still comes first');

# Alfred needs real JSON booleans and a nested object here, not strings.
$result = display({ data => [ { title => 'One', valid => 0, variables => { joplin_action => 'update' } } ] });
ok(JSON::is_bool($result->{items}[0]{valid}), 'valid is a real JSON boolean, not a string of digits');
ok(!$result->{items}[0]{valid}, 'valid => 0 reaches Alfred as false');
is_deeply($result->{items}[0]{variables}, { joplin_action => 'update' }, 'per item variables are passed through');

$result = display({ data => [ { title => 'One', valid => 1 } ] });
ok($result->{items}[0]{valid}, 'valid => 1 reaches Alfred as true');

done_testing();
