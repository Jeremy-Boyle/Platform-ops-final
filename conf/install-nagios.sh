#/user/bin/bash
sudo apt-get update
sudo echo "postfix postfix/mailname string localhost" | debconf-set-selections
sudo echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
sudo apt-get install -y postfix
sudo apt-get -y install nginx apache2 nagios4 awscli python3-pip
wget https://raw.githubusercontent.com/asafs133/nagios_plugins/master/ecs_cluster_memory_cpu.py
pip3 install --upgrade awscli
pip3 install --upgrade awscli
sudo systemctl stop apache2
sudo systemctl stop nagios4
#Enable mods for nagios
sudo a2enmod rewrite
sudo a2enmod cgi
sudo a2enmod authz_groupfile
sudo a2enmod auth_digest
sudo htpasswd -b -c /etc/nagios4/htdigest.users Phantom Platform-Ops
#Force Apache to use port 8080
sudo sed -i '1s/.*/<VirtualHost *:8080>/' /etc/apache2/sites-enabled/000-default.conf
