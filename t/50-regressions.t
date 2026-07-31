#!/usr/bin/perl

# One test per bug that shipped, driven through the real scripts the way Alfred
# runs them.  These are the failures the self update would otherwise propagate
# to everyone within a day, so each one names the symptom it guards against.

use strict;
use warnings;

use Test::More;

use JSON;
use TestWorkflow;

my $t = TestWorkflow->new;

my $NOTES = encode_json({
    items => [
        { id => 'n1', title => 'Go Guild — 5-Minute Launch Talk', updated_time => 1_700_000_000_000 },
        { id => 'n2', title => "Jerry Cline's Bread",             updated_time => 1_600_000_000_000 },
        { id => 'n3', title => 'Plain Note',                      updated_time => 1_500_000_000_000 },
    ],
});

sub items {
    my $json = shift;
    my $data = eval { decode_json($json) };

    return $data ? $data->{items} : undef;
}

# --- a backtick in a search used to be executed by the shell ---------------
$t->respond($NOTES);
my $out = $t->run('search_notes.pl', 'a`id`b');
ok(items($out), 'a search containing a backtick still returns valid JSON') or diag($out);
like($t->url, qr/%60id%60/, 'the backtick is percent encoded on its way to curl');
unlike($t->url, qr/`/, 'no raw backtick reaches curl');
unlike($out, qr/uid=\d+/, 'the command was not run');

# --- punctuation used to be compiled as a regex ----------------------------
foreach my $term ('foo(', 'a[', '*', 'x{2,') {
    $t = TestWorkflow->new;
    $t->respond($NOTES);
    my $result = $t->run('search_notes.pl', '-t', $term);
    ok(items($result), "title search for '$term' does not die on a regex metacharacter")
        or diag($result);
}

# --- the title filter has to still actually filter -------------------------
$t = TestWorkflow->new;
$t->respond($NOTES);
my $filtered = items($t->run('search_notes.pl', '-t', 'Guild'));
is(scalar(@$filtered), 1, 'title search narrows the results');
is($filtered->[0]{title}, 'Go Guild — 5-Minute Launch Talk', 'and keeps the right one');

# --- a non ASCII search used to fail outright ------------------------------
$t = TestWorkflow->new;
$t->respond($NOTES);
$filtered = items($t->run('search_notes.pl', '-t', 'Guild —'));
is(scalar(@$filtered), 1, 'a title search containing an em dash matches');
like($t->url, qr/%E2%80%94/, 'the em dash is sent as percent encoded UTF-8');

# --- the subtitle used to always be empty ----------------------------------
$t = TestWorkflow->new;
$t->respond($NOTES);
my $all = items($t->run('search_notes.pl', 'anything'));
like($all->[0]{subtitle}, qr/^Updated \d{4}-\d{2}-\d{2}$/, 'results carry the date instead of an empty subtitle');

# --- an apostrophe in a new note title used to break the shell -------------
$t = TestWorkflow->new;
$t->respond('{"id":"created"}');
my $created = $t->run('create_note.pl', 'folder-1', "Jerry Cline's café ☕");
is($created, 'created', 'the note is created and its id returned');

my $body = decode_json($t->body);
is($body->{title}, "Jerry Cline's caf\x{e9} \x{2615}", 'the title arrives intact, accent and all');
is($body->{parent_id}, 'folder-1', 'the folder is passed through');
like($t->body, qr/caf\xc3\xa9/, 'and is correct UTF-8 on the wire');

# --- folder filtering ------------------------------------------------------
my $FOLDERS = encode_json({
    items => [
        { id => 'f1', title => 'Recipes (new)', parent_id => '' },
        { id => 'f2', title => 'Work',          parent_id => '' },
    ],
});

$t = TestWorkflow->new;
$t->respond($FOLDERS);
ok(items($t->run('find_folder.pl', '(')), 'folder search survives a regex metacharacter');

$t = TestWorkflow->new;
$t->respond($FOLDERS);
my $folders = items($t->run('find_folder.pl', 'Recipes'));
is(scalar(@$folders), 1, 'folder search narrows the results');
is($folders->[0]{arg}, 'f1', 'and returns the folder id');

done_testing();
