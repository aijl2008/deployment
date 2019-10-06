mkdir -p /data/src
cd /data/src
curl -o nginx-1.12.2.tar.gz -s http://nginx.org/download/nginx-1.12.2.tar.gz
curl -o php-7.1.30.tgz -s https://www.php.net/distributions/php-7.1.30.tar.gz
curl -o redis-3.1.6.tgz -s http://pecl.php.net/get/redis-3.1.6.tgz
curl -o mongodb-1.5.5.tgz -s http://pecl.php.net/get/mongodb-1.5.5.tgz
curl -o imagick-3.1.2.tgz -s http://pecl.php.net/get/imagick-3.1.2.tgz
curl -o grpc-1.22.0.tgz -s http://pecl.php.net/get/grpc-1.22.0.tgz
curl -o composer-installer.php -s https://getcomposer.org/installer
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
/usr/sbin/groupadd -f -g 501 www-data
/usr/sbin/groupadd -f -g 510 php-fpm
/usr/sbin/useradd -m -u 501 -g 501 www-data
/usr/sbin/useradd -m -u 510 -g 510 php-fpm
mkdir -p /data/webroot && chown www-data:www-data /data/webroot
mkdir -p /data/webroot/runtimes && chown php-fpm:php-fpm /data/webroot/runtimes
mkdir -p /data/logs/php
tar -zxvf php-7.1.30.tgz
cd php-7.1.30
./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=php-fpm --with-fpm-group=php-fpm --enable-sigchild --disable-short-tags --with-libxml-dir --with-openssl --with-pcre-regex --with-zlib --enable-calendar --with-curl --enable-exif --with-jpeg-dir --with-png-dir --with-freetype-dir --with-gd --enable-gd-native-ttf --with-gettext --with-mhash --enable-intl --enable-mbstring --with-mcrypt --with-mysqli --enable-pcntl --with-pdo-mysql --with-readline --enable-shmop --enable-soap --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-tidy --with-xmlrpc --with-xsl=DIR --enable-zip --enable-mysqlnd && \
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
tar -zxvf nginx-1.12.2.tar.gz
cd nginx-1.12.2
./configure --prefix=/usr/local/nginx --error-log-path=/data/logs/nginx/error.log --http-log-path=/data/logs/nginx/access.log --user=www-data --group=www-data --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module  --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module && \
make && make install
cd ..  && rm -rf nginx-1.12.2
cat > /usr/local/php/etc/php-fpm.conf <<EOF
[global]
error_log = /data/logs/php/fpm_errors.log
process.max = 128
daemonize = yes
include = etc/php-fpm.d/*.conf
EOF
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

cat > /usr/local/nginx/conf/nginx.conf  <<EOF
worker_processes  2;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    sendfile        on;
    keepalive_timeout  65;
    include vhost/*.conf
}
EOF
mkdir /usr/local/nginx/conf/vhost
cat > /usr/local/nginx/conf/vhost/default.conf <<EOF
server {
    listen 1979;
    server_name localhost;
    #listen 443 ssl;
    #ssl_certificate ssl/cert.pem;
    #ssl_certificate_key ssl/cert.key;
    charset utf-8;
    access_log  /data/logs/nginx/default.access.log  main;
    error_log  /data/logs/nginx/default.error.log;
    root /data/webroot/;
    autoindex on;
    location / {
        index index.html index.php;
        try_files $uri $uri/ /index.php?$args;
    }
    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|ico|js|css)$ {
        expires      30d;
        access_log off;
    }
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF    
