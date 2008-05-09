#######################################
# logwatch module
# Puzzle ITC - haerry+puppet(at)puzzle.ch
# GPLv3
#######################################


# modules_dir { "logwatch": }
class logwatch {
    include logwatch::base
}

class logwatch::base {
    package{logwatch:
        ensure => present,
    }

    file{"/etc/logwatch/conf/logwatch.conf":
        source => [ "puppet://$server/logwatch/config/logwatch.conf",
                    "puppet://$server/files/config/logwatch.conf" ],
        require => Package[logwatch],
        mode => 0644, owner => root, group => 0;
    }
}
