#!/usr/bin/perl
package CSV::Lite;
use utf8;
use strict;

use Exporter qw(import);
our @EXPORT_OK=qw(csvLine csvPrint);

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

sub csvPrint {
 my $pars=ref($_[0]) eq 'HASH'?shift:{};
 my ($to,$from)=(shift,shift);
 my ($WriteTo,$fh)=('FILE',*STDOUT);
 if ((ref($to) eq 'ARRAY') and ! $from) {
  $from=$to;
  $to=[];
 } elsif ( ref($to) eq 'ARRAY' and ! $from and wantarray() ) {
  $from=$to;
  $to=[];
  $WriteTo='LIST_ON_RET';
 } elsif ( (ref($to) eq 'GLOB') and (ref($from) eq 'ARRAY') ) {
  $fh=$to;
  $to=[];
 } elsif ($to and ! ref($to) and (ref($from) eq 'ARRAY') ) {
  open($fh,'>',$to);
  $to=[];
 } elsif ( !((ref($to) eq 'ARRAY') and (ref($from) eq 'ARRAY')) ) {
  return 0;
 }
 
 if (ref($from->[0]) eq 'HASH' or ref($from->[1]) eq 'HASH') {
  my @keySeq;
  if (ref($pars->{'fields'}) eq 'ARRAY') {
   @keySeq=@{$pars->{'fields'}};
  } elsif ( ref($from->[0]) eq 'HASH' ) {
   @keySeq=sort keys $from->[0];
  } elsif (ref($from->[0]) eq 'ARRAY' and ref($from->[1]) eq 'HASH') {
   @keySeq=@{$from->[0]};
  } else {
   return 0;
  }
  @{$to}=map { csvLine(',','"',[@{$_}{@keySeq}])} @$from;
 } else {
  @{$to}=map { csvLine(',','"',$_) } @$from;
 }

 if ($WriteTo eq 'FILE') {
  print $fh join("\n",@{$to})."\n";
 } elsif ($WriteTo eq 'LIST_ON_RET') {
  return @{$to};
 } else {
  return 1;
 }
}

1;
