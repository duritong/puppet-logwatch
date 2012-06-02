class logwatch::base {
  package{logwatch:
    ensure => present,
  }

  file{"/etc/logwatch/conf/logwatch.conf":
    source => [ "puppet:///modules/site_logwatch/config/logwatch.conf",
                "puppet:///modules/logwatch/config/logwatch.conf" ],
    require => Package[logwatch],
    mode => 0644, owner => root, group => 0;
  }
}
