class f3backup::configure (
  $backup_home = '/backup',
  $backup_rdiff = true,
  $backup_mysql = false,
  $backup_command = false,
  $priority = '10',
  $rdiff_exclude = false,
  $rdiff_keep = '4W',
  $rdiff_global_exclude_file = false,
  $rdiff_user = false,
  $rdiff_path = false,
  $rdiff_extra_parameters = '',
  $mysql_backupdir = '/root/backup/MySQL',
  $mysql_daystokeep = 3,
  $mysql_monthstokeep = 2,
  $mysql_compress = 'gzip',
  $mysql_encrypt = 'none',
  $mysql_lock_tables = true,
  $mysql_extraparameters = '',
  $mysql_sshuser = 'root',
  $mysql_key = '/backup/.ssh/id_rsa-mysql-backup',
  $command_to_execute = '/bin/true',
  # Fact-based
  $backup_server = 'default',
  $myname = $::fqdn,
) {

  include '::f3backup'

  if $::f3backup::ensure != 'absent' {

    @@file { "${backup_home}/f3backup/${myname}/config.ini":
      content => template('f3backup/f3backup-host.ini.erb'),
      owner   => 'backup',
      group   => 'backup',
      mode    => '0644',
      tag     => "f3backup-${backup_server}",
    }

    if $rdiff_exclude {
      f3backup::configure::exclude { $rdiff_exclude: }
    }

    @file { '/etc/f3backup': ensure => directory }
    @file { '/etc/f3backup/facter': ensure => directory }
    if $backup_server != 'default' {
      realize File['/etc/f3backup']
      realize File['/etc/f3backup/facter']
      file { '/etc/f3backup/facter/backup_server.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $backup_server,
      }
    } else {
      file { '/etc/f3backup/facter/backup_server.conf': ensure => absent }
    }
    if $myname != $::fqdn {
      realize File['/etc/f3backup']
      realize File['/etc/f3backup/facter']
      file { '/etc/f3backup/facter/myname.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $myname,
      }
    } else {
      file { '/etc/f3backup/facter/myname.conf': ensure => absent }
    }

    # TODO : Fix all this...
    if $backup_mysql {
      file { '/usr/local/sbin/mysql-backup.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
        content => template('f3backup/mysql-backup.sh.erb'),
      }
      file { $mysql_backupdir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
      }
      # Ugly hack to also create the parent dir for the default
      if $mysql_backupdir == '/root/backup/MySQL' {
        file { '/root/backup':
          ensure => directory,
          owner  => 'root',
          group  => 'root',
          mode   => '0700',
        }
      }
      if $mysql_encrypt != 'none' {
        include '::f3backup::gpg_backup_key'
      }
    }

  }

}

