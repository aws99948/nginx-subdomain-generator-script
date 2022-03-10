#!/bin/bash
#
# Bash script for generating new domain with a new server block in Nginx.

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$1'\e[m'; exit 1; }

# Variable definitions.
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
# Sanity check.
[ $(id -g) != "0" ] && die "Script must be running as root."
[ $# != "1" ] && die "Usage: $(basename $0) subDomainName mainDomainName"

ok "Creating the config files for your domain."

# Create the Nginx config file.
cat > $NGINX_AVAILABLE_VHOSTS/$1.conf <<EOF
server {
    listen 80;
    server_name $1;
    
    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_max_temp_file_size 0;
        proxy_pass http://api_server/;
        proxy_redirect off;
        proxy_read_timeout 240s;
    }
}

EOF
# Enable site by creating symbolic link.
ln -s $NGINX_AVAILABLE_VHOSTS/$1.conf $NGINX_ENABLED_VHOSTS/$1.conf

# Restart the Nginx server.
service nginx reload ;
ok "subdomain is created for $1."
