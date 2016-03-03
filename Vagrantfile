# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "simp-5.1.X-vagrant.box"
  config.vm.hostname = "simp.test.net"

  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.33.10", virtualbox__intnet: "test.net"

  config.ssh.username = 'simp'
  config.ssh.password = 'suP3rP@ssw0r!9371'
  config.ssh.insert_key = 'false'
  #config.ssh.shell = '/bin/su root'
  #config.ssh.sudo_command = '/bin/su root %c'

  #config.vm.synced_folder "./", "/root/vagrant",
  #  owner: 'root',
  #  group: 'root'

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072"
    vb.cpus = "2"

    # enable custom boot order: PXEboot, disk, optical
    vb.customize [ "modifyvm", :id, "--boot1", "net"]
    vb.customize [ "modifyvm", :id, "--boot2", "disk"]
    vb.customize [ "modifyvm", :id, "--boot3", "dvd"]
  end

  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end
