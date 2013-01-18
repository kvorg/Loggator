use lib 'lib';
package Loggator;

use Loggator::Base -base;

use Loggator::Confer;
use Loggator::Parser;

use Carp;

has [ qw( config confer parser ) ];
has logs => sub { return {} };
has log = $0 . '.log'; # log to program_name.log if no better option
has hooks => sub { return {} };


sub new {
  my $self = SUPER::new(@_);
  croak "No config defined aborting.\n." .
    "Please instantiate loggator like this: Loggator->new(config => 'path/to/loggator.rc');"
      unless $self->config;
  $self->confer(Loggator::Confer->new($self->config));
  croak "Failed to instantiate the coniguration manager, aborting"
      unless $self->confer and ref $self->confer eq 'Loggator::Confer' ;
  $self->confer->setlog($self->log);
  $self->confer->process();  # process configuration

  #now we can init some stuff

  #and return to the user program so that they can set up hooks

  #and run the parsers

}

sub add_hook {
}

1;

=head1 NAME

Logattor - a log parsing utility

=head1 SYNOPSIS

  my $l = Loggator(config => 'path/to/loggator.rc');
  my $l = Loggator(config => 'path/to/loggator.rc', log => '/var/log/loggator.log' );

=head1 DESCRIPTION



=head1 ATTRIBUTES

L<Loggator> uses L<Logattor::Base> to expose the following attributes:

=head2

=head1 METHODS

L<Loggator> inherits from L<Logattor::Base> and exports the following methods:
flag or a base class.

=head2 C<has>

  has 'name';
  has [qw(name1 name2 name3)];
  has name => 'foo';
  has name => sub {...};
  has [qw(name1 name2 name3)] => 'foo';
  has [qw(name1 name2 name3)] => sub {...};

Create attributes, just like$ the C<attr> method.

=head1 DEBUGGING


=head1 SEE ALSO

L<Loggator::Parser>, L<Loggator::Confer>

=cut
