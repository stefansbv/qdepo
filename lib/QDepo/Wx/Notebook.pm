package QDepo::Wx::Notebook;

# ABSTRACT: A notebook controll

use strict;
use warnings;

use Wx qw(:everything);  # TODO: Eventualy change this!
use Wx::AUI;

use base qw{Wx::AuiNotebook};

=head1 SYNOPSIS

    use QDepo::Wx::Notebook;

    $self->{_nb} = QDepo::Wx::Notebook->new( $gui );

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $gui ) = @_;

    #- The Notebook

    my $self = $class->SUPER::new(
        $gui,
        -1,
        [-1, -1],
        [-1, -1],
        wxAUI_NB_TAB_FIXED_WIDTH,
    );

    #-- Panels

    $self->{p1} = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
    $self->{p2} = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
    $self->{p3} = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
    $self->{p4} = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );

    #--- Pages

    $self->AddPage( $self->{p1}, 'Query list' );
    $self->AddPage( $self->{p2}, 'Param/Fields' );
    $self->AddPage( $self->{p3}, 'SQL query' );
    $self->AddPage( $self->{p4}, 'Configs/Log' );

    return $self;
}

1;
