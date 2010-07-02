package Pdqm::Model;

use strict;
use warnings;

use Pdqm::Config;
use Pdqm::FileIO;
use Pdqm::Observable;
use Pdqm::Db;

sub new {
    my ($class, $args) = @_;

    my $self = {
        _connected => Pdqm::Observable->new(),
        _stdout    => Pdqm::Observable->new(),
        _updated   => Pdqm::Observable->new(),
        _editmode  => Pdqm::Observable->new(),
    };

    bless $self, $class;

    # Initializations

    $self->{cfg} = Pdqm::Config->new( $args );

    return $self;
}

#- next: DB

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

sub _connect {
    my $self = shift;

    # Connect to database
    my $db = Pdqm::Db->new($self->{cfg}{conninfo});

    # Is connected ?
    if ( ref( $db->dbh() ) =~ m{DBI} ) {
        $self->get_connection_observable->set( 1 );
    }
    else {
        $self->get_connection_observable->set( 0 );
    }
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

sub _disconnect {
    my $self = shift;

    my $db = Pdqm::Db->new();
    $db->dbh->disconnect;
}

sub is_connected {
    my $self = shift;

    return $self->get_connection_observable->get;
    # What if the connection is lost ???
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

sub get_list_data {
    my ($self) = @_;

    # XML read - write module
    $self->{xmldata} = Pdqm::FileIO->new($self->{cfg}{rex} );
    my $titles = $self->{xmldata}->get_titles();

    if (ref $titles) {
        $self->get_updated_observable->set( 1 );
        $self->_print("Got the titles");
    }
    else {
        $self->get_updated_observable->set( 0 );
        $self->_print("No titles1");
    }

    return $titles;
}

sub get_updated_observable {
    my $self = shift;

    return $self->{_updated};
}

sub run_export {
    my ($self) = @_;

    $self->_print("Running export :-)");
}

# prev: List
# next: Edit mode

sub set_editmode {
    my $self = shift;

    if ( !$self->is_editmode ) {
        $self->get_editmode_observable->set(1);
    }
    if ( $self->is_editmode ) {
        $self->_print("Edit mode.");
    }
    else {
        $self->_print("Idle mode.");
    }
}

sub set_idlemode {
    my $self = shift;

    if ( $self->is_editmode ) {
        $self->get_editmode_observable->set(0);
    }
    if ( $self->is_editmode ) {
        $self->_print("Edit mode.");
    }
    else {
        $self->_print("Idle mode.");
    }
}

sub is_editmode {
    my $self = shift;

    return $self->get_editmode_observable->get;
}

sub get_editmode_observable {
    my $self = shift;

    return $self->{_editmode};
}

sub save_query_def {
    my $self = shift;

    $self->_print("Edit mode");
}

# prev: Edit mode

1;
