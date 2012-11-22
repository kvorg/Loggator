=head1 Collected general subs for Loggator

=cut

require Exporter;

@EXPORT_OK = qw( testall );

=head2 testall {} @list;

Subroutine C<testall> is prototyped with a syntax similar to map with
a block: it applies the block to all the elements of its list
argument, ands the result and returns the value.

This is to be used when one or more conditions have to be tested on a
list of values.

Example:

 print "ok!\n" if testall { $_ > 3 } ( 7, 5, 4, 22, 78 ) ; #prints ok

=cut

sub testall (&@) {
  my $test = shift;
  my $status = 1;

  foreach (@_) {
    $status &&= &$test ;
  }
    return $status;
}
