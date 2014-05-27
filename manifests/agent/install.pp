class teamcity::agent::install {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  case downcase($::osfamily){
    'debian': {

      package { ['unzip','default-jre']:
        ensure => 'installed'
      } ->

      file {'agent_home':
        ensure => directory,
        path => "/home/$username",
        group => [$teamcity::agent::username],
        owner => [$teamcity::agent::username]
      } ->

      wget::fetch { "teamcity-buildagent":
        source => "${$teamcity::agent::download_url}",
        destination => "/root/${$teamcity::agent::archive_name}",
        timeout => 0,
      }

      file { "${$teamcity::agent::destination_dir}":
        ensure => "directory"
      }

      exec { "extract-build-agent":
        command => "unzip -d ${$teamcity::agent::destination_dir}/${$teamcity::agent::agent_dir} /root/${$teamcity::agent::archive_name} && cp ${$teamcity::agent::destination_dir}/${$teamcity::agent::agent_dir}/conf/buildAgent.dist.properties ${$teamcity::agent::destination_dir}/${$teamcity::agent::agent_dir}/conf/buildAgent.properties && chown ${$teamcity::agent::username}:${$teamcity::agent::username} ${$teamcity::agent::destination_dir}/${$teamcity::agent::agent_dir} -R",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/opt/local/bin",
        creates => "${$teamcity::agent::destination_dir}/${$teamcity::agent::agent_dir}",
        logoutput => "on_failure",
      }

      file { "${$teamcity::agent::destination_dir}/${$teamcity::agent::agent_dir}/bin/":
        mode => 755,
        recurse => true,
      }

    }
    'windows': {

      file {'c:\temp':
        ensure => 'directory'
      } ->

      download_file { 'TeamCity Windows Installer':
        url                   => "${teamcity::agent::download_url}",
        destination_directory => 'c:\temp'
      } ->

      exec { "extract-build-agent":
        command   => "unzip c:/temp/${teamcity::agent::archive_name} -d ${teamcity::agent::destination_dir}",
        creates   => "${teamcity::agent::destination_dir}",
        logoutput => "on_failure",
        provider  => 'powershell'
      } ->

      exec {'Install Build Agent':
        command  => '.\service.install.bat',
        onlyif   => 'if(Get-Service TCBuildAgent) { exit 1 } else { exit 0 }',
        cwd      => "${teamcity::agent::destination_dir}\bin",
        provider => 'powershell'
      }
    }
    default: {
      fail("This module is only supported by debian and windows based operating systems")
    }
  }

}