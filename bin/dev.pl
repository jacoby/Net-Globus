#!/usr/bin/env perl

use feature qw{ say } ;
use strict ;
use warnings ;
use Data::Dumper ;

# this works when not pulled into a for-deployment and not
# anonymized 

use Net::Globus ;

my $g        = Net::Globus->new() ;
my $username = 'jacoby' ;
$g->set_username($username) ;
$g->set_key_path('/home/jacoby/.ssh/id_globus') ;

# uses SSH for access. I haven't worked my way through their 
# REST API documentation yet.

# this code shares two directories as jacoby#DIR1 and jacoby#DIR2
# 

for my $dir (qw{ dir1 dir2 }) {
    my $end       = uc $dir ;
    my $directory = '/path/to/shared/directories/' . $dir . '/' ;
    my $endpoint  = join '#', $username, $end ;

    # create an endpoint, share with a second email address
    $g->endpoint_add_shared( 'institution#server', $directory, $end ) ;
    $g->acl_add( $endpoint . '/', 'jacoby@example.com' ) ;

    # list the files and directories in this endpoint
    for my $node ( $g->ls( $endpoint . '/' ) ) { say "\t", $node }

    # list the people this endpoint is shared with 
    my @out = $g->acl_list($endpoint) ;
    for my $acl (@out) {
        my ( $principal, $id, $permissions )
            = map { $acl->{$_} } qw{principal id permissions} ;
        say join "\t", $endpoint, $id, $permissions, $principal, ;
        }
    say '' ;
    }

exit;
my @endpoints = $g->endpoint_list() ;
for my $endpoint (@endpoints) {
    say "\tNuking\t" . $endpoint ;
    my ( $username, $end ) = split m{#}, $endpoint ;
    $g->endpoint_remove($end) ;
    }

say '' ;
exit ;
