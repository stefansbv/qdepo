package QDepo::Wx::App;

# ABSTRACT: Wx Perl application class

use strict;
use warnings;

use Wx q(:everything);
use base qw(Wx::App);

require QDepo::Wx::View;

sub create {
    my $self  = shift->new;
    my $model = shift;

    $self->{_view} = QDepo::Wx::View->new(
        $model, undef, -1, 'QDepo::wxPerl',
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_FRAME_STYLE,
    );

    # $self->{_view}->Show(1);

    return $self;
}

sub OnInit { return 1 }

1;

=head1 SYNOPSIS

    use QDepo::Wx::App;
    use QDepo::Wx::Controller;

    $gui = QDepo::Wx::App->create();

    $gui->MainLoop;

=head2 create

Constructor method.

=head2 OnInit

Override OnInit from WxPerl

=cut
