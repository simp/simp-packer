# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |c|
  c.ssh.insert_key = false

  c.vm.define 'server' do |v|
    v.vm.hostname = 'puppet.test.net'
    v.vm.box = "simp-5.1.X-vagrant.box"
    v.vm.network "private_network",
      ip: "192.168.33.10",
      virtualbox__intnet: "test.net"
    v.ssh.username = 'vagrant'
    v.ssh.password = 'suP3rP@ssw0r!9371'
    v.vm.provider "virtualbox" do |vb|
      vb.memory = "3072"
      vb.cpus = "2"
    end
  end

  c.vm.define 'client' do |v|
    v.vm.box = "simp-5.1.X-client-vagrant.box"
    v.vm.hostname = "client.test.net"
    v.vm.network "forwarded_port", guest: 80, host: 8080
    v.vm.network "private_network",
      mac: "080027555555",
      virtualbox__intnet: "test.net",
      adapter: 2
    v.vm.boot_timeout = 720
    v.ssh.username = 'root'
    v.ssh.password = 'RootPassword'
    v.ssh.insert_key = 'false'
    v.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "2"
      vb.gui = "true"
      vb.customize [ "modifyvm", :id, "--boot1", "disk"]
      vb.customize [ "modifyvm", :id, "--boot2", "net"]
    end
  end
end
