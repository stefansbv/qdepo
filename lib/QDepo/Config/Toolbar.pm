package QDepo::Config::Toolbar;

# ABSTRACT: Data store for toolbar

use Mouse;
use Locale::TextDomain 1.20 qw(QDepo);
use namespace::autoclean;

has 'toolnames' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [ 'tb_ed', 'tb_sv', 'tb_ad', 'tb_rm', 'tb_ls', 'tb_go',
          'tb_qt' ],
        },
    handles => {
        all_buttons => 'elements',
    },
);

has 'tool' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {   'tb_go' => {
                'tooltip' => 'Run',
                'icon'    => 'navforward16',
                'sep'     => 'after',
                'help'    => 'Execute query',
                'type'    => '_item_normal',
                'id'      => '1006',
                'state'   => {
                    'edit' => 'disabled',
                    'idle' => 'disabled',
                    'sele' => 'normal'
                }
            },
            'tb_ad' => {
                'tooltip' => 'Add query',
                'icon'    => 'actitemadd16',
                'sep'     => 'none',
                'help'    => 'Create new query definition file',
                'type'    => '_item_normal',
                'id'      => '1003',
                'state'   => {
                    'edit' => 'disabled',
                    'idle' => 'normal',
                    'sele' => 'normal'
                }
            },
            'tb_ls' => {
                'sep'   => 'after',
                'type'  => '_item_list',
                'id'    => '1005',
                'state' => {
                    'edit' => 'disabled',
                    'idle' => 'disabled',
                    'sele' => 'normal'
                }
            },
            'tb_qt' => {
                'tooltip' => 'Quit',
                'icon'    => 'actexit16',
                'sep'     => 'none',
                'help'    => 'Quit the application',
                'type'    => '_item_normal',
                'id'      => '1007',
                'state'   => {
                    'edit' => 'disabled',
                    'idle' => 'normal',
                    'sele' => 'normal'
                }
            },
            'tb_rm' => {
                'tooltip' => 'Remove query',
                'icon'    => 'actitemdelete16',
                'sep'     => 'after',
                'help'    => 'Remove query definition file',
                'type'    => '_item_normal',
                'id'      => '1004',
                'state'   => {
                    'edit' => 'disabled',
                    'idle' => 'disabled',
                    'sele' => 'normal'
                }
            },
            'tb_sv' => {
                'tooltip' => 'Save metadata',
                'icon'    => 'filesave16',
                'sep'     => 'after',
                'help'    => 'Save query definition file',
                'type'    => '_item_normal',
                'id'      => '1002',
                'state'   => {
                    'edit' => 'normal',
                    'idle' => 'disabled',
                    'sele' => 'disabled'
                }
            },
            'tb_ed' => {
                'tooltip' => 'Edit metadata',
                'icon'    => 'edit16',
                'sep'     => 'none',
                'help'    => 'Edit mode on/off',
                'type'    => '_item_check',
                'id'      => '1001',
                'state'   => {
                    'edit' => 'normal',
                    'idle' => 'disabled',
                    'sele' => 'normal'
                }
            }
        };
    },
    handles => {
        ids_in_tool => 'keys',
        get_tool    => 'get',
    },
);

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
