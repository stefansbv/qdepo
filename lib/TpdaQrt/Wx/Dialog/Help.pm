package TpdaQrt::Wx::Dialog::Help;

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

=head2 new

Constructor method

=cut

    my $class = shift;

    my $self = {};

    return bless( $self, $class );
}

=head2 show_html_help

Show guide.

=cut

sub show_html_help {
    my ($self) = @_;

    $self->{help} = Wx::HtmlHelpController->new(
        wxHF_FLATTOOLBAR | wxHF_DEFAULTSTYLE );

    my $cfg = TpdaQrt::Config->instance();

    my $htb_file = $cfg->get_help_file('guide.htb');

    $self->{help}->AddBook( $htb_file, 1 );
    $self->{help}->DisplayContents;

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>.

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Wx::Dialog::Help
