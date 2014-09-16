package QDepo::Wx::LogView;

# ABSTRACT: QDepo Logger control with syntax highlighting

use strict;
use warnings;

use Wx::Scintilla ();
use base 'Wx::Scintilla::TextCtrl';

use Wx qw(:everything);
use Wx::Event;


sub new {
    my ( $class, $parent ) = @_;

    my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

    $self->SetMarginType( 1, wxSTC_MARGIN_SYMBOL );
    $self->SetMarginWidth( 1, 0 );
    $self->SetWrapMode(wxSTC_WRAP_NONE); # wxSTC_WRAP_WORD
    $self->StyleSetFont( wxSTC_STYLE_DEFAULT,
        Wx::Font->new( 10, wxDEFAULT, wxNORMAL, wxNORMAL, 0, 'Courier New' ) );
    $self->SetLexer( wxSTC_LEX_MSSQL );
    $self->SetWrapMode(wxSTC_WRAP_NONE); # wxSTC_WRAP_WORD

    # List0
    $self->SetKeyWords(0, q{ii} );
    # List1
    $self->SetKeyWords(1, q{ee} );
    # List2
    $self->SetKeyWords(2, q{ww} );

    $self->SetTabWidth(4);
    $self->SetIndent(4);
    $self->SetHighlightGuide(4);
    $self->StyleClearAll();

    # MSSQL - works with wxSTC_LEX_MSSQL
    $self->StyleSetSpec( 3,  "fore:#0000ff" );    #*Number
    $self->StyleSetSpec( 4,  "fore:#dca3a3" );    #*Singlequoted
    $self->StyleSetSpec( 8,  "fore:#705050" );    #*Doublequoted
    $self->StyleSetSpec( 9,  "fore:#00ff00" );    #*List0
    $self->StyleSetSpec( 10, "fore:#ff0000" );    #*List1
    $self->StyleSetSpec( 11, "fore:#0000ff" );    #*List2

    return $self;
}

1;
