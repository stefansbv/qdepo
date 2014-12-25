package QDepo::Wx::Notebook;

# ABSTRACT: A notebook widget

use strict;
use warnings;

use Locale::TextDomain 1.20 qw(QDepo);
use Wx qw(wxAUI_NB_TAB_FIXED_WIDTH);
use Wx::AUI;

use base qw{Wx::AuiNotebook};

sub new {
    my ( $class, $parent ) = @_;

    #- The Notebook

    my $self = $class->SUPER::new(
        $parent, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxAUI_NB_TAB_FIXED_WIDTH,
    );

    #-- Panels

    $self->{p1} = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
    $self->{p2} = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
    $self->{p3} = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
    $self->{p4} = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );

    #--- Pages

    $self->AddPage( $self->{p1}, __ 'Queries' );
    $self->AddPage( $self->{p2}, __ 'Info' );
    $self->AddPage( $self->{p3}, __ 'SQL' );
    $self->AddPage( $self->{p4}, __ 'Admin' );

    $self->{pages} = {
        0 => 'p1',
        1 => 'p2',
        2 => 'p3',
        3 => 'p4',
    };

    $self->{nb_prev} = q{};
    $self->{nb_curr} = q{};

    return $self;
}

sub get_current {
    my $self = shift;
    my $idx  = $self->GetSelection();
    return $self->{pages}{$idx};
}

1;

=head1 SYNOPSIS

    use QDepo::Wx::Notebook;

    $self->{_nb} = QDepo::Wx::Notebook->new( $parent );

=head2 new

Constructor method.

=cut
