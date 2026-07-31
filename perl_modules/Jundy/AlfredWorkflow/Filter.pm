package Jundy::AlfredWorkflow::Filter;

use JSON;

# Item keys that are handed straight to Alfred when the caller supplies them.
my @_optional_keys = qw(uid autocomplete icon variables mods quicklookurl text);

# display prints out what Alfred is expecting for the filtered list
# INPUT:
# {
#     empty => {
#         title => "Nothing to see here",
#         subtitle => "Try something else",
#     }
#     data => [
#         {
#             title => "Foo",
#             subtitle => "Bar",
#             arg => 1
#         },
#     ]
#     append => [ # always shown, after data or empty
#         {
#             title => "An update is available",
#             arg => "https://...",
#             valid => 1,
#             variables => { joplin_action => 'update' },
#         },
#     ]
# }
sub display {
    my $href = shift;

    my @items;
    if (@{$href->{data}}) {
        @items = map { _item($_) } @{$href->{data}};
    }
    else {
        @items = (_item($href->{empty}));
    }

    push(@items, map { _item($_) } @{ $href->{append} || [] });

    print encode_json({ items => \@items });
}

sub _item {
    my $href = shift || {};

    my %item = (
        title    => $href->{title}    // '',
        subtitle => $href->{subtitle} // '',
        arg      => $href->{arg}      // '',
    );

    foreach my $key (@_optional_keys) {
        $item{$key} = $href->{$key} if exists $href->{$key};
    }

    # valid has to reach Alfred as a JSON boolean, not as 0 or 1.
    $item{valid} = $href->{valid} ? \1 : \0 if exists $href->{valid};

    return \%item;
}

1;
