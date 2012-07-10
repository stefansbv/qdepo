package TpdaQrt::Tk::Dialog::Login;

use strict;
use warnings;

use Tk;

require TpdaQrt::Config;

=head1 NAME

TpdaQrt::Tk::Dialog::Login - Dialog for user name and password

=head1 VERSION

Version 0.37

=cut

our $VERSION = 0.37;

=head1 SYNOPSIS

    use TpdaQrt::Tk::Dialog::Login;

    my $fd = TpdaQrt::Tk::Dialog::Login->new;

    $fd->login($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $type = shift;

    my $self = {};

    bless( $self, $type );

    return $self;
}

=head2 login

Show dialog

=cut

sub login {
    my ( $self, $mw ) = @_;

    $self->{bg}  = $mw->cget('-background');
    $self->{dlg} = $mw->DialogBox(
        -title   => 'Login',
        -buttons => [qw/Accept Cancel/],
    );

    #- Frame

    my $frame = $self->{dlg}->LabFrame(
        -foreground => 'blue',
        -label      => 'Login',
        -labelside  => 'acrosstop',
    );
    $frame->pack(
        -padx  => 10,
        -pady  => 10,
        -ipadx => 5,
        -ipady => 5,
    );

    #-- User

    my $luser = $frame->Label( -text => 'User:', );
    $luser->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );
    my $euser = $frame->Entry(
        -width              => 30,
        -background         => 'white',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $euser->form(
        -top  => [ '&', $luser, 0 ],
        -left => [ %0,  90 ],
    );

    #-- Pass

    my $lpass = $frame->Label( -text => 'Password:', );
    $lpass->form(
        -top     => [ $luser, 8 ],
        -left    => [ %0,     0 ],
        -padleft => 5,
    );
    my $epass = $frame->Entry(
        -width              => 30,
        -background         => 'white',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
        -show               => '*',
    );
    $epass->form(
        -top  => [ '&', $lpass, 0 ],
        -left => [ %0,  90 ],
    );

    $euser->focus;

    my $cfg = TpdaQrt::Config->instance();

    # User from parameter
    if ( $cfg->user ) {
        $euser->delete( 0, 'end' );
        $euser->insert( 0, $cfg->user );
        $euser->xview('end');
        $epass->focus;
    }

    my $answer = $self->{dlg}->Show();
    my $return_string = '';

    if ( $answer eq 'Accept' ) {
        my $user = $euser->get;
        my $pass = $epass->get;

        if ( $user && $pass ) {
            my $cfg = TpdaQrt::Config->instance();
            $cfg->user($user);
            $cfg->pass($pass);
        }
        else {
            $return_string = 'else';
        }
    }
    else {
        $return_string = 'shutdown';
    }

    return $return_string;
}

1;    # End of TpdaQrt::Tk::Dialog::Login
