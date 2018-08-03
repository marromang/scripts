# instalation of firefly-III web app on self hosted servers
# LAMP minus php
sudo apt install apache2 mysql-server

# php 7.2
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update
sudo apt-get install -y php7.2-fpm
sudo apt-get install -y php7.2
sudo apt-get -y install curl php7.2-pgsql php7.2-curl php7.2-json php7.2-mbstring php7.2-gd php7.2-intl php7.2-xml ph$
sudo systemctl disable apache2

# php libraries and CONNECTOR
sudo apt install -y php-bcmath php-curl php-zip php-gd php-xml php-mbstring php-mysql php-intl

# apache stuff
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php7.2-fpm
sudo systemctl reload apache2

#other packeages
sudo apt install curl

# install composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# main command of firefly install
cd /var/www/html/
composer create-project grumpydictator/firefly-iii --no-dev --prefer-dist firefly-iii 4.7.5.3

# initializa database
cd firefly-iii/

echo "Modify .env file."
echo "Config database"
