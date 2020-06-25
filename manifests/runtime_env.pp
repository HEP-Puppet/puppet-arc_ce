# Class arc_ce::runtime_env
# Manages runtime environments (RTEs)
class arc_ce::runtime_env(
  Boolean $add_atlas = true,
  Boolean $add_glite = true,
  Boolean $purge_rte_dirs = true,
  Array[String] $enable = [ 'ENV/PROXY' ],
  Array[String] $default = [ 'ENV/PROXY' ],
  Hash[String,Hash] $additional_rtes = {},
) {

  # create directories for custom runtime environments
  $user_rte_dirs = unique(unique($additional_rtes.keys() +
    ($add_atlas ? {
      true    => ['APPS/HEP/ATLAS-SITE-LCG'],
      default => [],
    }) +
    ($add_glite ? {
      true    => ['ENV/GLITE'],
      default => [],
    })
  ).map |$x| { split(dirname($x), '/').reduce([]) |$m, $x| { $m + join([$m[-1], $x], '/')}}.flatten())

  file { [ '/etc/arc/', '/etc/arc/runtime/' ] + $user_rte_dirs.map |$x| { "/etc/arc/runtime${x}" }:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # RTEs have to be enabled to be set as default
  $default_real = intersection($default, $enable)

  # create directories for enabled runtime environments
  $enabled_rte_dirs =
    unique(unique($enable).map |$x| { split(dirname($x), '/').reduce([]) |$m, $x| { $m + join([$m[-1], $x], '/')}}.flatten())

  # create directories for default runtime environments
  $default_rte_dirs =
    unique($default_real.map |$x| { split(dirname($x), '/').reduce([]) |$m, $x| { $m + join([$m[-1], $x], '/')}}.flatten())

  file { ['/var/spool/arc/jobstatus/rte', '/var/spool/arc/jobstatus/rte/enabled', '/var/spool/arc/jobstatus/rte/default', ] +
      $enabled_rte_dirs.map |$x| { "/var/spool/arc/jobstatus/rte/enabled${x}" } +
      $default_rte_dirs.map |$x| { "/var/spool/arc/jobstatus/rte/default${x}" }:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    purge   => $purge_rte_dirs,
    recurse => true,
    force   => true,
    require => Package['nordugrid-arc-arex'],
  }

  # add atlas RTE
  if $add_atlas {
    # create empty ATLAS-SITE-LCG for ATLAS prd jobs
    arc_ce::rte { 'APPS/HEP/ATLAS-SITE-LCG':
      enable  => 'APPS/HEP/ATLAS-SITE-LCG' in $enable,
      default => 'APPS/HEP/ATLAS-SITE-LCG' in $default_real,
      source  => "puppet:///modules/${module_name}/RTEs/ATLAS-SITE-LCG",
    }
  }

  # add glite RTE
  if $add_glite {
    # add glite env
    arc_ce::rte { 'ENV/GLITE':
      enable  => 'ENV/GLITE' in $enable,
      default => 'ENV/GLITE' in $default_real,
      source  => "puppet:///modules/${module_name}/RTEs/GLITE",
    }
  }

  # add user defined RTEs
  $additional_rtes.each |String $rte, Hash $rte_cfg| {
    $rte_path = dirname($rte)
    arc_ce::rte { $rte:
      enable  => $rte in $enable,
      default => $rte in $default_real,
      source  => 'source' in $rte_cfg ? {
        true    => $rte_cfg['source'],
        default => undef,
      },
      content => 'content' in $rte_cfg ? {
        true    => $rte_cfg['content'],
        default => undef,
      },
    }
  }

  # configure system RTEs
  [ 'ENV/CANDYPOND', 'ENV/CONDOR/DOCKER', 'ENV/LRMS-SCRATCH', 'ENV/PROXY', 'ENV/RTE', 'ENV/SINGULARITY' ].each |String $rte| {
    arc_ce::rte { $rte:
      enable  => $rte in $enable,
      default => $rte in $default_real,
    }
  }

}
