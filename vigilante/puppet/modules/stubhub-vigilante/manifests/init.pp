# == Class: vigilante
#
# This class implements various functions for the vigilante package.
# The package performs environment auditing, monitoring and workflow control
#
# === Parameters
#
# Document parameters details here, including default value.
#
#  [*phaktordepth*]
#    The number of previous phaktor runs that are saved on disk,
#    above this number, older entries are truncated.
#    Defaults to '10'
#
#  [*phaktor_bindir*]
#    Path to the phaktor python source program.
#    Defaults to'/usr/local/bin'
#
#  [*phaktor_cfg*]
#    Path to where the phaktor config file should be placed.
#    Defaults to '/nas/reg/log/jiralab/vigilante/facts.ftr'
#
#  [*phaktor_dir*]
#    The root dir of where all of the auditing data is stored on the NAS.
#    Defaults to '/nas/reg/log/jiralab/vigilante/auditor'
#
#  [*phaktor_sched_minute]*
#    Minute on the hour that phaktor should run, defaults to fqdn_rand(60)
#
#  [*phaktor_sched_hour*]
#    Array that contains the hours that phaktor is run, note that we use
#    fqdn_rand() to "fuzz" the actual run time to spread out the
#    disk write activity. Defaults to
#     [ fqdn_rand(4), 6+fqdn_rand(5), 12+fqdn_rand(5), 18+fqdn_rand(5) ]
#
# === Examples
#
#  class { vigilante:
#    phaktordepth         => '15',
#    phaktor_sched_minute => '23',
#  }
#

# === Authors
#
# Author Name <geowhite@stubhub.com>
#
# === Copyright
#
# Copyright 2014 StubHub, unless otherwise noted.
#

class vigilante (
    $phaktordepth = '100',
    $phaktor_bindir = '/usr/local/bin',
    $phaktor_cfg = '/nas/reg/log/jiralab/vigilante/generic.yaml',
    $phaktor_dir = '/nas/reg/log/jiralab/vigilante/auditor',
    $phaktor_sched_minute = fqdn_rand(60),
    $phaktor_sched_hour = [ fqdn_rand(4), 6+fqdn_rand(5), 12+fqdn_rand(5), 18+fqdn_rand(5) ],
){

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
    }

  file { "${phaktor_bindir}/phaktor.py" :
    ensure => 'file',
    mode   => '0755',
    source => 'puppet:///modules/vigilante/bin/phaktor.py',
  }

  file { "${phaktor_bindir}/phaktor":
    ensure  => 'link',
    target  => "${phaktor_bindir}/phaktor.py",
    require => File["${phaktor_bindir}/phaktor.py", "${phaktor_bindir}/yaml"],
  }

  file { "${phaktor_bindir}/yaml":
    ensure   => directory,
    path     => "${phaktor_bindir}/yaml",
    source   => 'puppet:///modules/vigilante/bin/yaml',
    recurse  => true,
  }

  file { $phaktor_cfg :
    ensure => 'file',
    source => 'puppet:///modules/vigilante/etc/generic.yaml',
  }

  file { $phaktor_dir :
    ensure => 'directory',
  }


  cron { 'phaktor':
    user    => 'root',
    minute  => $phaktor_sched_minute,
    hour    => $phaktor_sched_hour,
    command => "${phaktor_bindir}/phaktor -c ${phaktor_cfg} -r ${phaktor_dir} -d ${phaktordepth}",
    require => File[$phaktor_cfg, "${phaktor_bindir}/phaktor", $phaktor_dir ]
  }

}
