#
# Borrowed and adapted from Sqitch v0.997 by @theory
#
use strict;
use warnings;
use 5.010;
use utf8;
use Test::More;
use Path::Class;
use Test::Exception;
use Locale::TextDomain qw(QDepo);
use QDepo;
use QDepo::Target;
use lib 't/lib';

my $CLASS;

BEGIN {
    $CLASS = 'QDepo::Engine';
    use_ok $CLASS or die;
    # $ENV{TRANSFER_CONFIG} = 'nonexistent.conf';
}

can_ok $CLASS, qw(load new name uri);
my $die = '';
ENGINE: {
    # Stub out a engine.
    package QDepo::Engine::whu;
    use Moose;
    extends 'QDepo::Engine';
    $INC{'App/QDepoDev/Engine/whu.pm'} = __FILE__;

    my @SEEN;
    for my $meth (qw(
        get_info
    )) {
        no strict 'refs';
        *$meth = sub {
            die 'AAAH!' if $die eq $meth;
            push @SEEN => [ $meth => $_[1] ];
        };
    }

    sub seen { [@SEEN] }
    after seen => sub { @SEEN = () };
}

##############################################################################
# Test new().
ok my $target = QDepo::Target->new(
    uri      => 'db:firebird:',
), 'new target instance';

throws_ok { $CLASS->new }
    qr/\QAttribute (target) is required/,
    'Should get an exception for missing target param';
lives_ok { $CLASS->new( target => $target ) }
    'Should get no exception';

isa_ok $CLASS->new( { target => $target } ), $CLASS,
    'Engine';

##############################################################################
# Test load().
ok $target = QDepo::Target->new(
    uri      => 'db:whu:',
), 'new whu target';
ok my $engine = $CLASS->load({
    target   => $target,
}), 'Load a "whu" engine';
isa_ok $engine, 'QDepo::Engine::whu';

# Try an unknown engine.
$target = QDepo::Target->new(
    uri      => 'db:nonexistent:',
);
throws_ok { $CLASS->load( { target => $target } ) }
    'QDepo::X', 'Should get error for unsupported engine';
is $@->message, 'Unable to load QDepo::Engine::nonexistent',
    'Should get load error message';

# Test handling of an invalid engine.
throws_ok { $CLASS->load({ engine => 'nonexistent', target => $target }) }
    'QDepo::X', 'Should die on invalid engine';
is $@->message, __('Unable to load QDepo::Engine::nonexistent'),
    'Should get load error message';

NOENGINE: {
    # Test handling of no target.
    throws_ok { $CLASS->load({}) } 'QDepo::X',
            'No target should die';
    is $@->message, 'Missing "target" parameter to load()',
        'It should be the expected message';
}

done_testing;
