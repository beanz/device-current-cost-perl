use strict;
use warnings;
package Device::CurrentCost::Constants;

# ABSTRACT: Module to export constants for Current Cost devices

=head1 SYNOPSIS

  use Device::CurrentCost::Constants;

=head1 DESCRIPTION

Module to export constants for Current Cost devices

=cut

my %constants =
  (
   CURRENT_COST_CLASSIC => 0x1,
   CURRENT_COST_ENVY => 0x2,
  );
my %names =
  (
   $constants{CURRENT_COST_ENVY} => 'Envy',
   $constants{CURRENT_COST_CLASSIC} => 'Classic',
  );

sub import {
  no strict qw/refs/; ## no critic
  my $pkg = caller(0);
  foreach (keys %constants) {
    my $v = $constants{$_};
    *{$pkg.'::'.$_} = sub () { $v };
  }
  foreach (qw/current_cost_type_string/) {
    *{$pkg.'::'.$_} = \&{$_};
  }
}

=head1 C<FUNCTIONS>

=head2 C<current_cost_type_string( $type )>

Returns a string describing the given Current Cost device type.

=cut

sub current_cost_type_string {
  $names{$_[0]}
}
