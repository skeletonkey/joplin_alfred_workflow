package Joplin;

use strict;
use warnings;

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
        # Sorted so that the same request always produces the same URL, which
        # makes both debugging and testing possible.
        $url .= '?' . join('&',
            map { Jundy::AlfredWorkflow::HTTP::url_encode($_) . '=' . Jundy::AlfredWorkflow::HTTP::url_encode($query_map->{$_}) }
            sort keys %$query_map);
    }

    return $url;
}

# Both of these run curl directly rather than through a shell, so nothing a
# search term or a note title happens to contain can be read as shell syntax.
sub _curl {
    my $url  = shift;
    my $body = shift;

    return defined $body ? _post($url, $body) : _get($url);
}

sub _get {
    my $url = shift;

    open(my $reader, '-|', 'curl', '-s', '-q', $url) or return '';

    local $/;
    my $response = <$reader>;
    close($reader);

    return $response;
}

# Writing to curl as well as reading from it needs IPC::Open2.  Only note
# creation does that, so keep it off the search path, which runs on every
# keystroke.  Sending the body on stdin also keeps long notes off the command
# line.
sub _post {
    my $url  = shift;
    my $body = shift;

    require IPC::Open2;

    my ($reader, $writer);
    my $pid = eval {
        IPC::Open2::open2(
            $reader, $writer,
            'curl', '-X', 'POST', '-s', '-q', '-H', 'Content-Type: application/json', '--data-binary', '@-', $url
        )
    } or return '';

    print $writer $body;
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
