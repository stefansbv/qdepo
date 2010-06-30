package Pdqm::Wx::Notebook;

use strict;
use warnings;

use Wx qw(:everything);  # Eventualy change this !!!
use Wx::AUI;

use base qw{Wx::AuiNotebook};

sub new {

    my ( $class, $gui, $repo ) = @_;

    #- The Notebook

    my $self = $class->SUPER::new(
        $gui,
        -1,
        [-1, -1],
        [-1, -1],
        wxAUI_NB_TAB_FIXED_WIDTH,
    );

    $self->{repo} = $repo;  # Report app object

    #-- Panels

    $self->{p1} = Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize );
    $self->{p2} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );

    $self->{p3} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );
    $self->{p4} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );

    #--- Pages

    $self->AddPage( $self->{p1}, 'Query' );
    $self->AddPage( $self->{p2}, 'Parameters' );
    $self->AddPage( $self->{p3}, 'SQL' );
    $self->AddPage( $self->{p4}, 'Configs' );

    # # Works but makes interface to not respond to mouse interaction
    # Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGING(
    #     $self, -1, \&OnPageChanging );

    # # Inspired ... from Kephra ;)
    # Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED(
    #     $self,
    #     -1,
    #     sub {
    #         my ( $bar, $event ) = @_;  # bar !!! realy? :)

    #         my $new_pg = $event->GetSelection;
    #         my $old_pg = $event->GetOldSelection;

    #         $self->{repo}->on_page_change($old_pg, $new_pg);

    #         $event->Skip;
    #     });


    return $self;
}

1;
