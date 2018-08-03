cd /var/www/html/firefly-iii/
sudo service mysql restart
sudo php artisan migrate:refresh --seed
sudo php artisan firefly:upgrade-database
sudo php artisan firefly:verify
sudo php artisan passport:install
sudo a2enmod rewrite
sudo service apache2 restart

echo "Edit apache conf file:"
echo "Search the line <Directory /var/www/> and change AllowOverride None to AllowOverride All"
echo "Restart apache: service apache2 restart"
echo "Go to http://localhost/firefly-iii/"
