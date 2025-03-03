#!/usr/bin/perl -I perl_modules

use strict;
use warnings;

use Joplin;
use Jundy::AlfredWorkflow::Filter;

my $find = join(' ', @ARGV);

my %display_data = (
    data  => [],
    empty => { title => "No folders found", subtitle => "Please try a different search" },
);

my ($folders, $error) = get_folders($find);

if ($error) {
    $display_data{empty} = { title => 'Error', subtitle => $error };
}
else {
    if (keys %$folders) {
        map {
            push(
                @{$display_data{data}},
                { title => $folders->{$_}{title}, subtitle => $folders->{$_}{full_name}, arg => $folders->{$_}{id} }
            )
        } sort { $folders->{$a}{full_name} cmp $folders->{$b}{full_name} } keys %$folders;
    }
}

Jundy::AlfredWorkflow::Filter::display(\%display_data);

sub get_folders {
    my $filter = shift;
    my %folders;

    my $data = Joplin::get_data(["folders"]);

    if (exists $data->{error}) {
        my @lines = split(/\n/, $data->{error});
        $lines[0] =~ s/"/'/g;
        return {}, Joplin::parse_error($data);
    }

    foreach my $item (@{$data->{items}}) {
        $folders{$item->{id}} = $item;
    }

    foreach my $id (keys %folders) {
        $folders{$id}{full_name} = _get_folder_name(\%folders, $id)
    }

    foreach my $id (keys %folders) {
        if ($folders{$id}{title} !~ /$filter/i) {
            delete $folders{$id};
        }
    }

    return \%folders, '';
}

sub _get_folder_name {
    my $folders = shift;
    my $id = shift;

    if ($folders->{$id}{parent_id}) {
        my $parent = _get_folder_name($folders, $folders->{$id}{parent_id});
        return join(' -> ', $parent, $folders->{$id}{title});
    } else {
        return $folders->{$id}{title};
    }
}