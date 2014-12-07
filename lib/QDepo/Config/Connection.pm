package QDepo::Config::Connection;

# ABSTRACT: Database connection data

use Mouse;
use Locale::TextDomain 1.20 qw(QDepo);

has 'dbname' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'driver' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    default  => sub { 'localhost' },
);

has 'port' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    default => sub {
        my $self       = shift;
        my $driver = $self->driver;
        my $port
            = $driver eq q{firebird}   ? 3050
            : $driver eq q{postgresql} ? 5432
            : $driver eq q{mysql}      ? 3306
            : $driver eq q{cubrid}     ? 30000
            : $driver eq q{sqlite}     ? undef
            :                            undef;
            return  $port;
        },
);

has 'user' => (
    is       => 'rw',
    isa      => 'Str',
);

has 'pass' => (
    is       => 'rw',
    isa      => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
