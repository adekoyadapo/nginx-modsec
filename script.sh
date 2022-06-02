#!/bin/bash

# install nginx
sudo apt update
sudo apt upgrade
sudo apt install gnupg -y
echo -e "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ bionic nginx\ndeb-src http://nginx.org/packages/mainline/ubuntu/ bionic nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
sudo apt update
sudo apt install nginx -y

sudo mkdir -p /opt/nginx

# install modesecurity
sudo apt-get install bison build-essential ca-certificates curl dh-autoreconf doxygen \
  flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev \
  libpcre3-dev libpcre++-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales \
  lua5.3-dev pkg-config wget zlib1g-dev zlibc libgd-dev vim nano git -y

cd /opt && sudo git clone https://github.com/SpiderLabs/ModSecurity

cd ModSecurity
sudo git submodule init
sudo git submodule update
sudo ./build.sh
sudo ./configure
sudo make
sudo make install

cd /opt && sudo git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

cd /opt/nginx
sudo apt source nginx
sudo apt source nginx

cd /opt/nginx/nginx-1.21.6
sudo ./configure --add-dynamic-module=../../ModSecurity-nginx --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-1.21.6/debian/debuild-base/nginx-1.21.6=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie'

sudo make modules
sudo mkdir -p /etc/nginx/modules
sudo cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

sudo sed -i '3 i load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf

sudo rm -rf /usr/local/modsecurity-crs

sudo git clone https://github.com/coreruleset/coreruleset /usr/local/modsecurity-crs

sudo mv /usr/local/modsecurity-crs/crs-setup.conf.example /usr/local/modsecurity-crs/crs-setup.conf
sudo mv /usr/local/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/local/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
sudo mkdir -p /etc/nginx/modsec
sudo cp /opt/ModSecurity/unicode.mapping /etc/nginx/modsec
sudo cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/nginx/modsec/modsecurity.conf
echo -e "Include /etc/nginx/modsec/modsecurity.conf\nInclude /usr/local/modsecurity-crs/crs-setup.conf\nInclude /usr/local/modsecurity-crs/rules/*.conf" | sudo tee /etc/nginx/modsec/main.conf

sudo sed -i '3 i \    modsecurity on;\n \   modsecurity_rules_file /etc/nginx/modsec/main.conf;' /etc/nginx/conf.d/default.conf

sudo nginx -t