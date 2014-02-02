#
# Cookbook Name:: shibboleth
# Recipe:: default
#
# Copyright 2013, UMass Transit Service
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
include_recipe 'apache2'

if platform_family?('rhel')
  yum_repository'shibboleth' do
    description 'Shibboleth package repository'

    platform_dirs = {
      'centos' => { '5' => 'CentOS_5/',
                    '6' => 'CentOS_CentOS-6/'},
      'rhel'   => { '5' => 'RHEL_5/',
                    '6' => 'RHEL_6/'}
    }

    base = 'http://download.opensuse.org/repositories/security:/shibboleth/' +
      platform_dirs[node['platform']][node['platform_version'].split('.').first]

    baseurl base
    gpgkey "#{base}repodata/repomd.xml.key"
    action :create
  end

  package 'shibboleth'

  file '/etc/httpd/conf.d/shib.conf' do
    action :delete
  end

else
  package 'libapache2-mod-shib2'
end

service "shibd" do
  supports :restart => true
  action [:enable, :start]
end

execute 'shib-keygen' do
  cwd '/etc/shibboleth'
  creates '/etc/shibboleth/sp-cert.pem'
  command "shib-keygen -f -h #{node['fqdn']} -e #{node['fqdn']}/shibboleth && chmod 644 /etc/shibboleth/sp-key.pem"
  notifies :run, "execute[shib-metagen]", :immediately
  notifies :restart, 'service[shibd]'
end

execute 'shib-metagen' do
  cwd '/etc/shibboleth'
  creates "/etc/shibboleth/#{node['fqdn']}-metadata.xml"
  command "shib-metagen -c /etc/shibboleth/sp-cert.pem -h #{node['fqdn']} > #{node['fqdn']}-metadata.xml"
  action :nothing
  notifies :restart, 'service[shibd]'
end

remote_file '/etc/shibboleth/idp-metadata.xml' do
  source "#{node['shibboleth']['idp']}/idp/profile/Metadata/SAML"
  mode '0644'
  notifies :restart, 'service[shibd]'
end

template '/etc/shibboleth/shibboleth2.xml' do
  source 'shibboleth2.xml.erb'
  mode '0644'
  variables(
    :idp_url => "#{node['shibboleth']['idp']}/idp/shibboleth"
  )
  notifies :restart, 'service[shibd]'
end

# Using ruby_block with ::File.open instead of file because I want to wait
# until converge-time to read in the .xml bits
ruby_block 'build-attribute-map' do
  block do
    head = <<-EOF
      <!-- This file is managed with Chef.  Any changes WILL BE OVER-WRITTEN -->
      <Attributes xmlns="urn:mace:shibboleth:2.0:attribute-map" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    EOF

    tail = "</Attributes>\n"

    content = (head + ::Dir.glob('/etc/shibboleth/attributes.d/*.xml').map { |file| ::File.read(file) }.join + tail)

    ::File.open("/etc/shibboleth/attribute-map.xml", "w", 0644) { |f| f.write(content) }
  end

  action :nothing
  notifies :restart, 'service[shibd]'
end

remote_directory '/etc/shibboleth/attributes.d' do
  mode '0755'
  files_mode '0644'
  notifies :create, 'ruby_block[build-attribute-map]'
end

shib_module_path = value_for_platform(['rhel', 'centos'] => {'default' => '/usr/lib64/shibboleth/mod_shib_22.so'},
                                 'ubuntu' => {'default' => '/usr/lib/apache2/modules/mod_shib_22.so'})

apache_module 'shib2' do
  identifier 'mod_shib'
  module_path shib_module_path
end
