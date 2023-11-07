package Jundy::AlfredWorkflow::Filter;

my $_filter_tmpl = '"title":"%s","subtitle":"%s","arg":"%s"';

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

    if (@{$href->{data}}) {
        print '{"items":[{' . join('},{', map({ sprintf($_filter_tmpl, $_->{"title"},$_->{"subtitle"},$_->{"arg"} || "") } @{$href->{data}})) . '}]}';
    }
    else {
        print '{"items":[{' . sprintf($_filter_tmpl, $href->{empty}{"title"},$href->{empty}{"subtitle"},$href->{empty}{"arg"} || "") . '}]}';
    }
}

1;