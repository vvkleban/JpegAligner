#!/usr/bin/perl

use Image::MetaData::JPEG;

use strict;

my $image = new Image::MetaData::JPEG('/media/raid5/pictures/2017-03-26 New Orleans/P1060114.JPG');
die 'Error: ' . Image::MetaData::JPEG::Error() unless $image;

my $textual_exif= $image->get_Exif_data('IMAGE_DATA');

use Data::Dumper;

print Dumper $textual_exif;

