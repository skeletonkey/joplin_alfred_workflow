package Jundy::AlfredWorkflow::HTTP;

use strict;
use warnings;

# url_encode percent encodes everything outside RFC 3986's unreserved set.
# Encoding by exception rather than from a table of known characters means new
# punctuation - and anything non-ASCII - cannot slip through unencoded.
sub url_encode {
    my $value = shift;
    return '' unless defined $value;

    # Percent encoding is defined over bytes, so a decoded string has to be run
    # back through UTF-8 first.
    utf8::encode($value) if utf8::is_utf8($value);

    $value =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;

    return $value;
}

1;
