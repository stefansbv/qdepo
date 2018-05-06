package QDepo::Engine;

# ABSTRACT: Base class for the engine interface

use 5.010001;
use Moose;
use Try::Tiny;
use Locale::TextDomain qw(QDepo);
use QDepo::X qw(hurl);
use namespace::autoclean;

has target => (
    is       => 'ro',
    isa      => 'QDepo::Target',
    required => 1,
    weak_ref => 1,
    handles => {
        uri         => 'uri',
        destination => 'name',
    }
);

sub database { shift->destination }

sub load {
    my ( $class, $p ) = @_;

    # We should have a target param.
    my $target = $p->{target}
        or hurl engine => __x( 'Missing "target" parameter to load()' );

    # Load the engine class.
    my $ekey = $target->engine_key or die 'No engine specified!';

    my $pkg = __PACKAGE__ . '::' . $target->engine_key;
    eval "require $pkg"
        or hurl engine => __x( 'Unable to load {name}', name => $pkg );

    return $pkg->new($p);
}

sub driver { shift->key }

sub key {
    my $class = ref $_[0] || shift;
    die 'No engine specified!' if $class eq __PACKAGE__;
    my $pkg = quotemeta __PACKAGE__;
    $class =~ s/^$pkg\:://;
    return $class;
}

sub name { shift->key }

sub use_driver {
    my $self = shift;
    my $driver = $self->driver;
    eval "use $driver";
    die $self->key . __x(
        ' {driver} required to manage {engine}',
        driver => $driver,
        engine => $self->name,
    ) if $@;
    return $self;
}

# sub handle_error {
#     my ( $self, $err,  $dbh )  = @_;
#     my ( $name, $param ) = $self->parse_error($err);
#     my $categ = $self->get_message_categ($name);
#     if ( defined $dbh and $dbh->isa('DBI::db') ) {
#         my $message =
#             ( $name eq 'unknown' )
#             ? $dbh->errstr
#             : $self->get_message($name);
#         Exception::Db::SQL->throw(
#             logmsg  => $err,
#             usermsg => __x( $message, name => $param ),
#         );
#     }
#     else {
#         my $message
#             = ( $name eq 'unknown' )
#             ? DBI->errstr
#             : $self->get_message($name);
#         if ( $categ eq 'auth' ) {
#             Exception::Db::Connect::Auth->throw(
#                 logmsg  => $err,
#                 usermsg => __x( $message, name => $param ),
#             );
#         }
#         elsif ( $categ eq 'conn' ) {
#             Exception::Db::Connect->throw(
#                 logmsg  => $err,
#                 usermsg => __x( $message, name => $param ),
#             );
#         }
#         elsif ( $categ eq 'network' ) {
#             Exception::Db::Connect->throw(
#                 logmsg  => $err,
#                 usermsg => __x( $message, name => $param ),
#             );
#         }
#         elsif ( $categ eq 'system' ) {
#             say "categ eq 'system'";
#             Exception::Db::Connect::Sys->throw(
#                 logmsg  => "SYS:$err",
#                 usermsg => __x( $message, name => $param ),
#             );
#         }
#         else {
#             Exception::Db::Connect->throw(
#                 logmsg  => $err,
#                 usermsg => __x( $message, name => $param ),
#             );
#         }
#     }
#     return;
# }

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

QDepo::Engine - Base class for the engine interface

=head1 Synopsis

  ok my $engine = QDepo::Engine->load({
  });
  my $records = $engine->get_data;

=head1 Description

QDepo::Engine is the base class for all engine modules.

=head1 Interface

=head2 Constructors

=head3 C<load>

  my $engine = QDepo::Engine->load( \%params );

A factory method for instantiating QDepoDev engines.  It loads the
subclass for the specified engine and calls C<new> with the hash
parameter.  Supported parameters are:

=over

=item C<engine>

The name of the engine to be used.

=item C<options>

TODO!

An L<QDepo::Options> representing the options and configs
passed and read by the application.

=back

=head2 Attributes

=head3 C<options>

TODO!

  my $options = $self->options;

Returns the L<QDepo::Options> object that instantiated the engine.

=head1 Author

David E. Wheeler <david@justatheory.com>

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2012-2014 iovation Inc.

Copyright (c) 2016 Ștefan Suciu.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
