# manifests/logserver.pp
# used to deploy stuff on the logserver
class logwatch::logserver inherits logwatch::base {
  file{
    "/opt/bin/logwatch_wrapper.rb":
      source  => "puppet:///modules/logwatch/scripts/logwatch_warpper.rb",
      require => [ File["/opt/bin"], Package['logwatch'] ],
      owner   => root,
      group   => 0,
      mode    => '0700';
    "/etc/cron.daily/logwatch_wrapper.rb":
      ensure  => "/opt/bin/logwatch_wrapper.rb";
  }
}
