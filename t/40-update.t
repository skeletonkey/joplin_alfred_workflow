#!/usr/bin/perl

# The self update logic.  This decides what gets installed over the copy the
# user is running, so the release picking and the download guard matter more
# here than anywhere else in the workflow.

use strict;
use warnings;

use Test::More;

use JSON;
use TestWorkflow;
use Jundy::AlfredWorkflow::Update;

my $U = 'Jundy::AlfredWorkflow::Update';

# --- version comparison ---------------------------------------------------
is($U->can('compare_versions')->('0.0.9', '0.0.10'), -1, '9 sorts before 10, not after');
is($U->can('compare_versions')->('0.0.10', '0.0.9'), 1, 'and the other way round');
is($U->can('compare_versions')->('0.0.8', '0.0.8'), 0, 'equal versions compare equal');
is($U->can('compare_versions')->('1.0', '1.0.0'), 0, 'a missing segment counts as zero');
is($U->can('compare_versions')->('1.0.0', '0.99.99'), 1, 'a major bump wins');
is($U->can('compare_versions')->('v0.1.0', '0.0.99'), 1, 'a v prefix is ignored');
is($U->can('compare_versions')->('2', '1.9.9'), 1, 'a bare major version still compares');

# --- release selection ----------------------------------------------------
my $asset = sub {
    my ($version, @names) = @_;
    return {
        tag_name   => "v$version",
        draft      => JSON::false,
        prerelease => JSON::false,
        assets     => [ map { { name => $_, browser_download_url => "https://github.com/o/r/$version/$_" } } @names ],
    };
};

sub latest_from {
    my $releases = shift;

    my $t = TestWorkflow->new;
    $t->respond(encode_json($releases));

    my ($found, $error) = $U->can('refresh')->();

    return ($found, $error, $t);
}

