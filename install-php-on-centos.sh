curl -o /etc/yum.repos.d/CentOS-Base.repo -s http://mirrors.aliyun.com/repo/Centos-7.repo
yum install -y epel-release
rpm -ivh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
rpm -ivh https://www.atomicorp.com/channels/atomic/centos/7/x86_64/RPMS/atomic-release-1.0-21.el7.art.noarch.rpm
yum install -y openssl-devel
yum install -y libtidy-devel
yum install -y curl-devel
yum install -y freetype-devel
yum install -y readline-devel
yum install -y libxml2-devel
yum install -y libicu-devel
yum install -y libxslt-devel
yum install -y libmcrypt-devel
yum install -y libpng-devel
yum install -y libjpeg-devel
yum install -y libssh2-devel
/usr/sbin/groupadd -f -g 510 php-fpm
/usr/sbin/useradd -m -u 510 -g 510 php-fpm
mkdir -p /data/src
mkdir -p /data/webroot && chown www-data:www-data /data/webroot
mkdir -p /data/webroot/runtimes && chown php-fpm:php-fpm /data/webroot/runtimes
mkdir -p /data/logs/php
cd /data/src
curl -o php-7.1.30.tgz -s https://www.php.net/distributions/php-7.1.30.tar.gz
curl -o redis-3.1.6.tgz -s http://pecl.php.net/get/redis-3.1.6.tgz
curl -o mongodb-1.5.5.tgz -s http://pecl.php.net/get/mongodb-1.5.5.tgz
curl -o imagick-3.1.2.tgz -s http://pecl.php.net/get/imagick-3.1.2.tgz
curl -o grpc-1.22.0.tgz -s http://pecl.php.net/get/grpc-1.22.0.tgz
curl -o composer-installer.php -s https://getcomposer.org/installer
tar -zxvf php-7.1.30.tgz
cd php-7.1.30
./configure \
  --prefix=/usr/local/php \
  --enable-fpm \
  --with-fpm-user=php-fpm \
  --with-fpm-group=php-fpm \
  --enable-sigchild \
  --disable-short-tags \
  --with-libxml-dir \
  --with-openssl \
  --with-pcre-regex \
  --with-zlib \
  --enable-calendar \
  --with-curl \
  --enable-exif \
  --with-jpeg-dir \
  --with-png-dir \
  --with-freetype-dir \
  --with-gd \
  --enable-gd-native-ttf \
  --with-gettext \
  --with-mhash \
  --enable-intl \
  --enable-mbstring \
  --with-mcrypt \
  --with-mysqli \
  --enable-pcntl \
  --with-pdo-mysql \
  --with-readline \
  --enable-shmop \
  --enable-soap \
  --enable-sockets \
  --enable-sysvmsg \
  --enable-sysvsem \
  --enable-sysvshm \
  --with-tidy \
  --with-xmlrpc \
  --with-xsl=DIR \
  --enable-zip \
  --enable-mysqlnd
make && make install
ln -s /usr/local/php/bin/* /usr/local/bin
cp php.ini-production /usr/local/php/lib/php.ini
sed -i "s/display_errors = Off/display_errors = On/" /usr/local/php/lib/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 1024M/" /usr/local/php/lib/php.ini
sed -i "s/short_open_tag = Off/short_open_tag = On/" /usr/local/php/lib/php.ini
sed -i "s/;date.timezone =/date.timezone =Asia\/Shanghai/" /usr/local/php/lib/php.ini
sed -i "s/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/" /usr/local/php/lib/php.ini
sed -i "s/;error_log = php_errors.log/error_log = \/data\/logs\/php\/php_errors.log/" /usr/local/php/lib/php.ini
touch /data/logs/php/php_errors.log
chown php-fpm:php-fpm /data/logs/php/php_errors.log
cd ..  && rm -rf php-7.1.30
php composer-installer.php && mv composer.phar /usr/local/bin/composer
composer global config -g repo.packagist composer https://mirrors.aliyun.com/composer  && composer global config secure-http false
su php-fpm -c "composer global config -g repo.packagist composer https://mirrors.aliyun.com/composer/"  && su php-fpm -c "composer global config secure-http false"
tar -zxvf grpc-1.22.0.tgz
cd grpc-1.22.0
/usr/local/php/bin/phpize ./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
echo "extension=grpc.so" >> /usr/local/php/lib/php.ini
cd .. && rm -rf grpc-1.22.0
tar -zxvf redis-3.1.6.tgz
cd redis-3.1.6
/usr/local/php/bin/phpize ./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
echo "extension=redis.so" >> /usr/local/php/lib/php.ini
cd .. && rm -rf redis-3.1.6
tar -zxvf mongodb-1.5.5.tgz
cd mongodb-1.5.5
/usr/local/php/bin/phpize ./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
echo "extension=mongodb.so" >> /usr/local/php/lib/php.ini
cd .. && rm -rf mongodb-1.5.5
cat > /usr/local/php/etc/php-fpm.conf <<EOF
[global]
error_log = /data/logs/php/fpm_errors.log
process.max = 128
daemonize = yes
include = etc/php-fpm.d/*.conf
EOF
mkdir -p /usr/local/php/etc/php-fpm.d
cat > /usr/local/php/etc/php-fpm.d/pool.conf <<EOF
[pool-1]
user = php-fpm
group = php-fpm
listen = 127.0.0.1:9000
pm = static
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
access.log = /data/logs/php/$pool.access.log
slowlog = /data/logs/php/$pool.log.slow
request_slowlog_timeout = 2
EOF
