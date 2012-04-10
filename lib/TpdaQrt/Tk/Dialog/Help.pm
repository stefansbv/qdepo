package TpdaQrt::Tk::Dialog::Help;

use strict;
use warnings;
use utf8;

use Tk;
use IO::File;

use TpdaQrt::Tk::TB;

=head1 NAME

TpdaQrt::Tk::Dialog::Help - Dialog for quick help.

=head1 VERSION

Version 0.49

=cut

our $VERSION = 0.49;

=head1 SYNOPSIS

    use TpdaQrt::Tk::Dialog::Help;

    my $fd = TpdaQrt::Tk::Dialog::Help->new;

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $class = shift;

    my $self = {
        tb3   => {},    # ToolBar
        tlw   => {},    # TopLevel
        ttext => '',    # text
    };

    return bless( $self, $class );
}

=head2 search_dialog

Define and show search dialog.

=cut

sub help_dialog {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('Help');

    # Main frame
    my $tbf0 = $self->{tlw}->Frame();
    $tbf0->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'x',
    );

    # Frame for main toolbar
    my $tbf1 = $tbf0->Frame();
    $tbf1->pack( -side => 'left', -anchor => 'w' );

    #-- ToolBar

    $self->{tb3} = $tbf1->TB();

    my $attribs = {
        'tb3gd' => {
            'tooltip' => 'Show User Guide',
            'icon'    => 'appbook16',
            'sep'     => 'none',
            'help'    => 'Show User Guide',
            'method'  => sub { $self->toggle_load('ugd'); },
            'type'    => '_item_check',
            'id'      => '20001',
        },
        'tb3gp' => {
            'tooltip' => 'Show GPL',
            'icon'    => 'appbox16',    # actbookmark16 appbrowser16
            'sep'     => 'after',
            'help'    => 'Show GPL',
            'method' => sub { $self->toggle_load('gpl'); },
            'type'   => '_item_check',
            'id'     => '20002',
        },
        'tb3qt' => {
            'tooltip' => 'Close',
            'icon'    => 'actexit16',
            'sep'     => 'after',
            'help'    => 'Quit',
            'method'  => sub { $self->dlg_exit; },
            'type'    => '_item_normal',
            'id'      => '20003',
        }
    };

    my $toolbars = [ 'tb3gd', 'tb3gp', 'tb3qt', ];

    $self->{tb3}->make_toolbar_buttons( $toolbars, $attribs );

    #-- end ToolBar

    # Frame 1
    my $frame1 = $self->{tlw}->LabFrame(
        -foreground => 'blue',
        -label      => 'Document',
        -labelside  => 'acrosstop'
        )->pack(
        -side => 'bottom',
        -fill => 'both'
        );

    # Text
    $self->{ttext} = $frame1->Scrolled(
        'Text',
        Name        => 'importantText',
        -width      => 70,
        -height     => 30,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'white'
    );

    $self->{ttext}->pack(
        -anchor => 's',
        -padx   => 3,
        -pady   => 3,
        -expand => 's',
        -fill   => 'both'
    );

    # define some fonts.
    my $basefont
        = $self->{ttext}->cget('-font')->Clone( -family => 'Helvetica' );
    my $boldfont = $basefont->Clone( -weight => 'bold', -family => 'Arial' );

    # define a tag for bold font.
    $self->{ttext}->tag( 'configure', 'boldtxt',   -font => $boldfont );
    $self->{ttext}->tag( 'configure', 'normaltxt', -font => $basefont );
    $self->{ttext}->tag(
        'configure', 'centertxt',
        -font    => $boldfont->Clone( -size => 12 ),
        -justify => 'center'
    );

    $self->toggle_load('ugd');

    MainLoop();

    return;
}

sub toggle_load {
    my ( $self, $doc ) = @_;

    if ( $doc eq 'ugd' ) {
        $self->get_toolbar_btn('tb3gd')->select;
        $self->get_toolbar_btn('tb3gp')->deselect;
    }
    elsif ( $doc eq 'gpl' ) {
        $self->get_toolbar_btn('tb3gd')->deselect;
        $self->get_toolbar_btn('tb3gp')->select;
    }
    else {
        return;
    }

    my $proc = "load_${doc}_text";

    $self->$proc;

    return;
}

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{tb3}->get_toolbar_btn($name);
}

sub load_gpl_text {
    my $self = shift;

    my $cfg = TpdaQrt::Config->instance();

    $self->{ttext}->configure( -state => 'normal' );
    $self->{ttext}->delete( '1.0', 'end' );

    my $txt = $cfg->get_license();

    $self->{ttext}->insert( 'end', $txt );

    # not editable.
    $self->{ttext}->configure( -state => 'disabled' );

    return;
}

sub load_ugd_text {

    my $self = shift;

    $self->{ttext}->configure( -state => 'normal' );
    $self->{ttext}->delete( '1.0', 'end' );

    my $title = "\n Ghid de utilizare \n\n";

    my $txt = get_help_ro();

    # add the help text.
    $self->{ttext}->insert( 'end', $title, 'centertxt' );
    my $tag = 'normaltxt';

    for my $section ( split( /(<[^>]+>)/, $txt ) ) {
        if ( $section eq '<BOLD>' ) {
            $tag = 'boldtxt';
        }
        elsif ( $section eq '</BOLD>' ) {
            $tag = 'normaltxt';
        }
        else {
            $self->{ttext}->insert( 'end', $section, $tag );
        }
    }

    # not editable.
    $self->{ttext}->configure( -state => 'disabled' );

    return;
}

sub dlg_exit {

    my $self = shift;

    $self->{tlw}->destroy;

    return;
}

sub get_help_ro {

    my $helptext = qq{
           <BOLD>Introducere</BOLD>

           TPDA - Query Repository Tool' este un program utilitar
           destinat exportului de informaţii dintr-o bază de date
           relaţională în fişiere format proprietar Microsoft Excel,
           sau în fişiere care folosesc open document format (ODF),
           adică OpenOffice sau LibreOffice Calc.  De asemenea este
           suportat şi formatul CSV.

           Aplicația este foarte simplu de folosit, se alege o
           interogare din listă şi se apasă pe butonul 'Run' (simbol:
           săgeată albastru spre dreapta).

           Dacă totul funcţionează normal, atunci va fi generat
           fişierul cerut în directorul de ieşire.

           <BOLD>Atenţie</BOLD> generarea fişierelor în format ODF poate dura
           destul de mult: de exemplu 100 înregistrări în 10 minute.

           <BOLD>Administratori</BOLD>

           Administratorii de sistem pot definii interogări noi folosind
           interfaţa aplicaţiei.

};

    return $helptext;
}

1;
