package QDepo::Wx::Dialog::Help;

# ABSTRACT: QDepo help dialog

use strict;
use warnings;

use Wx::Html;
use Wx::Help;
use Wx::FS;

use Wx qw(wxHF_FLATTOOLBAR wxHF_DEFAULTSTYLE);
use Wx::Event qw(EVT_BUTTON);

# very important for HTB to work
Wx::FileSystem::AddHandler( new Wx::ZipFSHandler );

sub new {
    my $class = shift;
    return bless( {}, $class );
}

sub show_html_help {
    my ($self) = @_;

    $self->{help} = Wx::HtmlHelpController->new(
        wxHF_FLATTOOLBAR | wxHF_DEFAULTSTYLE );

    my $cfg = QDepo::Config->instance();

    my $htb_file = $cfg->get_resource_file('help','htmlhelp.htb');

    $self->{help}->AddBook( $htb_file, 1 );
    $self->{help}->DisplayContents;

    return;
}

1;

=head2 new

Constructor method

=head2 show_html_help

Show guide.

=cut
