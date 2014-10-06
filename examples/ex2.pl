#!/usr/bin/perl
BEGIN { push @INC,"/opt/ot98/libs/Perl5" } 
use CSV::Lite qw(csvPrint);
csvPrint(
 {'delim'=>':::','quote'=>"'"},
 [["Surname","Name","Height","Weight"],
  {"Name"=>"Andrey",
   "Surname"=>"Konovalov",
   "Birth"=>1984,
   "Sex"=>"M",
   "Weight"=>71,
   "Height"=>172},
 ]
) || die "Some error happens";
