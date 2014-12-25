package QDepo::Utils;

# ABSTRACT: Various utility functions

use strict;
use warnings;
use Encode qw(is_utf8 decode);

sub trim {
    my ( $self, @text ) = @_;
    for (@text) {
        s{\A \s* | \s* \z}{}gmx;
    }
    return wantarray ? @text : "@text";
}

sub sort_hash_by {
    my ( $self, $key, $attribs ) = @_;

    #-- Sort by id
    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{$key} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return \@attribs;
}

sub params_to_hash {
    my ( $self, $params ) = @_;

    my $parameters;
    foreach my $parameter ( @{ $params->{parameter} } ) {
        my $id = $parameter->{id};
        if ($id) {
            $parameters->{"value$id"} = $parameter->{value};
            $parameters->{"descr$id"} = $parameter->{descr};
        }
    }

    return $parameters;
}

sub transform_data {
    my ( $self, $record_aref ) = @_;
    my $rec;
    foreach my $item ( @{$record_aref} ) {
        while ( my ( $key, $value ) = each( %{$item} ) ) {
            $rec->{$key} = $value;
        }
    }
    return $rec;
}

sub transform_para {
    my ( $self, $record_aref ) = @_;
    my ( @aoh, $rec );
    foreach my $item ( @{$record_aref} ) {
        while ( my ( $key, $value ) = each( %{$item} ) ) {
            if ( $key =~ m{descr([0-9])}x ) {
                $rec = {};                # new record
                $rec->{descr} = $value;
            }
            if ( $key =~ m{value([0-9])}x ) {
                $rec->{id}    = $1;
                $rec->{value} = $value;
                push( @aoh, $rec );
            }
        }
    }
    return \@aoh;
}

sub ins_underline_mark {
    my ( $self, $label, $position ) = @_;
    substr( $label, $position, 0, '&' );
    return $label;
}

sub decode_unless_utf {
    my ( $self, $value ) = @_;
    $value = decode( 'utf8', $value ) unless is_utf8($value);
    return $value;
}

1;

=head1 SYNOPSIS

    use QDepo::Utils;

    my $foo = QDepo::Utils->function_name();

=head2 trim

Trim strings or arrays.

=head2 sort_hash_by_id

Use ST to sort hash by value (Id), returns an array ref of the sorted items.

=head2 params_to_hash

Transform data in simple hash reference format

TODO: Move this to model?

=head2 transform_data

Transform data to be suitable to save in XML format

=head2 transform_para

Transform parameters data to AoH, to be suitable to save in XML format.

From:       {          'descr1' => 'Parameter1',          'descr2' =>
'Parameter2',          'value1' => 'default1',          'value2' => 'default2' 
     };

To:      [        {          'value' => 'default1',          'id' => '1',      
   'descr' => 'Parameter1'        },        {          'value' => 'default2',  
       'id' => '2',          'descr' => 'Parameter2'        }      ];

=head2 ins_underline_mark

Insert ampersand character for underline mark in menu.

=cut
