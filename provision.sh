echo "$(tput setaf 2)starting to provision!!!$(tput sgr0)"

# update repos
sudo apt-get update
#sudo apt-get upgrade

# install necessary graphite software
echo "$(tput setaf 2)installing git, vim, python, apache, etc$(tput sgr0)"
sudo apt-get install -y vim git-core apache2 apache2-mpm-worker apache2-utils apache2.2-bin apache2.2-common libapr1 libaprutil1 libaprutil1-dbd-sqlite3 build-essential python3.2 python-dev libpython3.2 python3-minimal libapache2-mod-wsgi libaprutil1-ldap memcached python-cairo-dev python-django python-ldap python-memcache python-pysqlite2 sqlite3 erlang-os-mon erlang-snmp rabbitmq-server bzr expect libapache2-mod-python python-setuptools python-pip

# install python tools
echo "$(tput setaf 2)installing python tools$(tput sgr0)"
sudo easy_install django-tagging zope.interface txamqp

pip install 'Twisted<12.0'
easy_install django==1.5.8

cd /home/vagrant

# download graphite components
echo "$(tput setaf 2)downloading graphite components$(tput sgr0)"
wget https://launchpad.net/graphite/0.9/0.9.10/+download/graphite-web-0.9.10.tar.gz
wget https://launchpad.net/graphite/0.9/0.9.10/+download/carbon-0.9.10.tar.gz
wget https://launchpad.net/graphite/0.9/0.9.10/+download/whisper-0.9.10.tar.gz
tar -zxvf graphite-web-0.9.10.tar.gz
tar -zxvf carbon-0.9.10.tar.gz
tar -zxvf whisper-0.9.10.tar.gz
mv graphite-web-0.9.10 graphite
mv carbon-0.9.10 carbon
mv whisper-0.9.10 whisper
rm graphite-web-0.9.10.tar.gz
rm carbon-0.9.10.tar.gz
rm whisper-0.9.10.tar.gz

# install whisper
echo "$(tput setaf 2)installing whisper$(tput sgr0)"
cd /home/vagrant/whisper
sudo python setup.py install
 
# install carbon 
echo "$(tput setaf 2)installing carbon$(tput sgr0)"
cd /home/vagrant/carbon
sudo python setup.py install

# install graphite
echo "$(tput setaf 2)installing graphite$(tput sgr0)"
cd /home/vagrant/graphite
sudo python check-dependencies.py
sudo python setup.py install
 
# configure graphite 
echo "$(tput setaf 2)configuring graphite$(tput sgr0)"
sudo sed -i "s/SECRET_KEY = .*/SECRET_KEY = '88%1#_z#ffih!$ffdj48qrl*j_#9d$j$6w36$32(y!4=#izxb%'/" /opt/graphite/webapp/graphite/app_settings.py
echo "ALLOWED_HOSTS = ['graphite.dev', '192.168.56.108']" >> /opt/graphite/webapp/graphite/app_settings.py
cd /opt/graphite/conf
sudo cp carbon.conf.example carbon.conf
sudo cp storage-schemas.conf.example storage-schemas.conf
echo "[stats]
pattern = ^stats.*
retentions = 10s:6h,1m:7d,10m:5y" > /opt/graphite/conf/storage-schemas.conf 

sudo touch /opt/graphite/conf/storage-aggregation.conf
echo "[count]
pattern = \.count$
aggregationMethod = sum
xFilesFactor = 0
 
[min]
pattern = \.min$
xFilesFactor = 0.1
aggregationMethod = min
 
[max]
pattern = \.max$
xFilesFactor = 0.1
aggregationMethod = max
 
[sum]
pattern = \.count$
xFilesFactor = 0
aggregationMethod = sum
 
[default_average]
pattern = .*
xFilesFactor = 0.5
aggregationMethod = average" > /opt/graphite/conf/storage-aggregation.conf
 
echo "$(tput setaf 2)creating graphite database$(tput sgr0)" 
sudo chown -R www-data:www-data /opt/graphite/storage/
cd /opt/graphite/webapp/graphite
sudo cp local_settings.py.example local_settings.py

# configure database
sudo echo "DATABASES = {
    'default': {
        'NAME': '/opt/graphite/storage/graphite.db',
        'ENGINE': 'django.db.backends.sqlite3',
        'USER': '',
        'PASSWORD': '',
        'HOST': '',
        'PORT': ''
    }
}" >> /opt/graphite/webapp/graphite/local_settings.py

# create database
sudo chown -R www-data:www-data /opt/graphite/storage
cd /opt/graphite/webapp/graphite/
sudo python manage.py syncdb

sudo chown www-data:www-data /opt/graphite/storage/graphite.db

# configure apache
echo "$(tput setaf 2)configuring apache$(tput sgr0)"
sudo a2enmod headers
cp /var/www/graphite.conf /etc/apache2/sites-available/graphite.conf
cp /var/www/grafana.conf /etc/apache2/sites-available/grafana.conf
sudo cp /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/graphite.wsgi
sudo mkdir /etc/httpd
sudo mkdir /etc/httpd/wsgi 
# echo "NameVirtualHost *:80" >> /etc/apache2/httpd.conf
/etc/apache2/sites-available
sudo a2ensite graphite.conf
sudo a2ensite grafana.conf

sudo rm -rf /etc/apache2/sites-enabled/000-default

# install node
echo "$(tput setaf 2)installing node$(tput sgr0)"
sudo apt-get install -y nodejs

# download statsd 
echo "$(tput setaf 2)downloading node$(tput sgr0)"
cd /home/vagrant
sudo git clone git://github.com/etsy/statsd.git
sudo cp /var/www/localConfig.js /home/vagrant/statsd/localConfig.js

# install java
echo "$(tput setaf 2)installing java$(tput sgr0)"
sudo apt-get install -y openjdk-7-jre-headless 

# install elasticsearch 
echo "$(tput setaf 2)downloading elasticsearch$(tput sgr0)"
sudo wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
 
sudo echo "deb http://packages.elasticsearch.org/elasticsearch/1.1/debian stable main" >> /etc/apt/sources.list
 
sudo apt-get update
 
echo "$(tput setaf 2)installing elasticsearch$(tput sgr0)" 
sudo apt-get install -y elasticsearch

# download grafana
echo "$(tput setaf 2)downloading grafana$(tput sgr0)"
cd /var/www
sudo git clone https://github.com/grafana/grafana.git

# install grafana
echo "$(tput setaf 2)installing grafana$(tput sgr0)"
sudo cp /var/www/grafanaConfig.js /var/www/grafana/src/config.js
sudo chown -R www-data:www-data /var/www/grafana

echo "$(tput setaf 2)creating start app command$(tput sgr0)"
sudo echo "#!/usr/bin/env bash

sudo service apache2 restart
sudo /opt/graphite/bin/carbon-cache.py start
sudo service elasticsearch start
sudo node /home/vagrant/statsd/stats.js /home/vagrant/statsd/localConfig.js &" > /usr/local/bin/startapp

sudo chmod +x /usr/local/bin/startapp

echo "$(tput setaf 2)starting app$(tput sgr0)"
/usr/local/bin/startapp

echo "$(tput setaf 2)done!!$(tput sgr0)"