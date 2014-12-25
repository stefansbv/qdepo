package QDepo::Wx::ListCtrl;

# ABSTRACT: Virtual List Control

use strict;
use warnings;

use Wx;
use Wx qw(:listctrl);

use base qw(Wx::ListView);

sub new {
    my ( $class, $parent, $dt ) = @_;
    my $self = $class->SUPER::new(
        $parent, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxLC_REPORT | wxLC_VIRTUAL | wxLC_SINGLE_SEL
    );
    $self->SetItemCount( $dt->get_item_count );
    $self->{dt} = $dt;
    $self->add_columns;
    return $self;
}

sub add_columns {
    my ( $self, $header ) = @_;
    my $cnt = 0;
    foreach my $rec ( @{$header} ) {
        my $label = $rec->{label};
        my $width = $rec->{width};
        my $align
            = $rec->{align} eq 'left'   ? wxLIST_FORMAT_LEFT
            : $rec->{align} eq 'center' ? wxLIST_FORMAT_CENTER
            : $rec->{align} eq 'right'  ? wxLIST_FORMAT_RIGHT
            :                             wxLIST_FORMAT_LEFT;
        $self->InsertColumn( $cnt, $label, $align, $width );
        $cnt++;
    }
    return;
}

sub OnGetItemText {
    my ( $self, $item, $column ) = @_;
    return $self->{dt}->get_value( $item, $column );
}

sub OnGetItemAttr {
    my ( $self, $item ) = @_;
    my $attr = Wx::ListItemAttr->new;
    $attr->SetBackgroundColour( Wx::Colour->new('LIGHT YELLOW') )
        if $item % 2 == 0;
    return $attr;
}

sub RefreshList {
    my $self       = shift;
    my $item_count = $self->{dt}->get_item_count;
    $self->SetItemCount($item_count);
    $self->RefreshItems( 0, $item_count );
    return;
}

sub get_selection {
    my $self = shift;
    return $self->GetFirstSelected;
}

sub set_selection {
    my ( $self, $item ) = @_;
    $self->Select( $item, 1 );
    return;
}

1;

=head1 ACKNOWLEDGMENTS

The Wx::DemoModules::wxListCtrl::Virtual package from the Wx::Demo application,
with small changes to add external data items.

