package Jundy::AlfredWorkflow::Filter;

use JSON;

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
# }
sub display {
    my $href = shift;

    my @items;
    if (@{$href->{data}}) {
        @items = map {
            {
                title    => $_->{title}    // '',
                subtitle => $_->{subtitle} // '',
                arg      => $_->{arg}      // '',
            }
        } @{$href->{data}};
    }
    else {
        @items = ({
            title    => $href->{empty}{title}    // '',
            subtitle => $href->{empty}{subtitle} // '',
            arg      => $href->{empty}{arg}      // '',
        });
    }

    print encode_json({ items => \@items });
}

1;