StatsVM
=======

1. `vagrant up` the VM. 
2. `vagrant ssh` into the VM.
3. Go to the directory with the provisioning script, `cd /var/www`
4. Provision the VM, `sudo sh provision.sh`
5. Follow prompts to install software and create a django admin user
6. Create an entry in your host computer's hosts file `192.168.56.108 grafana.dev`
7. Start sending stats. Ex.`echo "accounts.authentication.login.attempted:1|c" | nc -w0 -u 192.168.56.108 8125`
8. Go to [grafana.dev](http://grafana.dev) and start creating grafts

### Notes
 - A globally available `startapp` executable will be created for you. This starts apache, elasticsearch, carbon, and statsd. You will need to execute this command if you halt and bring the vm back up.

 - Grafana will be available at [grafana.dev](http;//grafana.dev)
 
 - Graphite will be available at [http://192.168.56.108](http://192.168.56.108).

 - Elasticsearch will be available at [http://192.168.56.108:9200](http://192.168.56.108:9200).

 - StatsD will be available at `192.168.56.108:8125`.
