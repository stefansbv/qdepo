package QDepo::Wx::LogView;

use strict;
use warnings;

use Wx::Scintilla ();
use base 'Wx::Scintilla::TextCtrl';

use Wx qw(:everything);
use Wx::Event;

# Override the constructor to Enable Perl support in the editor
sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

    # TODO: !

    $self->SetMarginType( 1, wxSTC_MARGIN_SYMBOL );
    $self->SetMarginWidth( 1, 0 );

    # $self->SetLexer( wxSTC_LEX_MSSQL );
    # $self->SetWrapMode(wxSTC_WRAP_NONE); # wxSTC_WRAP_WORD

    # # List0
    # $self->SetKeyWords(0, q{ii} );
    # # List1
    # $self->SetKeyWords(1, q{ee} );
    # # List2

    # $self->SetKeyWords(2, q{ww} );
    # $self->SetTabWidth(4);
    # $self->SetIndent(4);
    # $self->SetHighlightGuide(4);
    # $self->StyleClearAll();

    # $self->StyleSetSpec(4, "fore:#dca3a3");            #*Singlequoted
    # $self->StyleSetSpec(8, "fore:#705050");            #*Doublequoted
    # $self->StyleSetSpec(9, "fore:#00ff00");            #*List0
    # $self->StyleSetSpec(10,"fore:#ff0000");            #*List1
    # $self->StyleSetSpec(11,"fore:#0000ff");            #*List2

    # $self->SetLexer(Wx::Scintilla::SCLEX_PERL);

    # From the SYNOPSIS

    # Set the font
    my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );
    $self->SetFont($font);
    $self->StyleSetFont( Wx::Scintilla::STYLE_DEFAULT, $font );
    $self->StyleClearAll();

    # Set the various Perl lexer colors
    $self->StyleSetForeground( 0,  Wx::Colour->new( 0x00, 0x00, 0x7f ) );
    $self->StyleSetForeground( 1,  Wx::Colour->new( 0xff, 0x00, 0x00 ) );
    $self->StyleSetForeground( 2,  Wx::Colour->new( 0x00, 0x7f, 0x00 ) );
    $self->StyleSetForeground( 3,  Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
    $self->StyleSetForeground( 4,  Wx::Colour->new( 0x00, 0x7f, 0x7f ) );
    $self->StyleSetForeground( 5,  Wx::Colour->new( 0x00, 0x00, 0x7f ) );
    $self->StyleSetForeground( 6,  Wx::Colour->new( 0xff, 0x7f, 0x00 ) );
    $self->StyleSetForeground( 7,  Wx::Colour->new( 0x7f, 0x00, 0x7f ) );
    $self->StyleSetForeground( 8,  Wx::Colour->new( 0x00, 0x00, 0x00 ) );
    $self->StyleSetForeground( 9,  Wx::Colour->new( 0x7f, 0x7f, 0x7f ) );
    $self->StyleSetForeground( 10, Wx::Colour->new( 0x00, 0x00, 0x7f ) );
    $self->StyleSetForeground( 11, Wx::Colour->new( 0x00, 0x00, 0xff ) );
    $self->StyleSetForeground( 12, Wx::Colour->new( 0x7f, 0x00, 0x7f ) );
    $self->StyleSetForeground( 13, Wx::Colour->new( 0x40, 0x80, 0xff ) );
    $self->StyleSetForeground( 17, Wx::Colour->new( 0xff, 0x00, 0x7f ) );
    $self->StyleSetForeground( 18, Wx::Colour->new( 0x7f, 0x7f, 0x00 ) );
    $self->StyleSetBold( 12, 1 );
    $self->StyleSetSpec( Wx::Scintilla::SCE_H_TAG, "fore:#0000ff" );

    # set the lexer to Perl 5
    $self->SetLexer(Wx::Scintilla::SCLEX_PERL);

    return $self;
}

1;
