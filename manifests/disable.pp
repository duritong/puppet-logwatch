# manifests/disable.pp
# used to disable logwatch on hosts

class logwatch::disable inherits logwatch::base {
  Package[logwatch]{
    ensure => absent,
  }
  File["/etc/logwatch/conf/logwatch.conf"]{
    ensure => absent,
  }
}
