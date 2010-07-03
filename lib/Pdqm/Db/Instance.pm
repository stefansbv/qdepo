package Pdqm::Db::Instance;

use strict;
use warnings;

use Pdqm::Db::Connection;
use base qw(Class::Singleton);

use vars qw($VERSION);
$VERSION = 0.01;

sub _new_instance {
    my ($class, $args) = @_;

    my $conn = Pdqm::Db::Connection->new( $args );
    my $dbh = $conn->db_connect(
        'stefan',   # ??? from cli params !!!
        'tba790k',  # ??? from cli params !!!
    );

    # Some defaults
    $dbh->{AutoCommit}  = 1;            # disable transactions
    $dbh->{RaiseError}  = 1;
    $dbh->{LongReadLen} = 512 * 1024;

    return bless {dbh => $dbh}, $class;
}


1;

__END__
