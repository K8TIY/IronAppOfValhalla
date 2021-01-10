#!/usr/bin/env perl

# This is a hack to make universal ARM64 and Intel versions of the
# libsndfile static libraries using pre-built Homebrew binaries.
# May require perlbrew or CPAN to grab the needed modules
# (in particular JSON::PP).

# TODO: is it possible to get versions for the same target as the IAoV
# Intel build target OS version? It would silence a lot of warnings and
# allow me to sleep a little better at night.

# Also TODO: maybe snag at least the libsndfile headers instead of relying
# on Homebrew.

use strict;
use warnings;
use JSON::PP;
#use Data::Dumper;
use File::Copy;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
use File::Path;

my $LIBRARY_FILENAMES = {'libsndfile' => ['libsndfile'],
                         'libogg' => ['libogg'],
                         'libvorbis' => ['libvorbis', 'libvorbisenc'],
                         'flac' => ['libFLAC'],
                         'opus' => ['libopus']};

my @libraries = @ARGV;
@libraries = keys %$LIBRARY_FILENAMES unless scalar @libraries;
mkdir 'universal_libraries' unless -d 'universal_libraries';

foreach my $library (@libraries)
{
  my $jsonpp = JSON::PP->new->ascii->pretty->allow_nonref;
  my $cmd = "curl -s https://formulae.brew.sh/api/formula/$library.json";
  my $out = `$cmd`;
  #print "$out\n";
  my $data = $jsonpp->decode($out);
  #print Dumper $data->{'bottle'}->{'stable'}->{'files'};
  foreach my $arch ('intel', 'arm')
  {
    my $key = ($arch eq 'intel')? 'mojave' : 'arm64_big_sur';
    my $url = $data->{'bottle'}->{'stable'}->{'files'}->{$key}->{'url'};
    die "Can't find $library URL for $arch" unless $url;
    my @components = split '/', $url;
    my $file = $components[-1];
    $cmd = "curl -Ls $url -o universal_libraries/$file";
    print BLUE "$cmd\n";
    `$cmd`;
    $cmd = "gunzip -c universal_libraries/$file | tar -C universal_libraries -xf -";
    print BLUE "$cmd\n";
    `$cmd`;
    my $lib_files = $LIBRARY_FILENAMES->{$library};
    foreach my $lib_file (@$lib_files)
    {
      $cmd = "find universal_libraries/$library -type f -name ". $lib_file. '.a';
      print BLUE "$cmd\n";
      my $paths = `$cmd`;
      #print GREEN "Find output: $paths\n";
      my @paths = split "\n", $paths;
      die "Can't find $lib_file.a for $arch" unless scalar @paths == 1;
      copy($paths[0], 'universal_libraries/'. $lib_file. '_'. $arch. '.a');
    }
    unlink "universal_libraries/$file";
    File::Path::remove_tree("universal_libraries/$library");
  }
  #File::Path::remove_tree("universal_libraries/$library");
  my $lib_files = $LIBRARY_FILENAMES->{$library};
  foreach my $lib_file (@$lib_files)
  {
    $cmd = 'lipo -create -output universal_libraries/'. $lib_file. '_universal.a'.
           ' universal_libraries/'. $lib_file. '_intel.a'.
           ' universal_libraries/'. $lib_file. '_arm.a';
    print BLUE "$cmd\n";
    `$cmd`;
    unlink('universal_libraries/'. $lib_file. '_intel.a');
    unlink('universal_libraries/'. $lib_file. '_arm.a');
  }
}
 
