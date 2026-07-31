#!/usr/bin/perl

# url_encode is the guard that stops a search term being read as shell syntax
# or breaking the query string, so it is tested character by character rather
# than by example.

use strict;
use warnings;

use Test::More;

use Jundy::AlfredWorkflow::HTTP;

sub encode { return Jundy::AlfredWorkflow::HTTP::url_encode(@_) }

is(encode('plain'), 'plain', 'unreserved characters are left alone');
is(encode('a-b_c.d~e'), 'a-b_c.d~e', 'the whole unreserved set survives');

# Every character outside the unreserved set has to come back percent encoded,
# as UTF-8.  Walking the whole range catches anything a hand written table
# would miss - which is how the backtick got through in the first place.
my @wrong;
foreach my $code (0 .. 255, 0x2014, 0x2615) {
    my $char = chr($code);

    my $expected;
    if ($char =~ /^[A-Za-z0-9\-._~]$/) {
        $expected = $char;
    }
    else {
        my $bytes = $char;
        utf8::encode($bytes);
        $expected = join('', map { sprintf('%%%02X', ord($_)) } split(//, $bytes));
    }

    my $got = encode($char);
    push(@wrong, sprintf('U+%04X got %s wanted %s', $code, $got, $expected)) if $got ne $expected;
}
is_deeply(\@wrong, [], 'every character encodes to its UTF-8 percent encoding')
    or diag(join("\n", @wrong));

# The property that actually matters: nothing a shell or a URL parser could act
# on ever survives.
my $everything = join('', map { chr } 0 .. 255);
like(encode($everything), qr/^[A-Za-z0-9\-._~%]*$/, 'output only ever contains safe characters');

# The characters that actually caused trouble, called out so a regression is
# obvious from the test name.
is(encode('`'),  '%60', 'backtick is encoded - it used to reach the shell');
is(encode('$'),  '%24', 'dollar is encoded');
is(encode('\\'), '%5C', 'backslash is encoded');
is(encode('"'),  '%22', 'double quote is encoded');
is(encode("'"),  '%27', 'single quote is encoded');
is(encode('&'),  '%26', 'ampersand is encoded so it cannot add a parameter');

is(encode('`id`'), '%60id%60', 'a command substitution is inert once encoded');

# url_encode takes characters and emits UTF-8 percent encoding.  perl keeps a
# string like this one downgraded, with no UTF-8 flag, which is exactly the
# case that used to come out as a single latin-1 byte.
is(encode("caf\x{e9}"), 'caf%C3%A9', 'an accented character encodes as UTF-8, not latin-1');
is(encode("\x{2014}"), '%E2%80%94', 'an em dash encodes as three bytes');
is(encode("\x{2615}"), '%E2%98%95', 'an emoji outside the basic plane encodes correctly');

my $upgraded = "caf\x{e9}\x{2014}";
is(encode($upgraded), 'caf%C3%A9%E2%80%94', 'a string perl does hold as UTF-8 encodes the same way');

done_testing();
