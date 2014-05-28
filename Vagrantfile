Vagrant.configure("2") do |config|
	config.vm.box = "precise64"
	config.vm.box_url = "http://files.vagrantup.com/precise64.box"
	config.vm.hostname = "grafana.dev"

	config.vm.network :private_network, ip: "192.168.56.108"
	config.vm.network "forwarded_port", guest: 9200, host: 9200 # elasticsearch
	config.vm.network "forwarded_port", guest: 8125, host: 8125 # statsd

	config.ssh.forward_agent = true

	config.vm.provider :virtualbox do |v|
		v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
		v.customize ["modifyvm", :id, "--memory", 1024]
	end

	config.vm.synced_folder ".", "/var/www"
end
