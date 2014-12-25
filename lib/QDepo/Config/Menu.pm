package QDepo::Config::Menu;

# ABSTRACT: Data store for menu

use Mouse;
use Locale::TextDomain 1.20 qw(QDepo);

has 'menu_names' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        return [ 'menu_app', 'menu_help', ],
    },
    handles => {
        all_menus => 'elements',
    },
);

has 'menu' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return {   'menu_app' => {
                'id'        => '5001',
                'label'     => __ 'App',
                'underline' => 0,
                'popup'     => {
                    '1' => {
                        'name'      => 'mn_qt',
                        'label'     => __ 'Quit',
                        'underline' => '1',
                        'key'       => 'Ctrl+Q',
                        'sep'       => 'before',
                    },
                },
            },
            'menu_help' => {
                'id'        => '5009',
                'label'     => __ 'Help',
                'underline' => 0,
                'popup'     => {
                    '1' => {
                        'name'      => 'mn_gd',
                        'label'     => __ 'Manual',
                        'underline' => 0,
                        'key'       => undef,
                        'sep'       => 'none',
                    },
                    '2' => {
                        'name'      => 'mn_ab',
                        'label'     => __ 'About',
                        'underline' => 0,
                        'key'       => undef,
                        'sep'       => 'none',
                    }
                },
            },
        };
    },
    handles => {
        ids_in_menu    => 'keys',
        get_menu       => 'get',
    },
);

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
