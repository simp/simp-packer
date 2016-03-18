# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "simp-5.1.X-vagrant.box"
  config.vm.hostname = "simp.test.net"

  config.vm.network "private_network",
    ip: "192.168.33.10",
    mac: "08002730D774",
    virtualbox__intnet: "test.net"

  config.ssh.username = 'simp'
  config.ssh.password = 'suP3rP@ssw0r!9371'
  config.ssh.insert_key = 'false'

  config.vm.provider "virtualbox" do |vb|
    vb.name = "SIMP 5.1.X Server"

    vb.memory = "3072"
    vb.cpus = "2"

    ## enable custom boot order: PXEboot, disk, optical
    #vb.customize [ "modifyvm", :id, "--boot1", "net"]
    #vb.customize [ "modifyvm", :id, "--boot2", "disk"]
    #vb.customize [ "modifyvm", :id, "--boot3", "dvd"]
  end
end
