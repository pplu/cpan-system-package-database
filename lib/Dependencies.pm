package Dependencies;
  use Moo;

  has _os_packages => (is => 'ro', default => sub { { } });

  sub os_package_list { my $self = shift; return sort keys %{ $self->_os_packages } }

  sub add_os_package {
    my ($self, $os_package) = @_;
    $self->_os_packages->{ $os_package } = 1;
  }

1;
