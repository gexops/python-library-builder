#!/bin/bash

# This script is used to bootstrap the nginx configuration for the lotus node.

CUSTOM_NGINX_CONFIG_FILE=${CUSTOM_NGINX_CONFIG_FILE:-/frontend/nginx.conf}
NGINX_CONFIG_FILE=${NGINX_CONFIG_FILE:-/etc/nginx/conf.d/default.conf}

BACKEND_API_HOST=${BACKEND_API_HOST:-backend}
BACKEND_API_PORT=${BACKEND_API_PORT:-8000}

FRONTEND_PORT=${FRONTEND_PORT:-80}

function create_nginx_config(){
    echo " - Copying: $CUSTOM_NGINX_CONFIG_FILE -> $NGINX_CONFIG_FILE"
    echo " - Nginx Timeout: $NGINX_TIMEOUT"
    cat $CUSTOM_NGINX_CONFIG_FILE | sed "s|BACKEND_API_PORT|${BACKEND_API_PORT}|g" | sed "s|BACKEND_API_HOST|${BACKEND_API_HOST}|g" | sed "s|FRONTEND_PORT|${FRONTEND_PORT}|g" | cat > $NGINX_CONFIG_FILE
    if [[ -f "/etc/nginx/sites-enabled/default" ]]; then
        rm /etc/nginx/sites-enabled/default
    fi
}

create_nginx_config

# run nginx
nginx -g daemon off;
