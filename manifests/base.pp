class logwatch::base {
    package{logwatch:
        ensure => present,
    }

    file{"/etc/logwatch/conf/logwatch.conf":
        source => [ "puppet://$server/modules/site-logwatch/config/logwatch.conf",
                    "puppet://$server/modules/logwatch/config/logwatch.conf" ],
        require => Package[logwatch],
        mode => 0644, owner => root, group => 0;
    }
}