my ($found) = latest_from([ $asset->('0.0.8', 'joplin.alfredworkflow'), $asset->('0.1.0', 'joplin.alfredworkflow') ]);
is($found->{version}, '0.1.0', 'the newest release is chosen regardless of list order');
like($found->{url}, qr{^https://github\.com/}, 'the download URL comes from the asset');

($found) = latest_from([ $asset->('0.2.0', 'joplin.alfredworkflow'), $asset->('0.1.0', 'joplin.alfredworkflow') ]);
is($found->{version}, '0.2.0', 'ordering the other way gives the same answer');

my $pre = $asset->('0.3.0', 'joplin.alfredworkflow');
$pre->{prerelease} = JSON::true;
($found) = latest_from([ $pre, $asset->('0.1.0', 'joplin.alfredworkflow') ]);
is($found->{version}, '0.1.0', 'a prerelease is skipped');

my $draft = $asset->('0.3.0', 'joplin.alfredworkflow');
$draft->{draft} = JSON::true;
($found) = latest_from([ $draft, $asset->('0.1.0', 'joplin.alfredworkflow') ]);
is($found->{version}, '0.1.0', 'a draft is skipped');

# Two assets means there is no way to know which one to install.
($found) = latest_from([ $asset->('0.3.0', 'a.alfredworkflow', 'b.alfredworkflow'), $asset->('0.1.0', 'joplin.alfredworkflow') ]);
is($found->{version}, '0.1.0', 'a release with two workflow assets is skipped');

($found) = latest_from([ $asset->('0.3.0', 'notes.txt'), $asset->('0.1.0', 'joplin.alfredworkflow') ]);
is($found->{version}, '0.1.0', 'a release with no workflow asset is skipped');

my $named = $asset->('0.3.0', 'sidecar.zip', 'joplin.alfredworkflow');
($found) = latest_from([$named]);
is($found->{version}, '0.3.0', 'an unrelated extra asset does not disqualify a release');

my $odd = $asset->('not-a-version', 'joplin.alfredworkflow');
my ($none, $error) = latest_from([$odd]);
is($none, undef, 'a tag that is not a version is ignored');
like($error, qr/No installable release/, 'and that is reported');

# --- API failures ---------------------------------------------------------
my $t = TestWorkflow->new;
$t->respond('{"message":"API rate limit exceeded"}');
(my $limited, $error) = $U->can('refresh')->();
is($limited, undef, 'a rate limit reply is not mistaken for a release list');
like($error, qr/Unexpected response/, 'the failure is described');

$t = TestWorkflow->new;
$t->respond('');
($limited, $error) = $U->can('refresh')->();
like($error, qr/Could not reach GitHub/, 'an empty reply is reported as unreachable');

# A failed check must not erase an update we already knew about.
$t = TestWorkflow->new;
$t->respond(encode_json([ $asset->('9.9.9', 'joplin.alfredworkflow') ]));
$U->can('refresh')->();
$t->respond('');
$U->can('refresh')->();
my $still = $U->can('available')->();
is($still->{version}, '9.9.9', 'a transient failure does not hide a pending update');

# --- available ------------------------------------------------------------
$t = TestWorkflow->new;
$t->respond(encode_json([ $asset->('9.9.9', 'joplin.alfredworkflow') ]));
$U->can('refresh')->();
ok($U->can('available')->(), 'a newer release is offered');

$ENV{alfred_workflow_version} = '9.9.9';
is($U->can('available')->(), undef, 'the release you are running is not offered');

$ENV{alfred_workflow_version} = '10.0.0';
is($U->can('available')->(), undef, 'an older release is not offered');
$ENV{alfred_workflow_version} = '0.0.9';

my $item = $U->can('notice_item')->();
is($item->{variables}{joplin_action}, 'update', 'the notice carries the variable that routes it to the installer');
like($item->{title}, qr/9\.9\.9/, 'the notice names the new version');

# --- the download guard ---------------------------------------------------
foreach my $bad (
    'http://github.com/o/r/x.alfredworkflow',
    'https://example.com/x.alfredworkflow',
    'https://github.com.evil.test/x.alfredworkflow',
) {
    my ($ok, $message) = $U->can('install')->($bad);
    ok(!$ok, "refuses to download from $bad") or diag($message);
}

# --- update.pl dispatch ----------------------------------------------------
# The background check runs "perl update.pl -refresh".  Perl only honours the
# -s on the #! line when it is started without switches of its own, so getting
# this wrong silently sends the refresh down the script filter branch instead.
$t = TestWorkflow->new;
$t->respond(encode_json([ $asset->('9.9.9', 'joplin.alfredworkflow') ]));
my $refresh_output = $t->run('update.pl', '-refresh');
is($refresh_output, '', '-refresh prints nothing, so it took the refresh branch');
is($U->can('available')->()->{version}, '9.9.9', 'and it wrote the cache');

$t = TestWorkflow->new;
$t->respond(encode_json([ $asset->('9.9.9', 'joplin.alfredworkflow') ]));
my $filter = decode_json($t->run('update.pl'));
is(scalar(@{ $filter->{items} }), 1, 'with no switch update.pl behaves as a script filter');
like($filter->{items}[0]{title}, qr/9\.9\.9/, 'and offers the new version');
is($filter->{items}[0]{variables}{joplin_action}, 'update', 'routed to the installer');

$t = TestWorkflow->new;
$t->respond('');
my $installed = $t->run('update.pl', '-install', 'https://example.com/x.alfredworkflow');
like($installed, qr/unexpected host/, '-install is recognised as a switch and refuses a bad host');

# --- settings -------------------------------------------------------------
$ENV{JOPLIN_UPDATE_CHECK} = '0';
is($U->can('enabled')->(), 0, 'the check can be switched off');
delete $ENV{JOPLIN_UPDATE_CHECK};
is($U->can('enabled')->(), 1, 'the check is on when nothing is configured');

$ENV{JOPLIN_UPDATE_FREQUENCY} = '7';
is($U->can('frequency')->(), 7, 'a configured frequency is used');
$ENV{JOPLIN_UPDATE_FREQUENCY} = 'soon';
is($U->can('frequency')->(), 1, 'nonsense falls back to the default');
delete $ENV{JOPLIN_UPDATE_FREQUENCY};

done_testing();
