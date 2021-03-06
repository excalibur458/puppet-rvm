class rvm::system($version=undef, $proxy=undef) {

  $actual_version = $version ? {
    undef     => 'latest',
    'present' => 'latest',
    default   => $version,
  }

  if $proxy {
    $cmd = "bash -c '/usr/bin/curl --proxy ${proxy} -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer -o /tmp/rvm-installer && \
            chmod +x /tmp/rvm-installer && \
            rvm_proxy=${proxy} rvm_bin_path=/usr/local/rvm/bin rvm_man_path=/usr/local/rvm/man /tmp/rvm-installer --version ${actual_version} && \
            rm /tmp/rvm-installer'"

    # Customize rvm_gem_options in /etc/rvmrc. This is a workaround for the fact
    # that RVM does not pass the value of --proxy to gem when installing 
    # the default gemset during an installation of ruby.
    file { '/etc/rvmrc':
      ensure  => present,
      content => "umask u=rwx,g=rwx,o=rx\nexport rvm_gem_options=\"--no-rdoc --no-ri --http-proxy ${proxy}\"",
      require => Exec['system-rvm'],
    }
  } else {
    $cmd = "bash -c '/usr/bin/curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer -o /tmp/rvm-installer && \
            chmod +x /tmp/rvm-installer && \
            rvm_bin_path=/usr/local/rvm/bin rvm_man_path=/usr/local/rvm/man /tmp/rvm-installer --version ${actual_version} && \
            rm /tmp/rvm-installer'"
  }
  exec { 'system-rvm':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => $cmd,
    creates => '/usr/local/rvm/bin/rvm',
    timeout => 3000,
    require => [
      Class['rvm::dependencies'],
    ],
  }

  # the fact won't work until rvm is installed before puppet starts
  if "${::rvm_version}" != "" {
    if ($version != undef) and ($version != present) and ($version != $::rvm_version) {
      # Update the rvm installation to the version specified
      notify { 'rvm_version': message => "RVM version ${::rvm_version}" }
      notify { 'rvm-get_version':
        message => "RVM updating to version ${version}",
        require => Notify['rvm_version'],
      } ->
      exec { 'system-rvm-get':
        path    => '/usr/local/rvm/bin:/usr/bin:/usr/sbin:/bin',
        command => "rvm get ${version}",
        before  => Exec['system-rvm'], # so it doesn't run after being installed the first time
      }
    }
  }

}
