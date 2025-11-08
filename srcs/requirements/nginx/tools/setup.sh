#!/bin/bash

if [ ! -f "/etc/nginx/ssl/nginx.crt" ]; then
    echo "Generating SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=BR/ST=SP/L=SaoPaulo/O=42SP/CN=${DOMAIN_NAME}"
    
    chmod 600 /etc/nginx/ssl/nginx.key
    chmod 644 /etc/nginx/ssl/nginx.crt
    echo "SSL certificate generated!"
fi

exec "$@"