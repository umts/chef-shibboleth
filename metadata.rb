maintainer       "UMass Transit Service"
maintainer_email "transit-mis@admin.umass.edu"
license          "MIT"
description      "Installs/Configures shibboleth"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
name             'shibboleth'

depends 'apache2'
depends 'yum'

supports "ubuntu"
supports "centos"
