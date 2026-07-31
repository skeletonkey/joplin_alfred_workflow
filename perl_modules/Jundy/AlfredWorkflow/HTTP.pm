package Jundy::AlfredWorkflow::HTTP;

use strict;
use warnings;

# url_encode percent encodes everything outside RFC 3986's unreserved set.
# Encoding by exception rather than from a table of known characters means new
# punctuation - and anything non-ASCII - cannot slip through unencoded.
#
# The argument is a string of characters, not of bytes; callers decode what
# they read from Alfred before they get here.
sub url_encode {
    my $value = shift;
    return '' unless defined $value;

    # Percent encoding is defined over bytes, so characters have to be run
    # through UTF-8 first.  This is unconditional on purpose: perl stores a
    # string whose characters all fit in a byte without the UTF-8 flag set, so
    # asking whether the flag is on would miss "café" and encode it as a
    # single latin-1 byte.
    utf8::encode($value);

    $value =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;

    return $value;
}

1;
