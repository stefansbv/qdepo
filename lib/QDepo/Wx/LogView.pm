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

    # TODO: !

    $self->SetMarginType( 1, wxSTC_MARGIN_SYMBOL );
    $self->SetMarginWidth( 1, 0 );

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

    $self->StyleSetSpec(4, "fore:#dca3a3");            #*Singlequoted ?
    #$self->StyleSetForeground( 4,  Wx::Colour->new( 0xdc, 0xa3, 0xa3 ) );
    $self->StyleSetSpec(8, "fore:#705050");            #*Doublequoted ?
    #$self->StyleSetForeground( 8,  Wx::Colour->new( 0x00, 0x00, 0x00 ) );
    $self->StyleSetSpec(9, "fore:#00ff00");            #*List0 ?
    #$self->StyleSetForeground( 9,  Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
    $self->StyleSetSpec(10,"fore:#ff0000");            #*List1 ?
    #$self->StyleSetForeground( 10, Wx::Colour->new( 0x00, 0x00, 0x7f ) );
    $self->StyleSetSpec(11,"fore:#0000ff");            #*List2 ?
    #$self->StyleSetForeground( 11, Wx::Colour->new( 0x00, 0x00, 0xff ) );

    my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );
    $self->SetFont($font);
    $self->StyleSetFont( Wx::Scintilla::STYLE_DEFAULT, $font );
    $self->StyleClearAll();

    $self->StyleSetSpec( Wx::Scintilla::SCE_H_TAG, "fore:#0000ff" );

    $self->SetLexer(Wx::Scintilla::SCLEX_MSSQL);

    return $self;
}

1;
