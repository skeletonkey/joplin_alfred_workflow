package Jundy::AlfredWorkflow::HTTP;

my %_url_translation = (
    ' ' => '%20',
    '!' => '%21',
    '"' => '%22',
    '#' => '%23',
    '$' => '%24',
    '%' => '%25',
    '&' => '%26',
    "'" => '%27',
    '(' => '%28',
    ')' => '%29',
    '*' => '%2A',
    '+' => '%2B',
    ',' => '%2C',
    '/' => '%2F',
    ':' => '%3A',
    ';' => '%3B',
    '=' => '%3D',
    '?' => '%3F',
    '@' => '%40',
    '[' => '%5B',
    ']' => '%5D',
);
sub url_encode {
    return join("",
        map({
            if (exists $_url_translation{$_}) {
                $_url_translation{$_};
            } else {
                $_;
            }
        } split(//, $_[0]))
    )
}

1;