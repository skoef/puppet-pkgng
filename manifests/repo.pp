define pkgng::repo (
  $enable = true,
  $url,
  $mirror_type,
  $pubkey,
){

  file { "/usr/local/etc/pkg/repo/${name}.conf":
    ensure => present,
    owner  => root,
    group  => 0,
    mode   => 0644,
  }

}
