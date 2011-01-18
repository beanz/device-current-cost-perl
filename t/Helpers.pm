package t::Helpers;

=head1 NAME

t::Helpers - Perl extension for Helper functions for tests.

=head1 SYNOPSIS

  use Test::More tests => 2;
  use t::Helpers qw/:all/;
  is(test_error(sub { die 'argh' }),
     'argh',
     'died horribly');

  is(test_warn(sub { warn 'danger will robinson' }),
     'danger will robinson',
     'warned nicely');

=head1 DESCRIPTION

Common functions to make test scripts a bit easier to read.  There are
CPAN modules to do this sort of thing, but most people wont have them
installed and they are pretty trivial functions so to encourage
testing they are included here.

=cut

use 5.006;
use strict;
use warnings;

use Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
                                    test_error
                                    test_warn
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = 0.1;

=head2 C<test_error($code_ref)>

This method runs the code with eval and returns the error.  It strips
off some common strings from the end of the message including any "at
<file> line <number>" strings and any "(@INC contains: .*)".

=cut

sub test_error {
  my $sub = shift;
  eval { $sub->() };
  my $error = $@;
  if ($error) {
    $error =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $error =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $error =~ s/ \(\@INC contains:.*?\)$//;
  }
  return $error;
}

=head2 C<test_warn($code_ref)>

This method runs the code with eval and returns the warning.  It strips
off any "at <file> line <number>" specific part(s) from the end.

=cut

sub test_warn {
  my $sub = shift;
  my $warn;
  local $SIG{__WARN__} = sub { $warn .= $_[0]; };
  eval { $sub->(); };
  die $@ if ($@);
  if ($warn) {
    $warn =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $warn =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $warn =~ s/ \(\@INC contains:.*?\)$//;
  }
  return $warn;
}

1;
