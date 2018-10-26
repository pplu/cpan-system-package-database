package Logger;
  use Moo;

  has level => (is => 'ro', default => 2);

  sub info  { 
    my $self = shift;
    #return if ($self->level <= 2);
    print "[INFO] ", @_, "\n" 
  }
  sub debug {
    my $self = shift; 
    return if ($self->level <= 4);
    print "[DEBG] ", @_, "\n" 
  }

package ModuleResolver;
  use YAML::PP;
  use HTTP::Tiny;
  use JSON::MaybeXS;
  use Moo;

  use Dependencies;

  has os_distro => (is => 'ro', default => 'Debian');
  has os_distro_version => (is => 'ro', default => 'buster');

  has log => (is => 'ro', default => sub { Logger->new });
  has db => (is => 'ro', default => sub { YAML::PP->new->load_file('DB.yaml') });
  has ua => (is => 'ro', default => sub { HTTP::Tiny->new });

  sub provided_in {
    my ($self, $distro) = @_;  
    return $self->db->{ $distro }->{ provided_in }->{ $self->os_distro }->{ $self->os_distro_version };
  }

  sub get_deps_for {
    my ($self, $module) = @_;

    my $seen = {};
    my $deps = Dependencies->new;
    $self->_get_deps_for($module, $deps, $seen, 0);
    return $deps;
  }

  sub _get_deps_for {
    my ($self, $module, $deps, $seen, $level) = @_;

    return if (defined $seen->{ $module });
    $seen->{ $module } = 1;

    my $distro = $self->get_distribution_for_module($module);

    $self->log->info(('  ' x $level) . "$module ($distro)");

    my $os_package = $self->provided_in($distro);
    if (defined $os_package) {
      $self->log->info(('  ' x $level) . "in OS package $os_package");
      $deps->add_os_package($os_package);
    } else {
      my $rel_deps = $self->get_release_dependencies($distro);
      
      foreach my $dep (@$rel_deps) {
        #$self->_get_deps_for($dep->{ module }, $deps, $seen, $level + 1) if ($dep->{ phase } eq 'runtime' and $dep->{ relationship } eq 'requires');
        $self->_get_deps_for($dep->{ module }, $deps, $seen, $level + 1);
      }
    }
  }
 
  sub get_distribution_for_module {
    my ($self, $module) = @_;
    my $result = $self->ua->get("https://fastapi.metacpan.org/v1/module/$module");
    my $module_info = decode_json($result->{ content }) if ($result->{ success });
    die "error getting module release for $module" if (not $result->{ success });
    #return $cache->{ $module } = $module_info->{ distribution };
    return $module_info->{ distribution };
  }

  sub get_release_dependencies {
    my ($self, $release) = @_;
    #state $cache = {};
    #return $cache->{ $release } if (exists $cache->{ $release });
    my $result = $self->ua->get("https://fastapi.metacpan.org/v1/release/$release");
    my $release_info = decode_json($result->{ content }) if ($result->{ success });
    die "error getting release dependencies for $release" if (not $result->{ success });
    #return $cache->{ $release } = ($release_info->{ dependency } || [ ])
    return ($release_info->{ dependency } || [ ])
  }

1;
