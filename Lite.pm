#!/usr/bin/perl
package CSV::Lite;
use utf8;
use strict;
use List::Util qw(max);

use Exporter qw(import);
our @EXPORT_OK=qw(csvLine csvDecLin csvPrint colWidth);

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
 my ($delim,$quote)=($pars->{'delim'} || ',',$pars->{'quote'} || '"');
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
   shift $from;
  } else {
   return 0;
  }
  @{$to}=map { csvLine($delim,$quote,[@{$_}{@keySeq}])} @$from;
 } else {
  @{$to}=map { csvLine($delim,$quote,$_) } @$from;
 }

 if ($WriteTo eq 'FILE') {
  print $fh join("\n",@{$to})."\n";
 } elsif ($WriteTo eq 'LIST_ON_RET') {
  return @{$to};
 } else {
  return 1;
 }
}

sub colWidth {
 my @mx=@_;
 my $lmx=$#mx;
 my $mcn=max(map {$#{$_}} @mx);
 my @w=map { my $c=$_; max(map { length($mx[$_][$c]) } 0..$lmx) } 0..$mcn;
 return wantarray?($mcn,@w):\@w;
}

sub csvDecLin {
 my ($d,$tq,$csvl)=@_;
 my @flds=$csvl=~m/(?:^|${d})(${tq}[^${tq}${d}]*(?:${tq}${tq}[^${tq}${d}]*)*${tq}|[^${tq}${d}]*)(?=${d}|$)/g;
 print join("\n->",@flds,'');
 map { do { s/${tq}${tq}/${tq}/; s/(?:^${tq}|${tq}$)//g } if /^${tq}/; $_  } @flds;
 return \@flds;
}

1;
