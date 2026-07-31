#!/usr/bin/perl -I perl_modules -s

use strict;
use warnings;
use vars qw($refresh $install);

use Jundy::AlfredWorkflow::Filter;
use Jundy::AlfredWorkflow::Update;

$refresh ||= 0;    # ask GitHub and update the cache; used by the background check
$install ||= 0;    # download and hand the release to Alfred

if ($refresh) {
    Jundy::AlfredWorkflow::Update::refresh();
    exit 0;
}

if ($install) {
    # Always exit cleanly so the message reaches the notification downstream,
    # whether the install worked or not.
    my (undef, $message) = Jundy::AlfredWorkflow::Update::install($ARGV[0]);
    print $message;
    exit 0;
}

# Without a switch this is the "check for updates" script filter.  Ask GitHub
# right now rather than trusting the cache, because the user explicitly asked.
my (undef, $error) = Jundy::AlfredWorkflow::Update::refresh();

my $current = Jundy::AlfredWorkflow::Update::current_version();
my $update  = Jundy::AlfredWorkflow::Update::available();

my %display_data = (data => []);

if ($update) {
    $display_data{data} = [
        {
            title     => "Install version $update->{version}",
            subtitle  => "Currently running $current",
            arg       => $update->{url},
            variables => { joplin_action => 'update' },
        }
    ];
}
elsif ($error) {
    $display_data{data} = [ { title => 'Could not check for updates', subtitle => $error, valid => 0 } ];
}
else {
    $display_data{data} = [ { title => "Version $current is the latest release", subtitle => '', valid => 0 } ];
}

Jundy::AlfredWorkflow::Filter::display(\%display_data);
