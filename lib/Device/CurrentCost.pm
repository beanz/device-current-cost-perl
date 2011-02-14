use strict;
use warnings;
package Device::CurrentCost;

# ABSTRACT: Perl modules for Current Cost energy monitors

=head1 SYNOPSIS

  use Device::CurrentCost;
  my $envy = Device::CurrentCost->new(device => '/dev/ttyUSB0');

  $|=1; # don't buffer output

  while (1) {
    my $msg = $envy->read() or next;
    print $msg->summary, "\n";
  }

  use Device::CurrentCost::Constants;
  my $classic = Device::CurrentCost->new(device => '/dev/ttyUSB1',
                                         type => CURRENT_COST_CLASSIC);
  ...

  open my $cclog, '<', 'currentcost.log' or die $!;
  my $cc = Device::CurrentCost->new(filehandle => $cclog);

  while (1) {
    my $msg = $cc->read() or next;
    print $msg->summary, "\n";
  }

=head1 DESCRIPTION

Module for reading from Current Cost energy meters.

B<IMPORTANT:> This is an early release and the API is still subject to
change.

The API for history is definitely not complete.  This will change soon
and an mechanism for aggregating the history (which is split across
many messages) should be added.

=cut

use constant {
  DEBUG => $ENV{DEVICE_CURRENT_COST_DEBUG},
};

use Carp qw/croak carp/;
use Device::CurrentCost::Constants;
use Device::CurrentCost::Message;
use Fcntl;
use IO::Handle;
use IO::Select;
use POSIX qw/:termios_h/;
use Time::HiRes;

=method C<new(%parameters)>

This constructor returns a new Current Cost device object.  The
supported parameters are:

=over

=item device

The name of the device to connect to.  The value should be a tty
device name, e.g. C</dev/ttyUSB0> but a pipe or plain file should also
work.  This parameter is mandatory if B<filehandle> is not given.

=item filehandle

A filehandle to read from.  This parameter is mandatory if B<device> is
not given.

=item type

The type of the device.  Currently either C<CURRENT_COST_CLASSIC> or
C<CURRENT_COST_ENVY>.  The default is C<CURRENT_COST_ENVY>.

=item baud

The baud rate for the device.  The default is derived from the type and
is either C<57600> (for Envy) or C<9600> (for classic).

=back

=cut

sub new {
  my ($pkg, %p) = @_;
  my $self = bless {
                    buf => '',
                    discard_timeout => 1,
                    type => CURRENT_COST_ENVY,
                    %p
                   }, $pkg;
  unless (exists $p{filehandle}) {
    croak $pkg.q{->new: 'device' parameter is required}
      unless (exists $p{device});
    $self->open();
  }
  $self;
}

=method C<device()>

Returns the path to the device.

=cut

sub device { shift->{device} }

=method C<type()>

Returns the type of the device.

=cut

sub type { shift->{type} }

=method C<baud()>

Returns the baud rate.

=cut

sub baud {
  my $self = shift;
  defined $self->{baud} ? $self->{baud} :
    $self->type == CURRENT_COST_CLASSIC ? 9600 : 57600;
}

=method C<posix_baud()>

Returns the baud rate in L<POSIX#Termios> format.

=cut

sub posix_baud {
  my $self = shift;
  my $baud = $self->baud;
  my $b;
  if ($baud == 57600) {
    $b = 0010001; ## no critic
  } else {
    eval qq/\$b = \&POSIX::B$baud/; ## no critic
    die "Unsupported baud rate: $baud\n" if ($@);
  }
  $b;
}

=method C<filehandle()>

Returns the filehandle being used to read from the device.

=cut

sub filehandle { shift->{filehandle} }

=method C<open()>

This method opens the serial port and configures it.

=cut

sub open {
  my $self = shift;
  my $dev = $self->device;
  print STDERR 'Opening serial port: ', $dev, "\n" if DEBUG;
  my $flags = O_RDWR;
  eval { $flags |= O_NOCTTY }; # ignore undefined error
  eval { $flags |= O_NDELAY }; # ignore undefined error
  sysopen my $fh, $dev, $flags
    or croak "sysopen of '$dev' failed: $!";
  $fh->autoflush(1);
  binmode($fh);
  if (-c $fh) {
    $self->_termios_config($fh);
  }
  return $self->{filehandle} = $fh;
}

sub _termios_config {
  my ($self, $fh) = @_;
  my $fd = fileno($fh);
  my $termios = POSIX::Termios->new;
  $termios->getattr($fd) or die "POSIX::Termios->getattr(...) failed: $!\n";
  my $lflag = $termios->getlflag();
  $lflag &= ~(POSIX::ECHO | POSIX::ECHOK | POSIX::ICANON);
  $termios->setlflag($lflag);
  $termios->setcflag(POSIX::CS8 | POSIX::CREAD |
                     POSIX::CLOCAL | POSIX::HUPCL);
  $termios->setiflag(POSIX::IGNBRK | POSIX::IGNPAR);
  my $baud = $self->posix_baud;
  $termios->setospeed($baud)
    or die "POSIX::Termios->setospeed(...) failed: $!\n";
  $termios->setispeed($baud)
    or die "POSIX::Termios->setospeed(...) failed: $!\n";
  $termios->setattr($fd, POSIX::TCSANOW)
    or die "POSIX::Termios->setattr(...) failed: $!\n";
}

=method C<read($timeout)>

This method blocks until a new message has been received by the
device.  When a message is received a data structure is returned
that represents the data received.

B<IMPORTANT:> This API is still subject to change.

=cut

sub read {
  my ($self, $timeout) = @_;
  my $res = $self->read_one(\$self->{buf});
  return $res if (defined $res);
  $self->_discard_buffer_check();
  my $fh = $self->filehandle;
  my $sel = IO::Select->new($fh);
  do {
    my $start = $self->_time_now;
    $sel->can_read($timeout) or return;
    my $bytes = sysread $fh, $self->{buf}, 2048, length $self->{buf};
    $self->{_last_read} = $self->_time_now;
    $timeout -= $self->{_last_read} - $start if (defined $timeout);
    unless ($bytes) {
      croak((ref $self).'->read: '.(defined $bytes ? 'closed' : 'error: '.$!));
    }
    $res = $self->read_one(\$self->{buf});
    return $res if (defined $res);
  } while (1);
}

=method C<read_one(\$buffer)>

This method attempts to remove a single Current Cost message from the
buffer passed in via the scalar reference.  When a message is removed
a data structure is returned that represents the data received.  If
insufficient data is available then undef is returned.

B<IMPORTANT:> This API is still subject to change.

=cut

sub read_one {
  my ($self, $rbuf) = @_;
  return unless ($$rbuf);
  if ($$rbuf =~ s!^\s*(<msg>.*?</msg>)\s*!!) {
    return Device::CurrentCost::Message->new(message => $1);
  } else {
    return;
  }
}

sub _discard_buffer_check {
  my $self = shift;
  if ($self->{buf} ne '' &&
      $self->{_last_read} < ($self->_time_now - $self->{discard_timeout})) {
    $self->{buf} = '';
  }
}

sub _time_now {
  Time::HiRes::time;
}

1;
