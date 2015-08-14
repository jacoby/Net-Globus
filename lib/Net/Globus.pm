package Net::Globus;
=pod

=head1 NAME

Net::Globus - Object-Oriented interface to Globus

=head1 DESCRIPTION

Globus is a tool that allows the sharing of scientific data between 
researchers and institutions. Globus enables you to transfer your 
data using just a web browser, or using their SSH interface at 
cli.globusonline.org.

This is a client library for the Globus Online Transfer API.

For detailed documentation of the Transfer API, 
see https://transfer.api.globusonline.org

=head1 LICENSE

Copyright (C) 2015, Dave Jacoby.

This program is free software, you can redistribute it and/or modify it 
under the terms of the Artistic License version 2.0.

=head1 AUTHOR

Dave Jacoby - L<jacoby.david@gmail.com>

=cut

use feature qw{ state say } ;
use strict ;
use warnings ;
use Carp ;
use Data::Dumper ;
use JSON ;
use Net::OpenSSH ;

sub new {
    my ( $class, $username, $key_path ) = @_ ;
    my $self = {} ;
    bless $self, $class ;
    $self->{username} = $username || 'none' ;
    $self->{key_path} = $key_path || 'none' ;
    return $self ;
    }

sub dump {
    my $self = shift ;
    return Dumper $self ;
    }

sub set_username {
    my ( $self, $username ) = @_ ;
    $self->{username} = $username ;
    }

sub set_key_path {
    my ( $self, $key_path ) = @_ ;
    $self->{key_path} = $key_path ;
    }

sub ls {
    my ( $self, $file_path ) = @_ ;
    my $command = qq{ls $file_path} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my @result = split m{\r?\n}, $result ;
    return wantarray ? @result : \@result ;
    }

sub scp {
    my ( $self, $from_path, $to_path, $recurse ) = @_ ;
    $recurse = $recurse ? '-r' : '' ;
    my $command = qq{scp $recurse $from_path $to_path} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

sub transfer {
    my ( $self, $from_path, $to_path, $recurse ) = @_ ;
    $recurse = $recurse ? '-r' : '' ;
    my $command = qq{transfer $from_path $to_path} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

# handling access permission

sub acl_add {
    my ( $self, $endpoint, $email, $rw ) = @_ ;
    my $readwrite = 'rw' ;
    $readwrite = 'r' unless $rw ;
    my $command = qq{acl-add $endpoint --email $email --perm $readwrite } ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my ($id) = $result =~ m{(\d+)} ;
    return $id ;
    }

sub acl_list {
    my ( $self, $endpoint ) = @_ ;
    my $command = qq{acl-list $endpoint} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my @slist = decode_json $result ;
    my $list  = $slist[0] ;
    return wantarray ? @$list : $list ;
    }

sub acl_remove {
    my ( $self, $endpoint, $id ) = @_ ;
    my $command = qq{acl-remove $endpoint --id $id} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

# creating new shares

# $ endpoint-add --sharing "purdue#rcac/home/djacoby/Globus/" Globus

sub endpoint_add_shared {
    my ( $self, $sharer_endpoint, $path, $endpoint ) = @_ ;
    my $command
        = qq{endpoint-add --sharing "$sharer_endpoint$path" $endpoint } ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

sub endpoint_list {
    my ($self) = @_ ;
    my $command = qq{endpoint-list} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my @result = map { ( split m{\s}, $_ )[0] } split "\n", $result ;
    return wantarray ? @result : \@result ;
    }

sub endpoint_remove {
    my ( $self, $endpoint ) = @_ ;
    my $command = qq{endpoint-remove $endpoint} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

sub profile {
    my ($self) = @_ ;
    my $command = qq{profile} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my %output
        = map { my ( $k, $v ) = split m{:\s?}, $_ ; $k => $v } split m{\n},
        $result ;
    return wantarray ? %output : \%output ;
    }

sub cancel              { }    # stops a task
sub delete              { }    # delete files/folders
sub details             { }    # info about task list
sub endpoint_activate   { }    # not sure what we get by activate/deactivate
sub endpoint_deactivate { }    # not sure what we get by activate/deactivate
sub endpoint_modify     { }    # changes attributes
sub endpoint_rename     { }    # changes endpoint name
sub events              { }    # task
sub help                { }
sub mkdir               { }    # file
sub modify              { }    # task
sub rename              { }    # file
sub rm                  { }    # file
sub status              { }    # tasks
sub versions            { }    # globus
sub wait                { }    # task

sub _globus_action {
    my ( $command, $user, $key_path ) = @_ ;
    my $host = '@cli.globusonline.org' ;

    my $ssh = Net::OpenSSH->new(
        $user . $host,
        key_path => $key_path,
        async    => 0,
        ) ;

    $ssh->error
        and die "Couldn't establish SSH connection: " . $ssh->error ;

    my $response = $ssh->capture($command)
        or die "remote command failed: " . $ssh->error ;

    return $response ;
    }

1 ;
