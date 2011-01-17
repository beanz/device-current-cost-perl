#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_CURRENT_COST_TEST_DEBUG}
};
use Test::More tests => 3;
use lib 't/lib';

$|=1;
use_ok('Device::CurrentCost');
BEGIN { use_ok('Device::CurrentCost::Constants'); }

my $dev = Device::CurrentCost->new(device => 't/log/envy.reading.xml');
$dev->_termios_config($dev->filehandle);
is_deeply([POSIX::Termios->calls],
          [
           'POSIX::Termios::getattr 3',
           'POSIX::Termios::getlflag ',
           'POSIX::Termios::setlflag 0',
           'POSIX::Termios::setcflag 15',
           'POSIX::Termios::setiflag 3',
           'POSIX::Termios::setospeed 4097',
           'POSIX::Termios::setispeed 4097',
           'POSIX::Termios::setattr 3 1',
          ], 'POSIX calls');
