# development.pp
stage { 'req-install': before => Stage['rvm-install'] }

class requirements {
  group { "puppet": ensure => "present", }
  exec { "apt-update":
    command => "/usr/bin/apt-get -y update"
  }

  package {
    ["mysql-client", "mysql-server", "libmysqlclient-dev"]: 
      ensure => installed, require => Exec['apt-update']
  }
}

class installrvm {
  include rvm
  rvm::system_user { vagrant: ; }

  if $rvm_installed == "true" {
    rvm_system_ruby {
      'ruby-1.9.3-p0':
        ensure => 'present';
    }
  }
}

class installruby {
    rvm_system_ruby {
      'ruby-1.9.3-p194':
        ensure => 'present';
    }
}

class doinstall {
  class { requirements:, stage => "req-install" }
  include installrvm
}
class apache {
  exec { "apt-get update":
    command => "/usr/bin/apt-get update"
  }
 
  package { "apache2":
    ensure => present,
  }
 
  service { "apache2":
    ensure => running,
    require => Package["apache2"],
	# root => '/vagrant/'
  }
 
  # file { "default-apache2":
  #   path    => "/etc/apache2/sites-available/default",
  #   ensure  => file,
  #   require => Package["apache2"],
  #   source  => "puppet:///modules/apache2/default",
  #   notify  => Service["apache2"]
  # }
  # Enable the rewrite module.
  exec { "a2enmod-rewrite":
    creates => "/etc/apache2/mods-enabled/rewrite.load",
    command => "/usr/sbin/a2enmod rewrite",
    require => Package["apache2"],
    notify  => Service["apache2"],
  }
  # Enable the ssl module.
  exec { "a2enmod-ssl":
    creates => "/etc/apache2/mods-enabled/ssl.load",
    command => "/usr/sbin/a2enmod ssl",
    require => Package["apache2"],
    notify  => Service["apache2"],
  }

}
 
class php {
  package { "php5":
    ensure => present,
  }
 
  package { "php5-cli":
    ensure => present,
  }
 
  package { "php5-mysql":
    ensure => present,
  }
 
  package { "libapache2-mod-php5":
    ensure => present,
  }
  package { "cakephp-scripts":
    ensure => present,
  }
}
 
class mysql {
  # package { "mysql-server":
  #   ensure => present,
  # }
  #  
  service { "mysql":
    ensure => running,
    require => Package["mysql-server"],
  }
 
  exec { "set-mysql-password":
    unless  => "mysql -uroot -proot",
    path    => ["/bin", "/usr/bin"],
    command => "mysqladmin -uroot password root",
    require => Service["mysql"],
 
  }
 
  exec { "create-yii-database":
    unless  => "/usr/bin/mysql -uyii_app_dev -pyi_app_dev yii_app_dev",
    command => "/usr/bin/mysql -uroot -proot -e \"create database yii_app_dev; grant all on yii_app_dev.* to vagrant@localhost identified by 'yii_app_dev';\"",
    require => Service["mysql"],
  }
  exec { "create-cake-database":
    unless  => "/usr/bin/mysql -ucakeapp -pcakeapp cakeapp",
    command => "/usr/bin/mysql -uroot -proot -e \"create database cakeapp; grant all on cakeapp.* to vagrant@localhost identified by 'cakeapp';\"",
    require => Service["mysql"],
  }
}
 
 
include doinstall
include apache
include php
include mysql
