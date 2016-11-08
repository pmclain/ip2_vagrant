#!/bin/bash

# Increase swap
swapsize=4000

# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
  echo 'swapfile not found. Adding swapfile.'
  sudo fallocate -l ${swapsize}M /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  sudo echo '/swapfile none swap defaults 0 0' >> /etc/fstab
else
  echo 'swapfile found. No changes made.'
fi

# output results to terminal
df -h
cat /proc/swaps
cat /proc/meminfo | grep Swap

sudo add-apt-repository ppa:ondrej/php
sudo apt-get update

# Install MySql
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password secret'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password secret'
sudo apt-get install -y mysql-server-5.6 

MYSQLAUTH="--user=root --password=secret"
mysql $MYSQLAUTH -e "GRANT ALL ON *.* TO root@'localhost' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql $MYSQLAUTH -e "CREATE USER 'ip2'@'localhost' IDENTIFIED BY 'secret';"
mysql $MYSQLAUTH -e "GRANT ALL ON *.* TO 'ip2'@'localhost' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql $MYSQLAUTH -e "GRANT ALL ON *.* TO 'ip2'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql $MYSQLAUTH -e "FLUSH PRIVILEGES;"
mysql $MYSQLAUTH -e "CREATE DATABASE ip2;"

# Install Apache, git, PHP
sudo apt-get install -y apache2 curl git php7.1 php7.1-mbstring php7.1-dom php7.1-curl php7.1-mysql zip unzip nodejs npm

sudo ln -s /usr/bin/nodejs /usr/bin/node

sudo npm install --global bower gulp

# Install Composer
cd
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === 'aa96f26c2b67226a324c27919f1eb05f21c248b987e6195cad9690d5c1ff713d53020a02ac8c217dbf90a7eacc9d141d') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

# Download IP2 from git repo
git config --global user.email 'admin@localhost.dev'
git config --global user.name 'vagrant'
sudo mkdir /var/www/ip2
sudo chown -R vagrant:vagrant /var/www/ip2
cd /var/www/ip2/
git clone https://github.com/InvoicePlane/InvoicePlane-2.git
cd InvoicePlane-2
git checkout develop

cp /vagrant/configs/.env /var/www/ip2/InvoicePlane-2/

composer update
sudo npm install

php artisan migrate

sudo cp -f /vagrant/configs/000-default.conf /etc/apache2/sites-available/
sudo service apache2 restart
