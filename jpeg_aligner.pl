#!/usr/bin/perl
# Copyright (c) Volodymyr Kleban

use Image::MetaData::JPEG;
use Time::Local;
use POSIX 'strftime';
use Data::Dumper;

use strict;

# By how many seconds the camera is ahead of real time
my %camera_shift_seconds_map = (
  'samsung_SM-G900H' => 0,
  'Apple_iPhone_4' => 0,
  'Apple_iPhone_7' => 0,
  'Canon_EOS_DIGITAL_REBEL_XSi' => -17680,
  'LGE_Nexus_4' => 0,
  'OnePlus_A3000' => 0,
  'OnePlus_A5000' => 0,
  'Panasonic_DMC-ZS100' => 588
);

#-------------------------------------------------------------------------------
# print string
#-------------------------------------------------------------------------------
sub debug($) {
#  print shift;
}

#-------------------------------------------------------------------------------
# dump variable
#-------------------------------------------------------------------------------
sub debug_dump($) {
#  print Dumper shift;
}

#-------------------------------------------------------------------------------
# get epoch time of when the image was taken according to the camera
# args:   JPEG object
# return: epoch time given in the pic
#-------------------------------------------------------------------------------
sub getEpoch($)
{
  my $image= shift;
  debug_dump($image->get_Exif_data('IMAGE_DATA'));
  my $time_string= $image->get_Exif_data('IMAGE_DATA')->{'DateTimeOriginal'}[0];
  debug( "Metadata module date: $time_string\n" );
  my ($year, $month, $date, $hour, $minute, $second);
  # 2017:03:29 00:19:14
  if (my ($year, $month, $date, $hour, $minute, $second) =
        $time_string =~ /(\d+)\D(\d+)\D(\d+)\D(\d+)\D(\d+)\D(\d+)/)
  {
    $month--;
    return timelocal($second, $minute, $hour, $date, $month, $year);
  }
  return -1;
}

#-------------------------------------------------------------------------------
# return: make_model string of the camera that produced given image
#-------------------------------------------------------------------------------
sub getMakeModel($)
{
  my $image = shift;
  my $exif= $image->get_Exif_data('IMAGE_DATA');
  my $make= $exif->{'Make'}[0];
  my $model= $exif->{'Model'}[0];
  $make =~ s/[^[:print:]]//g;
  $make =~ s/[\s]/_/g;
  $model =~ s/[^[:print:]]//g;
  $model =~ s/[\s]/_/g;
  if (length($make) >= 2)
  {
    my $make_in_model_index= index(lc($model), lc($make));
    if ($make_in_model_index >= 0)
    {
      $model= substr($model, $make_in_model_index + length($make) + 1);
    }
  }
  my $make_model= "${make}_${model}";
  return $make_model;
}

#-------------------------------------------------------------------------------
# get epoch shift in seconds for this make_model of the camera
# args:   JPEG object
# return: number of seconds the camera differs from real time
#-------------------------------------------------------------------------------
sub makeModelShift($)
{
  my $image = shift;
  my $make_model = getMakeModel($image);
  if (defined $camera_shift_seconds_map{$make_model})
  {
    return $camera_shift_seconds_map{$make_model};
  }
  else
  {
    print "Failed finding camera '$make_model' on my list! Assuming 0 time shift\n";
    return 0;
  }

}
#-------------------------------------------------------------------------------
# return: usage string
#-------------------------------------------------------------------------------
sub usage()
{
  return "\nPlease update \"camera_shift_seconds_map\" variable\nThen run: \"perl $0 <source path> <destination path>\" to convert pictures\n";
}

################################################################################
# MAIN
################################################################################

if ($#ARGV <= 0)
{
  print STDERR usage();
  exit 1;
}

my $dir= $ARGV[0];
my $dest_dir= $ARGV[1];

opendir(my $dh, $dir) || die "Can't opendir \"$dir:\" for reading: $!";
opendir(my $dh2, $dest_dir) || die "Can't opendir \"$dest_dir\" for writing: $!";
my @jpegs = grep { /\.(jpg|jpeg)/i && -f "$dir/$_" } readdir($dh);
for my $jpeg (@jpegs)
{
  my $full_path= "$dir/$jpeg";
  my $image= new Image::MetaData::JPEG( $full_path );
  die 'Error: ' . Image::MetaData::JPEG::Error() unless $image;
  print "Found: \"$jpeg\"\n";
  my $claimed_epoch= getEpoch($image);
  my $recorded_diff= makeModelShift($image);
  print "Its epoch is " . $claimed_epoch . "\n";
  print "Its shift is " . $recorded_diff . "\n";
  my $date_string= strftime('%Y%m%d_%H%M%S', localtime($claimed_epoch - $recorded_diff));
  print "Calculated date_time: $date_string\n";
  my $new_name= $date_string . "_" . getMakeModel($image) . ".jpg";
  print "Renaming \"$jpeg\" into \"$new_name\"\n";
  link($full_path, "$dest_dir/$new_name");
}
closedir $dh;
closedir $dh2;


