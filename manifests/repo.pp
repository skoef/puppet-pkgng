# This configures a single PkgNG repository. Instead of defining the repo
# with the repo URL, we split it up in hostname, mirror_type, protocol and
# repopath. This way, this resource can be integrated with possible firewalls
# better.

define pkgng::repo (
  $packagehost = $name,
  $release     = $::operatingsystemrelease,
  $protocol    = 'http',
  $mirror_type = 'srv',
  $repopath    = '/${ABI}/latest',
  $enabled     = true,
) {
  include ::pkgng

  validate_string($packagehost)
  # validate protocol against chosen mirror_type
  case $mirror_type {
    /(?i:srv)/: {
      if $protocol !~ /(?i:http(s)?)/ {
        fail("Mirror type ${mirror_type} support http:// and https:// only")
      }
    }
    /(?i:http)/: {
      if $protocol !~ /(?i:(http|https|ftp|file|ssh))/ {
        fail("Mirror type ${mirror_type} support http://, https://, ftp://, file://, ssh:// only")
      }
    }
    default: {
      fail("Mirror type ${mirror_type} not supported")
    }
  }
  validate_absolute_path($repopath)
  if is_string($enabled) {
    validate_re($enabled, ['^yes$', '^no$'])
  } else {
    validate_bool($enabled)
  }
  validate_integer($priority, 100)

  # define repository configuration
  file { "/usr/local/etc/pkg/repos/${name}.conf":
    content => template('pkgng/repo.erb'),
    notify  => Exec['pkg update'],
  }

  # set firewall
  $manage_firewall_host = $mirror_type ? {
    /(?i:srv)/ => firewall_resolve_srv_targets("_http._tcp.${packagehost}"),
    default    => $packagehost,
  }

  # TODO: ftp protocol also needs additional ports (either passive or active)
  $manage_firewall_port = $protocol ? {
    'http'  => 80,
    'https' => 443,
    'ftp'   => 21,
    'ssh'   => 22,
    default => undef,
  }

  if $manage_firewall_port {
    firewall::rule { "pkgng-repo-${name}":
      direction   => 'out',
      protocol    => 'tcp',
      port        => $manage_firewall_port,
      destination => $manage_firewall_host
    }
  }
}
