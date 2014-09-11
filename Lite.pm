#!/usr/bin/perl
package CSV::Lite;
use utf8;
use strict;

use Exporter qw(import);
our @EXPORT_OK=qw(csvLine);

sub csvLine {
 my ($csvSep,$csvQuo)=map {substr($_,0,1)} (shift,shift);
 return join($csvSep,map { 
                           length($_)==0 || /^[0-9]+(?:\.[0-9]+)?$/
                           ?
                            $_
                           :
                            do { 
                             my $q=$csvQuo; 
                             (my $t=$_)=~s/$q/${q}${q}/og; 
                             $q.$t.$q 
                            }
                         } map { ref($_) eq 'ARRAY'?@{$_}:$_ } @_
                  );
}                  

1;
