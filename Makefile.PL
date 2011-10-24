
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl modules for Current Cost energy monitors',
  'AUTHOR' => 'Mark Hindess <soft-cpan@temporalanomaly.com>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'IO::Pipe' => '0',
    'Test::More' => '0',
    'Test::Requires' => '0',
    'Test::SharedFork' => '0',
    'Test::Warn' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Device-CurrentCost',
  'EXE_FILES' => [
    'bin/current-cost-reader'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Device::CurrentCost',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Fcntl' => '0',
    'Getopt::Long' => '0',
    'IO::Handle' => '0',
    'IO::Select' => '0',
    'List::Util' => '0',
    'POSIX' => '0',
    'Pod::Usage' => '0',
    'Time::HiRes' => '0',
    'constant' => '0'
  },
  'VERSION' => '1.112970',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



