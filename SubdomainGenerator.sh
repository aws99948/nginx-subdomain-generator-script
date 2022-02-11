#!/bin/bash
#
# Bash script for generating new subdomain with a new server block in Nginx.

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$1'\e[m'; exit 1; }

# Variable definitions.
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/var/www'
NGINX_SCHEME='$scheme'
NGINX_REQUEST_URI='$request_uri'

# Sanity check.
[ $(id -g) != "0" ] && die "Script must be running as root."
[ $# != "2" ] && die "Usage: $(basename $0) subDomainName mainDomainName"

ok "Creating the config files for your subdomain."

# Create the Nginx config file.
cat > $NGINX_AVAILABLE_VHOSTS/$1 <<EOF
server {
    listen 80;
    server_name ram.com;
    
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

# Create {public,log} directories.
mkdir -p $WEB_DIR/$1/{public_html,logs}

# Create index.html file.
cat > $WEB_DIR/$1/public_html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
        <title>You are in the domain $1.$2</title>
        <meta charset="utf-8" />
</head>
<body class="container">
        <header><h1>You are in the domain $1.$2<h1></header>
        <div id="wrapper">
                This is the body of your domain page.
        </div>
        <br>
        <footer>© $(date +%Y)</footer>
</body>
</html>
EOF

# Change the folder permissions.
chown -R $USER:$WEB_USER $WEB_DIR/$1

# Enable site by creating symbolic link.
ln -s $NGINX_AVAILABLE_VHOSTS/$1 $NGINX_ENABLED_VHOSTS/$1

# Restart the Nginx server.
read -p "A restart to Nginx is required for the subdomain to be defined. Do you wish to restart nginx? (y/n): " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
  /etc/init.d/nginx restart;
fi

ok "domain is created for $1."
