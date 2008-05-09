# manifests/logserver.pp
# used to deploy stuff on the logserver

class logwatch::logserver inherits logwatch::base {

    file{"/opt/bin/logwatch_wrapper.rb":
        source => "puppet://$server/logwatch/scripts/logwatch_warpper.rb",
        require => [ File["/opt/bin"], Package[logwatch] ],
        mode => 0700, owner => root, group => 0;
    }

    file{"/etc/cron.daily/logwatch_wrapper.rb":
        ensure => "/opt/bin/logwatch_wrapper.rb",
        require => File["/opt/bin/logwatch_wrapper.rb"],
    }

}


