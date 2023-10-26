package Joplin;

use JSON;

# https://joplinapp.org/api/references/rest_api/

sub get_data {
    my $url_parts = shift || [];
    my $query_map = shift || {};

    $query_map->{token} = $ENV{JOPLIN_TOKEN};

    my $url = join("/", $ENV{JOPLIN_URL}, @$url_parts);
    if ($query_map) {
        $url .= '?';
        $url .= join("&", map { "$_=$query_map->{$_}"} keys %$query_map);
    }

    my $resp = `curl -s -q "$url"`;
    return decode_json($resp);
}

1;