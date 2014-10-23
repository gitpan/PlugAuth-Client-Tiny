package PlugAuth::Client::Tiny;

use strict;
use warnings;
use 5.006;
use HTTP::Tiny;

# ABSTRACT: Minimal PlugAuth client
our $VERSION = '0.01'; # VERSION


sub new
{
  my $class = shift;
  my %args = ref $_[0] ? %{$_[0]} : @_;
  my $url = (delete $args{url}) || 'http://localhost:3000/';
  $url =~ s{/?$}{/};
  return bless { 
    url    => $url,
    http   => HTTP::Tiny->new(%args),
  }, $class;
}


sub url { shift->{url} }


sub auth
{
  my($self, $user, $password) = @_;
  
  my $response = $self->{http}->get($self->{url} . 'auth', { 
    headers => { 
      ## TODO option for setting the realm
      # WWW-Authenticate: Basic realm="..."
      Authorization => 'Basic ' . do {
        ## TODO maybe use MIME::Base64 if available?
        ## it is XS, but may be faster.
        use integer;
        my $a = join(':', $user,$password);
        my $r = pack('u', $a);
        $r =~ s/^.//mg;
        $r =~ s/\n//g;
        $r =~ tr|` -_|AA-Za-z0-9+/|;
        my $p = (3-length($a)%3)%3;
        $r =~ s/.{$p}$/'=' x $p/e if $p;
        $r;
      },
    } 
  });
  
  return 1 if $response->{status} == 200;
  return 0 if $response->{status} == 403
  ||          $response->{status} == 401;
  
  die $response->{content};
}


sub authz
{
  my($self, $user, $action, $resource) = @_;
  
  $resource =~ s{^/?}{};
  my $url = $self->{url} . join('/', 'authz', 'user', $user, $action, $resource);
  my $response = $self->{http}->get($url);
  
  return 1 if $response->{status} == 200;
  return 0 if $response->{status} == 403;
  die $response->{content};
}

1;

__END__

=pod

=head1 NAME

PlugAuth::Client::Tiny - Minimal PlugAuth client

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use PlugAuth::Client::Tiny;
 my $client = PlugAuth::Client::Tiny->new( url => "http://localhost:3000/" );
 if($client->auth('primus', 'spark'))
 {
   # authentication succeeded
 }
 else
 {
   # authentication failed
 }

=head1 DESCRIPTION

PlugAuth::Client::Tiny is a minimal L<PlugAuth> client.  It uses L<HTTP::Tiny> 
instead of L<LWP> or L<Mojo::UserAgent>.  It provides only a mechanism for
authenticating and authorizing against a L<PlugAuth> server.  If you need to
modify the users/groups/authorization on the server through the RESTful API
then you will need the heavier L<PlugAuth::Client> which relies on 
L<Clustericious::Client> and L<Mojo::UserAgent>.

PlugAuth::Client::Tiny should work perfectly with L<PlugAuth::Lite> as well, 
because it only uses the subset of the PlugAuth API which is implemented by
L<PlugAuth::Lite>.

=head1 CONSTRUCTOR

The constructor is (predictably) C<new>:

 use PlugAuth::Client::Tiny->new;
 my $client = PlugAuth::Client::Tiny->new;

PlugAuth::Client::Tiny's constructor accepts one optional option:

=over 4

=item url

The URL of the L<PlugAuth> server.  If not specified, C<http://localhost:3000>
is used.

=back

All other options passed to C<new> will be passed on to the constructor of L<HTTP::Tiny>,
which allows you to set C<agent>, C<default_headers>, etc.  See the documentation of
L<HTTP::Tiny> for details.

=head1 ATTRIBUTES

=head2 $client-E<gt>url

Returns the URL for the L<PlugAuth> server.  This attribute is read-only.

=head1 METHODS

=head2 $client-E<gt>auth( $user, $password )

Attempt to authenticate against the L<PlugAuth> server using the given username and password.
Returns 1 on success, 0 on failure and dies on a connection failure.

=head2 $client-E<gt>authz( $user, $action, $resource)

Determine if the given user is authorized to perform the given action on the given resource.
Returns 1 on success, 0 on failure and dies on connection failure.

=head1 CAVEATS

This module depends on L<HTTP::Tiny>, which is a non-core dependency, and by
some definitions of C<::Tiny>, therefore no longer tiny.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
