package Pdqm::Db::Instance;

use strict;
use warnings;

use Pdqm::Db::Connection;
use base qw(Class::Singleton);

use vars qw($VERSION);
$VERSION = 0.01;

sub _new_instance {

    my ($type, $repo) = @_;

    my $class = ref $type || $type;

    my $conn = Pdqm::Db::Connection->new( $repo );
    my $dbh = $conn->db_connect(
        'stefan',
        'tba790k',
    );

    # Some defaults
    $dbh->{AutoCommit}  = 1;            # disable transactions
    $dbh->{RaiseError}  = 1;
    $dbh->{LongReadLen} = 512 * 1024;

    return bless {dbh => $dbh}, $class;
}


1;

__END__
