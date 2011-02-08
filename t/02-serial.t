#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_CURRENT_COST_TEST_DEBUG}
};
use Test::More tests => 10;
use lib 't/lib';

$|=1;
use_ok('Device::CurrentCost');
BEGIN { use_ok('Device::CurrentCost::Constants'); }

my $dev = Device::CurrentCost->new(device => 't/log/envy.reading.xml');
my $fh = $dev->filehandle;
my $fd = $fh->fileno;
$dev->_termios_config($fh);
my @calls = POSIX::Termios->calls;
foreach my $exp ('POSIX::Termios::getattr '.$fd,
                 'POSIX::Termios::getlflag ',
                 'POSIX::Termios::setlflag 0',
                 'POSIX::Termios::setcflag 15',
                 'POSIX::Termios::setiflag 3',
                 'POSIX::Termios::setospeed 4097',
                 'POSIX::Termios::setispeed 4097',
                 'POSIX::Termios::setattr '.$fd.' 1',
                ) {
  my $got = shift @calls;
  is($got, $exp, 'POSIX calls - '.$exp);
}
