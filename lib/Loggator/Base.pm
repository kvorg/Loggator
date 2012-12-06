package Loggator::Base;

# Shamelessly stolen from Mojo::Base.
# In the future, when we depend on Mojolicious, this will simply alias Mojo::Base

use strict;
use warnings;

# Mojo modules are modern!
# Loggator, however, are not
# use feature ();

# No imports because we get subclassed, a lot!
use Carp ();

# "Kids, you tried your best and you failed miserably.
#  The lesson is, never try."
sub import {
  my $class = shift;
  return unless my $flag = shift;

  # No limits!
  no strict 'refs';
  no warnings 'redefine';

  # Base
  if ($flag eq '-base') { $flag = $class }

  # Strict
  elsif ($flag eq '-strict') { $flag = undef }

  # Module
  else {
    my $file = $flag;
    $file =~ s/::|'/\//g;
    require "$file.pm" unless $flag->can('new');
  }

  # ISA
  if ($flag) {
    my $caller = caller;
    push @{"${caller}::ISA"}, $flag;

    # Can haz?
    *{"${caller}::has"} = sub { attr($caller, @_) };
  }

  # Mojo modules are strict!
  strict->import;
  warnings->import;
  # Loggator modules are not modern :-(
  # feature->import(':5.10');
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

# Performance is very important for something as often used as accessors,
# so we optimize them by compiling our own code, don't be scared, we have
# tests for every single case
sub attr {
  my ($class, $attrs, $default) = @_;
  return unless ($class = ref $class || $class) && $attrs;

  # Check default
  Carp::croak('Default has to be a code reference or constant value')
    if ref $default && ref $default ne 'CODE';

  # Create attributes
  for my $attr (@{ref $attrs eq 'ARRAY' ? $attrs : [$attrs]}) {
    Carp::croak(qq{Attribute "$attr" invalid})
      unless $attr =~ /^[a-zA-Z_]\w*$/;

    # Header (check arguments)
    my $code = "sub {\n  if (\@_ == 1) {\n";

    # No default value (return value)
    unless (defined $default) { $code .= "    return \$_[0]{'$attr'};" }

    # Default value
    else {

      # Return value
      $code .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";

      # Return default value
      $code .= "    return \$_[0]{'$attr'} = ";
      $code .= ref $default eq 'CODE' ? '$default->($_[0]);' : '$default;';
    }

    # Store value
    $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";

    # Footer (return invocant)
    $code .= "  \$_[0];\n};";

    # We compile custom attribute code for speed
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$attr"} = eval $code or Carp::croak("Mojo::Base error: $@");
    warn "\nATTRIBUTE: $class->$attr\n$code\n\n" if $ENV{LOGGATOR_BASE_DEBUG};
  }
}

1;

=head1 NAME

Loggator::Base - Minimal base class stolen from Mojo and Mojlicious

=head1 SYNOPSIS

  package Cat;
  use Loggator::Base -base;

  has 'mouse';
  has paws => 4;
  has [qw(ears eyes)] => 2;

  package Tiger;
  use Loggator::Base 'Cat';

  has stripes => 42;

  package main;

  my $mew = Cat->new(mouse => 'Mickey');
  say $mew->paws;
  say $mew->paws(5)->paws;

  my $rawr = Tiger->new(stripes => 23);
  say $rawr->ears * $rawr->stripes;

=head1 DESCRIPTION

L<Logattor::Base> is a simple base class for L<Logattor> objects. This
is a transitional solution. Please don't use this for anything else,
since in the future Loggator will depend on L<Mojolicious> and
L<Mojo::Base> will be used instead.

  # Automatically enables "strict", "warnings" (but not Perl 5.10 features)
  use Logattor::Base -strict;
  use Logattor::Base -base;
  use Logattor::Base 'SomeBaseClass';

All three forms save a lot of typing.

  # use Logattor::Base -strict;
  use strict;
  use warnings;
  use feature ':5.10';

  # use Logattor::Base -base;
  use strict;
  use warnings;
  use feature ':5.10';
  use Logattor::Base;
  push @ISA, 'Logattor::Base';
  sub has { Logattor::Base::attr(__PACKAGE__, @_) }

  # use Logattor::Base 'SomeBaseClass';
  use strict;
  use warnings;
  use feature ':5.10';
  require SomeBaseClass;
  push @ISA, 'SomeBaseClass';
  use Logattor::Base;
  sub has { Logattor::Base::attr(__PACKAGE__, @_) }

=head1 FUNCTIONS

L<Logattor::Base> exports the following functions if imported with the C<-base>
flag or a base class.

=head2 C<has>

  has 'name';
  has [qw(name1 name2 name3)];
  has name => 'foo';
  has name => sub {...};
  has [qw(name1 name2 name3)] => 'foo';
  has [qw(name1 name2 name3)] => sub {...};

Create attributes, just like the C<attr> method.

=head1 METHODS

L<Logattor::Base> implements the following methods.

=head2 C<new>

  my $object = BaseSubClass->new;
  my $object = BaseSubClass->new(name => 'value');
  my $object = BaseSubClass->new({name => 'value'});

This base class provides a basic object constructor. You can pass it either a
hash or a hash reference with attribute values.

=head2 C<attr>

  $object->attr('name');
  BaseSubClass->attr('name');
  BaseSubClass->attr([qw(name1 name2 name3)]);
  BaseSubClass->attr(name => 'foo');
  BaseSubClass->attr(name => sub {...});
  BaseSubClass->attr([qw(name1 name2 name3)] => 'foo');
  BaseSubClass->attr([qw(name1 name2 name3)] => sub {...});

Create attributes. An array reference can be used to create more than one
attribute. Pass an optional second argument to set a default value, it should
be a constant or a sub reference. The sub reference will be excuted at
accessor read time if there's no set value.

=head1 DEBUGGING

You can set the C<LOGATTOR_BASE_DEBUG> environment variable to get some advanced
diagnostics information printed to C<STDERR>.

  LOGGATOR_BASE_DEBUG=1

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Base

=cut
