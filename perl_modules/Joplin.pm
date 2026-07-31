package Joplin;

use strict;
use warnings;

use IPC::Open2;

use JSON;

use Jundy::AlfredWorkflow::HTTP;

# https://joplinapp.org/help/api/references/rest_api#using-the-api

sub get_data {
    my $url_parts = shift || [];
    my $query_map = shift || {};

    $query_map->{token} = $ENV{JOPLIN_TOKEN};

    return _response(_curl(_url($url_parts, $query_map)));
}

sub post_data {
    my $url_parts = shift || [];
    my $query_map = shift || {};
    my $body_map  = shift || {};

    $query_map->{token} = $ENV{JOPLIN_TOKEN};

    return _response(_curl(_url($url_parts, $query_map), encode_json($body_map)));
}

sub parse_error {
    my $data = shift || warn("parse_error called without data\n");

    warn("no error element found in data\n") unless exists $data->{error};

    my @lines = split(/\n/, $data->{error});
    $lines[0] =~ s/"/'/g;

    return $lines[0];
}

sub _url {
    my $url_parts = shift;
    my $query_map = shift;

    my $url = join('/', $ENV{JOPLIN_URL} // '', @$url_parts);

    if (%$query_map) {
        $url .= '?' . join('&',
            map { Jundy::AlfredWorkflow::HTTP::url_encode($_) . '=' . Jundy::AlfredWorkflow::HTTP::url_encode($query_map->{$_}) }
            keys %$query_map);
    }

    return $url;
}

# _curl runs curl directly rather than through a shell, so nothing a search
# term or a note title happens to contain can be read as shell syntax.  A body
# is sent on stdin, which also keeps long notes off the command line.
sub _curl {
    my $url  = shift;
    my $body = shift;

    my @command = ('curl', '-s', '-q', $url);
    if (defined $body) {
        splice(@command, 1, 0, '-X', 'POST', '-H', 'Content-Type: application/json', '--data-binary', '@-');
    }

    my ($reader, $writer);
    my $pid = eval { open2($reader, $writer, @command) } or return '';

    print $writer $body if defined $body;
    close($writer);

    local $/;
    my $response = <$reader>;
    close($reader);
    waitpid($pid, 0);

    return $response;
}

sub _response {
    my $resp = shift || return { data => [], error => "No response from Joplin - make sure Joplin is running" };

    my $data = eval { decode_json($resp) };

    return ref($data) eq 'HASH' ? $data : { data => [], error => "Joplin sent back something unexpected" };
}

1;
