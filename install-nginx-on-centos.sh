mkdir -p /data/src
mkdir -p /data/logs/nginx
/usr/sbin/groupadd -f -g 501 www-data
/usr/sbin/useradd -m -u 501 -g 501 www-data
cd /data/src
curl -o nginx-1.12.2.tar.gz http://nginx.org/download/nginx-1.12.2.tar.gz
tar -zxvf nginx-1.12.2.tar.gz
cd nginx-1.12.2
./configure \
  --prefix=/usr/local/nginx \
  --error-log-path=/data/logs/nginx/error.log \
  --http-log-path=/data/logs/nginx/access.log \
  --user=www-data \
  --group=www-data \
  --with-compat \
  --with-file-aio \
  --with-threads \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_mp4_module \
  --with-http_random_index_module \
  --with-http_realip_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_stub_status_module  \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-stream \
  --with-stream_realip_module \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module
make && make install
cd ..  && rm -rf nginx-1.12.2
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
mkdir -p /usr/local/nginx/conf/vhost
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
