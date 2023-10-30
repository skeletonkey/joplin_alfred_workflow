package Joplin;

use JSON;

use Jundy::AlfredWorkflow::HTTP;

# https://joplinapp.org/help/api/references/rest_api#using-the-api

sub get_data {
    my $url_parts = shift || [];
    my $query_map = shift || {};

    $query_map->{token} = $ENV{JOPLIN_TOKEN};
    $query_map->{fields} = 'id,title';
    $query_map->{limit} = 9;
    $query_map->{order_by} = "updated_time";

    my $url = join("/", $ENV{JOPLIN_URL}, @$url_parts);
    if ($query_map) {
        $url .= '?';
        $url .= join("&", map { "$_=" . Jundy::AlfredWorkflow::HTTP::url_encode($query_map->{$_})} keys %$query_map);
    }

    my $resp = `curl -s -q "$url"`;
    return decode_json($resp);
}

1;