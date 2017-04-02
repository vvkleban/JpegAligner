#!/usr/bin/perl

use Image::MetaData::JPEG;
use Time::Local;
use String::Escape qw( printable unprintable );
use Data::Dumper;

use strict;

my %camera_shift_seconds_map = (
  'samsung\\00_SM-G900H\\00' => 0
);

#-------------------------------------------------------------------------------
# print string
#-------------------------------------------------------------------------------
sub debug($) {
  print shift;
}

#-------------------------------------------------------------------------------
# dump variable
#-------------------------------------------------------------------------------
sub debug_dump($) {
  print Dumper shift;
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
  my $time_string= $image->get_Exif_data('IMAGE_DATA')->{'DateTime'}[0];
  debug( "$time_string\n" );
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
# get epoch shift in seconds for this make_model of the camera
# args:   JPEG object
# return: seconds to shift the epoch by
#-------------------------------------------------------------------------------
sub makeModelShift($)
{
  my $image = shift;
  my $exif= $image->get_Exif_data('IMAGE_DATA');
  my $make= $exif->{'Make'}[0];
  my $model= $exif->{'Model'}[0];
  my $make_model= printable("${make}_${model}");
  if (defined $camera_shift_seconds_map{$make_model})
  {
    #debug "defined to be " . $camera_shift_seconds_map{$make_model} . " seconds\n";
    return $camera_shift_seconds_map{$make_model};
  }
  else
  {
    print "Failed finding camera '$make_model' on my list!\n";
  }

}

my $image = new Image::MetaData::JPEG('/media/raid5/pictures/2017-03-26 New Orleans/20170326_124504.jpg');
die 'Error: ' . Image::MetaData::JPEG::Error() unless $image;


print getEpoch($image) . "\n";
print makeModelShift($image) . "\n";
