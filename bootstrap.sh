#!/bin/bash -eux

apt-get update

apt-get -y install unzip
apt-get -y install apache2

# manage mysql passwords
touch /root/.my.cnf
chmod 600 /root/.my.cnf
MYSQLPASS=`openssl rand -base64 32`
WPMYSQLPASS=`openssl rand -base64 32`
echo "[client]" >> /root/.my.cnf
echo "password=$MYSQLPASS" >> /root/.my.cnf
echo "mysql-server mysql-server/root_password password $MYSQLPASS" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQLPASS" | sudo debconf-set-selections
# install mysql
apt-get -y install mysql-server
# setup wordpress user and database
mysql -u root -e "CREATE DATABASE WORDPRESS"
mysql -u root -e "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '$WPMYSQLPASS'"
mysql -u root -e "GRANT ALL PRIVILEGES ON  WORDPRESS.* TO 'wordpress'@'localhost'"
mysql -u root -e "FLUSH PRIVILEGES"
# install php
apt-get -y install php libapache2-mod-php php-mcrypt php-mysql
# for wp rest api plugin
cat << EOF >> /etc/apache2/apache2.conf
<Directory /var/www/html/>
    AllowOverride All
</Directory>
EOF
# so apache can handle enough connections 
cat << EOF > /etc/apache2/mods-enabled/mpm_prefork.conf
<IfModule mpm_prefork_module>
	StartServers		 5
	MinSpareServers		 5
	MaxSpareServers		 10
	MaxRequestWorkers	 500
	MaxConnectionsPerChild   0
</IfModule>
EOF

a2enmod rewrite
systemctl restart apache2
# apache needs to take index.php first
rm /var/www/html/index.html

useradd -m wordpress 
chown -R wordpress:www-data /var/www/html 
# wp cli will do the install and config of wp
wget -O /tmp/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /tmp/wp
mv /tmp/wp /usr/local/bin/wp

mkdir /tmp/install
cd /tmp/install
# if wp user password or blog name are customised 
source /vagrant/wpinstall
WP_USER=${WP_USER:-bob}
WP_PASSWORD=${WP_PASSWORD:-bob}
WP_BLOG=${WP_BLOG:-MyBlog}
# install  and configure wp
wp core download --version=4.6.1 --allow-root
wp core config --dbname=WORDPRESS --dbuser=wordpress --dbpass="$WPMYSQLPASS" --dbhost=localhost --allow-root
wp core install --url=192.168.33.10 --title="$WP_BLOG" --admin_user="$WP_USER" --admin_password="$WP_PASSWORD" --admin_email=bob@bob.com --skip-email --allow-root

touch .htaccess
chmod 664 .htaccess
chmod -R g+w wp-content/themes
chmod -R g+w wp-content/plugins
# rest api wp plugin
wget -O /tmp/rest-api.zip https://downloads.wordpress.org/plugin/rest-api.2.0-beta15.zip
unzip /tmp/rest-api.zip -d /tmp/install/wp-content/plugins 
# for simple auth 
wget -O /tmp/basic-auth.zip https://github.com/WP-API/Basic-Auth/archive/master.zip 
unzip /tmp/basic-auth.zip -d /tmp/install/wp-content/plugins 
# wp cli needs this
cat << EOF > wp-cli.yml
apache_modules:
   - mod_rewrite
EOF

cp -a /tmp/install/. /var/www/html
chown -R wordpress:www-data /var/www/html 
# pretty permalinks
wp rewrite structure '/%postname%/' --hard --path=/var/www/html --allow-root
# activate plugins in wp
sudo -iu wordpress wp plugin activate rest-api --path=/var/www/html
sudo -iu wordpress wp plugin activate Basic-Auth-master --path=/var/www/html
# firewall everything exept ssh and apache
ufw allow OpenSSH
ufw allow "Apache Full"
ufw --force enable
