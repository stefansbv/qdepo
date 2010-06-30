package Pdqm::Model;

use strict;
use warnings;

use DBI;
use SQL::Abstract;

use Pdqm::Config;
use Pdqm::Observable;

sub new {
    my $class = shift;

    my $self = {
        _connected => Pdqm::Observable->new(),
        _stdout    => Pdqm::Observable->new(),
    };

    bless $self, $class;

    return $self;
}

sub db_connect {
    my $self = shift;

    if ( not $self->is_connected ) {
        $self->_connect();
    }
    if ( $self->is_connected ) {
        $self->get_connection_observable->set( 1 );
        $self->_print('Connected.');
    }
    else {
        $self->get_connection_observable->set( 0 );
        $self->_print('NOT connected.');
    }

    return $self;
}

sub db_disconnect {
    my $self = shift;
    if ( $self->is_connected ) {
        $self->_disconnect;
        $self->get_connection_observable->set( 0 );
        $self->_print('Disconnected.');
    }
    return $self;
}

sub _connect {

    # Connect to the database

    my $self = shift;

    # Get config info
    my $rc = Pdqm::Config->new();
    my $conf = $rc->get_config('conninfo');

    my $dbms   = $conf->{DBMS};
    my $server = $conf->{Server};
    my $user   = $conf->{User};
    my $pass   = $conf->{Pass};
    my $dbname = $conf->{Database};

    $self->_print("Connect to $dbms ...");

    eval {
        $self->{dbh} = DBI->connect(
            "DBI:Pg:" .
            "dbname=" . $dbname .
            ";host=" . $server,
            $user,
            $pass,
            { RaiseError => 1, FetchHashKeyName => 'NAME_lc' }
        );
    };
    if ($@) {
        $self->_print("Transaction aborted: $@");
        $self->get_connection_observable->set( 0 );
    }
    else {
        $self->get_connection_observable->set( 1 );
    }

    return;
}

sub _disconnect {
    my ($self) = @_;
    $self->_dbh->disconnect;
}

sub _dbh {
    my ($self) = @_;
    return $self->{dbh};
}

sub is_connected {
    my $self = shift;
    return $self->get_connection_observable->get;
}

sub get_connection_observable {
    my $self = shift;
    return $self->{_connected};
}

sub get_stdout_observable {
    my $self = shift;
    return $self->{_stdout};
}

sub _print {
    my ( $self, $line ) = @_;
    $self->get_stdout_observable->set( $line );
}

sub on_page_change {
    my ($self, $new_pg, $old_pg) = @_;
    print " page changed, current is $new_pg and old $old_pg\n";
    # $self->get_stdout_observable->set( $new_pg );
}

sub on_item_selected {
    my ($self, ) = @_;
    print "other list item selected \n";
}

1;
