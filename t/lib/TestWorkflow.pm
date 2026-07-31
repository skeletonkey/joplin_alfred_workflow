package TestWorkflow;

# Everything a test needs to exercise the workflow without a network, a running
# Joplin or a real Alfred: a scratch directory, a curl that records instead of
# calling out, and the environment variables Alfred would otherwise set.

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

our $ROOT = abs_path(dirname(__FILE__) . '/../..');

sub new {
    my $class = shift;

    my $self = bless { dir => tempdir(CLEANUP => 1) }, $class;

    # Put the recording curl ahead of the real one for this process and every
    # script it starts.
    $ENV{PATH}          = "$ROOT/t/bin:$ENV{PATH}" unless $ENV{PATH} =~ /^\Q$ROOT\E\/t\/bin:/;
    $ENV{FAKE_CURL_DIR} = $self->{dir};
    delete $ENV{FAKE_CURL_RESPONSE};
    delete $ENV{FAKE_CURL_EXIT};

    $ENV{JOPLIN_URL}            = 'http://joplin.test:41184';
    $ENV{JOPLIN_TOKEN}          = 'test-token';
    $ENV{alfred_workflow_cache} = $self->{dir};
    $ENV{alfred_workflow_version} = '0.0.9';

    # Leave the update check switched off unless a test asks for it, so that
    # unrelated tests do not spawn a background check.
    $ENV{JOPLIN_UPDATE_CHECK} = '0';

    return $self;
}

sub dir { return $_[0]{dir} }

sub root { return $ROOT }

# respond sets what the next curl call prints.
sub respond {
    my ($self, $body, $exit) = @_;

    $ENV{FAKE_CURL_RESPONSE} = $body;
    $ENV{FAKE_CURL_EXIT}     = $exit if defined $exit;

    return $self;
}

sub calls {
    my $self = shift;

    my $n = 0;
    $n++ while -e $self->{dir} . '/call-' . ($n + 1) . '.args';

    return $n;
}

# args returns the argument list of the nth curl call, defaulting to the last.
sub args {
    my ($self, $n) = @_;
    $n ||= $self->calls;

    my $raw = _read($self->{dir} . "/call-$n.args");

    return defined $raw ? [split(/\n/, $raw, -1)] : undef;
}

# body returns the raw bytes the nth curl call was given on stdin.
sub body {
    my ($self, $n) = @_;
    $n ||= $self->calls;

    return _read($self->{dir} . "/call-$n.body");
}

# url picks the URL out of a recorded argument list.
sub url {
    my ($self, $n) = @_;

    my $args = $self->args($n) or return undef;
    my ($url) = grep { m{^https?://} } @$args;

    return $url;
}

# run executes one of the workflow scripts the way Alfred does - from the
# workflow directory, with the bundled modules on the include path - and
# returns its stdout.
sub run {
    my ($self, $script, @argv) = @_;

    # Exactly as Alfred does it: no switches of our own, so that perl honours
    # the -I and -s on the script's #! line.  Passing -I here would silently
    # stop -s working and leave the script name in @ARGV.
    my @command = ($^X, $script, @argv);

    my $pid = open(my $out, '-|');
    die "cannot fork: $!\n" unless defined $pid;

    unless ($pid) {
        chdir($ROOT) or die "cannot chdir to $ROOT: $!\n";
        open(STDERR, '>&', \*STDOUT);
        exec(@command) or die "cannot run $script: $!\n";
    }

    local $/;
    my $stdout = <$out>;
    close($out);

    return defined $stdout ? $stdout : '';
}

sub _read {
    my $path = shift;
    return undef unless -e $path;

    open(my $fh, '<', $path) or return undef;
    binmode($fh);
    local $/;
    my $content = <$fh>;
    close($fh);

    return $content;
}

1;
