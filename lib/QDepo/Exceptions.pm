package QDepo::Exceptions;

# ABSTRACT: The QDepo Exceptions

use strict;
use warnings;

use Exception::Base
    'Exception::Db',
    'Exception::Db::Connect' => {
        isa               => 'Exception::Db',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg logmsg )],
    },
    'Exception::Db::Connect::Auth' => {
        isa               => 'Exception::Db::Connect',
    },
    'Exception::Db::SQL' => {
        isa               => 'Exception::Db',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg logmsg )],
    },
    'Exception::Db::SQL::Parser' => {
        isa               => 'Exception::Db::SQL',
    },
    'Exception::IO',
    'Exception::IO::PathNotFound' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::PathExists' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::FileNotFound' => {
        isa               => 'Exception::IO',
        has               => [qw( filename )],
        string_attributes => [qw( message filename )],
    };

1;
