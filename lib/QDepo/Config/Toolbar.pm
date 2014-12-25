package QDepo::Config::Toolbar;

# ABSTRACT: Data store for toolbar

use Mouse;
use Locale::TextDomain 1.20 qw(QDepo);

has 'toolnames' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        return [ 'tb_ed', 'tb_sv', 'tb_ad', 'tb_rm', 'tb_ls', 'tb_go', 'tb_qt' ],
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
        return {   'tb_go' => {
                'tooltip' => __ 'Run',
                'icon'    => 'navforward16',
                'sep'     => 'after',
                'help'    => __ 'Execute query',
                'type'    => '_item_normal',
                'id'      => '1006',
                'state'   => {
                    'edit'  => 'disabled',
                    'idle'  => 'disabled',
                    'sele'  => 'normal',
                    'admin' => 'disabled',
                }
            },
            'tb_ad' => {
                'tooltip' => __ 'Add query',
                'icon'    => 'actitemadd16',
                'sep'     => 'none',
                'help'    => __ 'Create new qdf file',
                'type'    => '_item_normal',
                'id'      => '1003',
                'state'   => {
                    'edit'  => 'disabled',
                    'idle'  => 'normal',
                    'sele'  => 'normal',
                    'admin' => 'disabled',
                }
            },
            'tb_ls' => {
                'sep'   => 'after',
                'type'  => '_item_list',
                'id'    => '1005',
                'state' => {
                    'edit'  => 'disabled',
                    'idle'  => 'disabled',
                    'sele'  => 'normal',
                    'admin' => 'disabled',
                }
            },
            'tb_qt' => {
                'tooltip' => __ 'Quit',
                'icon'    => 'actexit16',
                'sep'     => 'none',
                'help'    => __ 'Quit the application',
                'type'    => '_item_normal',
                'id'      => '1007',
                'state'   => {
                    'edit'  => 'disabled',
                    'idle'  => 'normal',
                    'sele'  => 'normal',
                    'admin' => 'disabled',
                }
            },
            'tb_rm' => {
                'tooltip' => __ 'Remove query',
                'icon'    => 'actitemdelete16',
                'sep'     => 'after',
                'help'    => __ 'Remove the qdf file',
                'type'    => '_item_normal',
                'id'      => '1004',
                'state'   => {
                    'edit'  => 'disabled',
                    'idle'  => 'disabled',
                    'sele'  => 'normal',
                    'admin' => 'disabled',
                }
            },
            'tb_sv' => {
                'tooltip' => __ 'Save metadata',
                'icon'    => 'filesave16',
                'sep'     => 'after',
                'help'    => __ 'Save metadata',
                'type'    => '_item_normal',
                'id'      => '1002',
                'state'   => {
                    'edit'  => 'normal',
                    'idle'  => 'disabled',
                    'sele'  => 'disabled',
                    'admin' => 'disabled',
                }
            },
            'tb_ed' => {
                'tooltip' => __ 'Edit metadata',
                'icon'    => 'edit16',
                'sep'     => 'none',
                'help'    => __ 'Toggle edit mode',
                'type'    => '_item_check',
                'id'      => '1001',
                'state'   => {
                    'edit'  => 'normal',
                    'idle'  => 'disabled',
                    'sele'  => 'normal',
                    'admin' => 'disabled',
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
