package Jundy::AlfredWorkflow::Update;

use strict;
use warnings;

use File::Path qw(make_path);

use JSON;

# Self updating, modelled on the mechanism documented at
# https://alfred-workflow.readthedocs.io/en/latest/user-manual/update.html
#
# Ask the GitHub releases API for the newest release that carries exactly one
# .alfredworkflow asset, cache the answer, and hand that asset to Alfred with
# `open` when the user asks for it.  Everything here relies on curl and Perl 5
# only, so nothing extra has to be installed.

use constant GITHUB_SLUG       => 'skeletonkey/joplin_alfred_workflow';
use constant CACHE_FILE        => 'update_check.json';
use constant DEFAULT_FREQUENCY => 1;      # days between checks
use constant DEFAULT_BUNDLE_ID => 'com.github.skeletonkey.joplin_alfred_workflow';
use constant API_TIMEOUT       => 20;     # seconds
use constant DOWNLOAD_TIMEOUT  => 120;    # seconds

# Only these hosts are ever handed to curl for the download itself.
use constant TRUSTED_HOST => qr{^https://(?:[\w.-]+\.)?github(?:usercontent)?\.com/};

# current_version returns the version of the installed workflow.  Alfred
# exports it; the info.plist fallback is for running the scripts by hand.
sub current_version {
    return $ENV{alfred_workflow_version} if $ENV{alfred_workflow_version};

    open(my $fh, '<', 'info.plist') or return '';
    local $/;
    my $plist = <$fh>;
    close($fh);

    return $plist =~ m{<key>version</key>\s*<string>([^<]*)</string>} ? $1 : '';
}

# enabled reports whether the user left the automatic check turned on.
sub enabled {
    my $setting = $ENV{JOPLIN_UPDATE_CHECK};
    return 1 unless defined $setting && length $setting;
    return $setting =~ /^(?:0|false|no|off)$/i ? 0 : 1;
}

# frequency is the number of days to wait between automatic checks.
sub frequency {
    my $days = $ENV{JOPLIN_UPDATE_FREQUENCY};
    return DEFAULT_FREQUENCY unless defined $days && $days =~ /^\d+(?:\.\d+)?$/ && $days > 0;
    return $days;
}

# compare_versions returns -1, 0 or 1 the same way <=> does.
sub compare_versions {
    my @left  = split(/\./, _normalize_version(shift));
    my @right = split(/\./, _normalize_version(shift));

    while (@left || @right) {
        my $l = shift(@left)  || 0;
        my $r = shift(@right) || 0;
        return $l <=> $r if $l != $r;
    }

    return 0;
}

# available returns { version, url } when the cache knows about a release that
# is newer than the installed one, and undef otherwise.
sub available {
    my $cache = _read_cache();
    return undef unless defined $cache->{version} && defined $cache->{url};

    my $current = current_version();
    return undef unless length $current;

    return compare_versions($cache->{version}, $current) > 0
        ? { version => $cache->{version}, url => $cache->{url} }
        : undef;
}

# notice_item is the Alfred item to append to a script filter when an update is
# waiting.  It returns an empty list when there is nothing to offer.
sub notice_item {
    my $update = available() or return ();

    return {
        title     => "Joplin Workflow $update->{version} is available",
        subtitle  => 'Select to download and install the update',
        arg       => $update->{url},
        variables => { joplin_action => 'update' },
    };
}

# check_in_background kicks off a check without making the caller wait for it.
# Script filters run on every keystroke, so this has to be cheap and has to
# refuse to pile up processes.
sub check_in_background {
    return 0 unless enabled();

    my $cache = _read_cache();
    return 0 if time() - ($cache->{checked} || 0) < frequency() * 86_400;

    # Stamp the attempt before spawning so the next keystroke sees a fresh
    # cache and stays quiet while this check is still in flight.
    $cache->{checked} = time();
    _write_cache($cache);

    system('nohup ' . _shell_quote($^X) . ' -I perl_modules update.pl -refresh >/dev/null 2>&1 &');

    return 1;
}

# refresh talks to GitHub and rewrites the cache.  It returns
# ({ version, url }, '') on success and (undef, $message) on failure.
sub refresh {
    my ($latest, $error) = _fetch_latest();

    my %cache = (checked => time());
    if ($latest) {
        @cache{qw(version url)} = @{$latest}{qw(version url)};
    }
    else {
        # A transient failure should not hide an update we already know about.
        my $previous = _read_cache();
        $cache{$_} = $previous->{$_} for grep { defined $previous->{$_} } qw(version url);
        $cache{error} = $error;
    }
    _write_cache(\%cache);

    return ($latest, $error);
}

# install downloads the .alfredworkflow and lets Alfred take over.  Alfred owns
# the actual import, which is what keeps the user's configuration intact.
sub install {
    my $url = shift;

    unless (defined $url && length $url) {
        $url = _read_cache()->{url};
    }
    return (0, 'There is no update to install') unless defined $url && length $url;
    return (0, 'Refusing to download from an unexpected host') unless $url =~ TRUSTED_HOST;

    my $target = _cache_dir() . '/joplin-update.alfredworkflow';
    unlink($target);

    my $download = sprintf(
        'curl -fsSL --max-time %d -o %s %s 2>/dev/null',
        DOWNLOAD_TIMEOUT, _shell_quote($target), _shell_quote($url),
    );
    return (0, 'Download failed') if system($download) != 0 || !-s $target;

    return (0, 'Alfred would not open the download') if system('open', $target) != 0;

    return (1, 'Alfred is installing the update');
}

sub _normalize_version {
    my $version = shift // '';
    $version =~ s/^\s*v//i;
    $version =~ s/\s+$//;
    return $version;
}

sub _fetch_latest {
    my $command = sprintf(
        'curl -sSL --max-time %d -H %s -H %s %s 2>/dev/null',
        API_TIMEOUT,
        _shell_quote('Accept: application/vnd.github+json'),
        _shell_quote('User-Agent: joplin_alfred_workflow'),
        _shell_quote('https://api.github.com/repos/' . GITHUB_SLUG . '/releases?per_page=50'),
    );

    my $raw = `$command`;
    return (undef, 'Could not reach GitHub') unless defined $raw && length $raw;

    my $releases = eval { decode_json($raw) };

    # The API answers with an object rather than a list for errors such as
    # having run out of unauthenticated requests.
    return (undef, 'Unexpected response from GitHub') unless ref($releases) eq 'ARRAY';

    my $best;
    foreach my $release (@$releases) {
        next if $release->{draft} || $release->{prerelease};

        my $version = _normalize_version($release->{tag_name});
        next unless $version =~ /^\d+(?:\.\d+)*$/;

        # Exactly one asset, otherwise there is no way to know what to install.
        my @assets = grep { ($_->{name} // '') =~ /\.alfredworkflow$/ } @{ $release->{assets} || [] };
        next unless @assets == 1 && $assets[0]{browser_download_url};

        next if $best && compare_versions($version, $best->{version}) <= 0;
        $best = { version => $version, url => $assets[0]{browser_download_url} };
    }

    return $best ? ($best, '') : (undef, 'No installable release found');
}

sub _cache_dir {
    my $dir = $ENV{alfred_workflow_cache};
    unless (defined $dir && length $dir) {
        my $bundle_id = $ENV{alfred_workflow_bundleid} || DEFAULT_BUNDLE_ID;
        $dir = "$ENV{HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/$bundle_id";
    }

    eval { make_path($dir) } unless -d $dir;

    return $dir;
}

sub _cache_file {
    return _cache_dir() . '/' . CACHE_FILE;
}

sub _read_cache {
    my $file = _cache_file();
    return {} unless -f $file;

    open(my $fh, '<', $file) or return {};
    local $/;
    my $raw = <$fh>;
    close($fh);

    my $cache = eval { decode_json($raw) };

    return ref($cache) eq 'HASH' ? $cache : {};
}

sub _write_cache {
    my $cache = shift;

    my $file = _cache_file();
    my $temp = "$file.$$";

    open(my $fh, '>', $temp) or return 0;
    print $fh encode_json($cache);
    close($fh) or return 0;

    # Rename so a reader never sees a half written cache.
    return rename($temp, $file) ? 1 : (unlink($temp) && 0);
}

sub _shell_quote {
    my $value = shift // '';
    $value =~ s/'/'\\''/g;
    return "'$value'";
}

1;
