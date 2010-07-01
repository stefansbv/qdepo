package Pdqm::Model;

use strict;
use warnings;

use Data::Dumper;

use DBI;
use SQL::Abstract;

use Pdqm::Config;
use Pdqm::FileIO;
use Pdqm::Observable;

sub new {
    my ($class, $args) = @_;

    my $self = {
        _connected => Pdqm::Observable->new(),
        _stdout    => Pdqm::Observable->new(),
        _updated   => Pdqm::Observable->new(),
    };

    bless $self, $class;

    $self->{cfg} = Pdqm::Config->new( $args );

    $self->data_load_list( $self->{cfg}->rex );
    # $self->db_connect(  );

    return $self;
}

#- next: DB

sub db_connect {
    my ($self, $args) = @_;

    if ( not $self->is_connected ) {
        $self->_connect($args);
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
    my ($self, $args) = @_;

    $args = $self->{cfg}->conninfo;

    # Get config info
    my $dbms   = $args->{DBMS};
    my $server = $args->{Server};
    my $user   = $args->{User};
    my $pass   = $args->{Pass};
    my $dbname = $args->{Database};

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

#- prev: DB
#- next: Log

sub get_stdout_observable {
    my $self = shift;
    return $self->{_stdout};
}

sub _print {
    my ( $self, $line ) = @_;
    print "$line\n";
    # $self->get_stdout_observable->set( $line );
}

#- prev: Log
#- next: Event

sub on_page_change {
    my ($self, $new_pg, $old_pg) = @_;
    print " page changed, current is $new_pg and old $old_pg\n";
    # $self->get_stdout_observable->set( $new_pg );
}

sub on_item_selected {
    my ($self, ) = @_;
    print "other list item selected \n";
}

#- prev: Event
#- next: List

sub data_load_list {

    my ($self, $args) = @_;

    # XML read - write module
    $self->{xmldata} = Pdqm::FileIO->new($args);
    my $titles = $self->{xmldata}->get_titles();

    # $self->list_populate_all($titles);

    $self->get_updated_observable->set( 1 );

    return;
}

sub get_updated_observable {
    my $self = shift;
    return $self->{_updated};
}

# sub list_populate_all {

#     my ($self, $titles) = @_;

#     # Clear list
#     $self->{control}->list_item_clear_all();

#     # Populate list in sorted order
#     my @titles = sort { $a <=> $b } keys %{$titles};
#     foreach my $indice ( @titles ) {
#         my $nrcrt = $titles->{$indice}[0];
#         my $title = $titles->{$indice}[1];
#         my $file  = $titles->{$indice}[2];
#         $self->{control}->list_item_insert($indice, $nrcrt, $title, $file);
#     }

#     # Set item 0 selected on start
#     $self->{control}->list_item_select_first();

#     return;
# }

1;
