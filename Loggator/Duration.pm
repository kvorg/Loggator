# Trivial duration management to avoid heavy lifting when
# DateTime.pm not needed.

package Loggator::Duration;
require Exporter;
use base Exporter;
@EXPORT = qw(walltime_to_sec
             sec_to_walltime
             duration_to_sec
             normalize_duration
            ); 

sub walltime_to_sec {
    $_ = shift ; m{^(\d\d+):(\d\d):(\d\d)$} or
      warn "Not a time duration string: $_.\n" and return undef  ;
      warn "Not a time duration string: $_.\n" and return undef
	if ($2 > 59 or $3 > 59);
    return $1 * 60 * 60 + $2 * 60 + $3 ;
}

sub sec_to_walltime {
    my $s = shift;
    my $msec = $s % 60**2;
    my $h = ($s - $msec) / 60**2;
    my $sec = $msec % 60;
    my $m = ($msec - $sec) / 60;
    return (join ':', ( sprintf('%02d', $h),
			sprintf('%02d', $m),
			sprintf('%02d', $sec)
		      )
	   );
}

sub duration_to_sec {
    $_ = shift ; m{^(\d+)([dhms])$} or
      warn "Not a simple duration specification n+[dhms]: $_.\n" and return undef  ;
    
    return $1 if $2 eq 's';
    return $1 * 60 if $2 eq 'm';
    return $1 * 60**2 if $2 eq 'h';
    return $1 * 24 * 60**2 if $2 eq 'd';
}

sub normalize_duration {
        $_ = shift ; 
	return $_ if m{^\d+$} ;
	return walltime_to_sec($_) if m{^(\d\d+):(\d\d):(\d\d)$};
	return duration_to_sec($_) if m{^(\d+)([dhms])$};
}
