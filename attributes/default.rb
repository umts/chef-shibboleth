default['shibboleth']['idp'] = 'https://idp.testshib.org'
default['shibboleth']['remote_user'] = 'eppn persistent-id targeted-id'

default['shibboleth']['sessions']['lifetime'] = 28_800
default['shibboleth']['sessions']['timeout'] = 3600
default['shibboleth']['sessions']['check_address'] = false
default['shibboleth']['sessions']['handler_ssl'] = true

default['shibboleth']['handlers']['metadata_generator'] = true
default['shibboleth']['handlers']['status'] = true
default['shibboleth']['handlers']['session'] = true
default['shibboleth']['handlers']['discovery_feed'] = true

default['shibboleth']['errors']['contact'] = "root@#{node['fqdn']}"
default['shibboleth']['errors']['logo'] = '/shibboleth-sp/logo.jpg'
default['shibboleth']['errors']['css'] = '/shibboleth-sp/main.css'

default['shibboleth']['package'] = value_for_platform(
  ['centos', 'redhat'] => {'default' => 'shibboleth'},
  ['debian', 'ubuntu'] => {'default' => 'libapache2-mod-shib2'}
)

default['shibboleth']['module_path'] = value_for_platform(
  ['centos', 'rhel'] => {'default' => '/usr/lib64/shibboleth/mod_shib_22.so'},
  'ubuntu' => {'default' => '/usr/lib/apache2/modules/mod_shib_22.so'}
)

if node['platform_family'] == 'rhel'
  dist_folder = value_for_platform(
    'centos' => {'~>5.0' => 'CentOS_5', '~>6.0' => 'CentOS_CentOS-6'},
    'rhel' => {'~>5.0' => 'RHEL_5', '~>6.0' => 'RHEL_6'}
  )
  default['shibboleth']['yum_base_url'] = 
    "http://download.opensuse.org/repositories/security:/shibboleth/#{dist_folder}/"
end

