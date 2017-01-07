define prosody::virtualhost (
  $custom_options = {},
  $ensure    = present,
  $ssl_key   = undef,
  $ssl_cert  = undef,
  $copy_ssl  = true,
  $components= {},
) {
  include prosody

  # Check if SSL set correctly
  if (($ssl_key != undef) and ($ssl_cert == undef)) {
    fail('The prosody::virtualhost type needs both ssl_key *and* ssl_cert set')
  }
  if (($ssl_key == undef) and ($ssl_cert != undef)) {
    fail('The prosody::virtualhost type needs both ssl_key *and* ssl_cert set')
  }

  if (($ssl_key != undef) and ($ssl_cert != undef)) {
   if $copy_ssl {
    # Copy the provided sources to prosody certs folder
    $prosody_ssl_key  = "/etc/prosody/certs/${name}.key"
    $prosody_ssl_cert = "/etc/prosody/certs/${name}.cert"

    file {
      $prosody_ssl_key:
        source => $ssl_key,
        mode   => '0640',
        owner  => $::prosody::user,
        group  => $::prosody::group;
      $prosody_ssl_cert:
        source => $ssl_cert,
        mode   => '0644',
        owner  => $::prosody::user,
        group  => $::prosody::group;
    }
   } else {
    # use ssl key in place
    $prosody_ssl_key  = "$ssl_key"
    $prosody_ssl_cert = "$ssl_cert"

    file {
      $prosody_ssl_key:
        mode   => '0640',
        group  => $::prosody::group;
      $prosody_ssl_cert:
        mode   => '0644',
        group  => $::prosody::group;
    }
   }

    $config_requires = [File[$ssl_key], File[$ssl_cert], Class['::prosody::package']]
  }
  else {
    $config_requires = Class['::prosody::package']
  }

  $conf_avail_fn = "/etc/prosody/conf.avail/${name}.cfg.lua"

  file { $conf_avail_fn:
      ensure  => $ensure,
      require => $config_requires,
      content => template('prosody/virtualhost.cfg.erb'),
      notify  => Class['::prosody::service'],
  }

  $cfg_ensure = $ensure ? {
    'present' => link,
    'absent'  => absent,
  }

  file { "/etc/prosody/conf.d/${name}.cfg.lua":
    ensure  => $cfg_ensure,
    target  => $conf_avail_fn,
    notify  => Class['::prosody::service'],
    require => File[$conf_avail_fn];
  }
}
