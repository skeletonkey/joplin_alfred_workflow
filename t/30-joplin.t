#!/usr/bin/perl

# The Joplin transport.  These tests care about exactly what is handed to curl,
# because that is where a search term stops being data and could start being
# shell syntax.

use strict;
use warnings;

use Test::More;

use JSON;
use TestWorkflow;
use Joplin;

my $t = TestWorkflow->new;

# --- URL building ---------------------------------------------------------
$t->respond('{"items":[]}');
Joplin::get_data(['search'], { query => 'notes', fields => 'id,title' });

is($t->calls, 1, 'one request is made');
is(
    $t->url,
    'http://joplin.test:41184/search?fields=id%2Ctitle&query=notes&token=test-token',
    'path, sorted query parameters and token are assembled correctly'
);

my $args = $t->args;
ok(!(grep { $_ eq '-X' } @$args), 'a read is not sent as a POST');

# --- shell safety ---------------------------------------------------------
$t = TestWorkflow->new;
$t->respond('{"items":[]}');
Joplin::get_data(['search'], { query => '`id`' });

like($t->url, qr/query=%60id%60/, 'a backtick reaches curl percent encoded');
unlike($t->url, qr/`/, 'no raw backtick is present in the URL');

$t = TestWorkflow->new;
$t->respond('{"items":[]}');
Joplin::get_data(['search'], { query => 'a"b$HOME;rm -rf /' });
my $url = $t->url;
unlike($url, qr/["\$;]/, 'quote, dollar and semicolon are all encoded');
like($url, qr/%22.*%24HOME%3Brm/, 'the whole term survives as data');

# curl is handed the URL as one argument, so no amount of quoting in the term
# can split it into something else.
$t = TestWorkflow->new;
$t->respond('{"items":[]}');
Joplin::get_data(['search'], { query => 'one two' });
is(scalar(grep { m{^https?://} } @{ $t->args }), 1, 'the URL is a single argument');

# --- POST bodies ----------------------------------------------------------
$t = TestWorkflow->new;
$t->respond('{"id":"new-note"}');
my $created = Joplin::post_data(['notes'], {}, { title => "Jerry Cline's Bread", body => '', parent_id => 'abc' });

is($created->{id}, 'new-note', 'the created note is returned');
$args = $t->args;
ok((grep { $_ eq '-X' } @$args), 'a write is sent as a POST');
ok((grep { $_ eq '@-' } @$args), 'the body is sent on stdin, not on the command line');
ok(!(grep { /Jerry Cline/ } @$args), 'the title never appears in the argument list');

my $sent = decode_json($t->body);
is($sent->{title}, "Jerry Cline's Bread", 'an apostrophe in the title survives intact');
is($sent->{parent_id}, 'abc', 'the parent folder is sent');

# The body has to be valid UTF-8 on the wire, not doubly encoded.
$t = TestWorkflow->new;
$t->respond('{"id":"new-note"}');
Joplin::post_data(['notes'], {}, { title => "caf\x{e9} \x{2615}", body => '', parent_id => 'x' });

my $raw = $t->body;
like($raw, qr/caf\xc3\xa9/, 'an accented character is sent as correct UTF-8');
unlike($raw, qr/\xc3\x83\xc2\xa9/, 'the accent is not doubly encoded');
like($raw, qr/\xe2\x98\x95/, 'an emoji is sent as correct UTF-8');

# --- responses ------------------------------------------------------------
$t = TestWorkflow->new;
$t->respond('');
my $empty = Joplin::get_data(['folders']);
like($empty->{error}, qr/make sure Joplin is running/, 'no response is reported as Joplin being down');

$t = TestWorkflow->new;
$t->respond('<html>not json</html>');
my $garbage = Joplin::get_data(['folders']);
like($garbage->{error}, qr/something unexpected/, 'a non JSON response is reported rather than fatal');

$t = TestWorkflow->new;
$t->respond('{"error":"Invalid \'token\' parameter\nstack trace here"}');
my $failed = Joplin::get_data(['folders']);
is(Joplin::parse_error($failed), "Invalid 'token' parameter", 'only the first line of an error is shown');

$t = TestWorkflow->new;
$t->respond('{"error":"He said \"no\"\nmore"}');
unlike(Joplin::parse_error(Joplin::get_data(['folders'])), qr/"/, 'double quotes are removed from error text');

done_testing();
