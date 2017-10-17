#!/usr/bin/perl
package CSV::Lite;
use 5.16.1;
use utf8;
use strict;
use List::Util qw(max);
use Try::Tiny;

use Exporter qw(import);

our @EXPORT=qw(csvPrint csvRead);
our @EXPORT_OK=qw(csvLine csvDecLin csvPrint colWidth);

my $ERRMSG;

sub csvRead {
 my $csvLines=[map [map { s{(?:"(?<V1>")|\\(?<V2>.))}{$+{V1} // $+{V2}}ge if s/^"|"$//g; $_ } m/\G("(?:(?!"|\\).|\\.|"")+"|[^";]+);/g], split /\r?\n/, do { open my $fh, '<', $_[0]; local $/=<$fh> }];
 my ($c, $hdr)=(-1, shift $csvLines);
 [$#{$csvLines}, $hdr, +{map {$c++; $_=>[map $_->[$c], @{$csvLines}]} @{$hdr}}] 
}

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
 my $pars=(ref($_[0]) eq 'HASH' and (@_>1))?shift:{};
 my ($delim,$quote)=($pars->{'delim'} || ',',$pars->{'quote'} || '"');
 my ($to,$from)=(shift,shift);
 my ($WriteTo,$fh,$flNeed2CloseFH)=('FILE',*STDOUT,0);
 my $flFromIsARef=(ref($from) eq 'ARRAY') || (ref($from) eq 'HASH');
 
 try {
	if ((ref($to) eq 'ARRAY' or ref($to) eq 'HASH') and ! $from) {
		$from=$to;
		$to=[];
		$WriteTo='LIST_ON_RET' if wantarray();
	} else {
		die '"from" must be a list or hash reference' unless $flFromIsARef;
		if (ref($to) eq 'GLOB') {
			$fh=$to;
			$to=[];
		} elsif ($to and ! ref($to)) {
			$fh=undef;
			open($fh,'>'.($pars->{'append'}?'>':''),$to);
			$to=[];
			$flNeed2CloseFH=1;
		} elsif (ref($to) eq 'ARRAY') {		
			$WriteTo='LIST_ON_RET';
		}
	}
	my @keySeq;
	if (ref($from) eq 'HASH') {
		if (ref($pars->{'fields'}) eq 'ARRAY') {
			@keySeq=@{$pars->{'fields'}};
		} else {
			@keySeq=sort keys $from->{(keys $from)[0]};
		}
		@{$to}=map { csvLine($delim,$quote,[$_,@{$from->{$_}}{@keySeq}]) } sort keys $from;
	} elsif (ref($from->[0]) eq 'HASH' or ref($from->[1]) eq 'HASH') {
		if (ref($pars->{'fields'}) eq 'ARRAY') {
			@keySeq=@{$pars->{'fields'}};
		} elsif ( ref($from->[0]) eq 'HASH' ) {
			@keySeq=sort keys $from->[0];
		} elsif (ref($from->[0]) eq 'ARRAY' and ref($from->[1]) eq 'HASH') {
			@keySeq=@{$from->[0]};
			shift $from;
		} else {
			die 'Unknown';
		}
		@{$to}=map { csvLine($delim,$quote,[@{$_}{@keySeq}])} @$from;
	} else {
		@{$to}=map { csvLine($delim,$quote,$_) } @$from;
	}

	if ($WriteTo eq 'FILE') {	
		print $fh join("\n",@{$to}),"\n";
	} elsif ($WriteTo eq 'LIST_ON_RET') {
		return wantarray()?@{$to}:join("\n",@{$to});
	} else {
		return 1;
	}
 } catch {	
	$ERRMSG=$_;
	return 0;
 } finally {
	close($fh) if $flNeed2CloseFH;
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
