#!/bin/sh
set -e

# Validar variable requerida
if [ -z "$LARAVEL_APP_URL" ]; then
    echo "ERROR: La variable LARAVEL_APP_URL es requerida."
    echo "Configúrala en las variables de entorno de Render."
    echo "Ejemplo: LARAVEL_APP_URL=https://mi-app.com"
    exit 1
fi

# Valores por defecto
PORT=${PORT:-8080}
MAX_UPLOAD_SIZE=${MAX_UPLOAD_SIZE:-100}
PROXY_TIMEOUT=${PROXY_TIMEOUT:-60}

# Extraer el backend de LARAVEL_APP_URL
# Ejemplo: http://servidor.com:8000 -> servidor.com:8000
LARAVEL_BACKEND=$(echo $LARAVEL_APP_URL | sed -e 's|^[^/]*//||' -e 's|/$||')

# Extraer solo el hostname (sin puerto) para el header Host
# Ejemplo: https://servidor.com:443 -> servidor.com
LARAVEL_HOST=$(echo $LARAVEL_BACKEND | sed -e 's|:.*||')

# Imprimir configuración para debugging
echo "========================================="
echo "Proxy Reverso Simplificado (v2)"
echo "Control de rutas en Laravel"
echo "========================================="
echo "Puerto: $PORT"
echo "Aplicación Laravel: $LARAVEL_APP_URL"
echo "Backend: $LARAVEL_BACKEND"
echo "Host: $LARAVEL_HOST"
echo "Tamaño máx. upload: ${MAX_UPLOAD_SIZE}M"
echo "Timeout: ${PROXY_TIMEOUT}s"
echo "========================================="

# Exportar variables para envsubst
export PORT
export MAX_UPLOAD_SIZE
export PROXY_TIMEOUT
export LARAVEL_BACKEND
export LARAVEL_HOST
export LARAVEL_APP_URL

envsubst '${PORT} ${MAX_UPLOAD_SIZE} ${PROXY_TIMEOUT} ${LARAVEL_BACKEND} ${LARAVEL_HOST} ${LARAVEL_APP_URL}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Configurar PHP-FPM para usar socket unix
echo "Configurando PHP-FPM..."
mkdir -p /run/php
sed -i 's|listen = 127.0.0.1:9000|listen = /run/php/php-fpm.sock|g' /etc/php83/php-fpm.d/www.conf
sed -i 's|;listen.owner = nobody|listen.owner = nginx|g' /etc/php83/php-fpm.d/www.conf
sed -i 's|;listen.group = nobody|listen.group = nginx|g' /etc/php83/php-fpm.d/www.conf
sed -i 's|;listen.mode = 0660|listen.mode = 0660|g' /etc/php83/php-fpm.d/www.conf

# Iniciar PHP-FPM en background
echo "Iniciando PHP-FPM..."
php-fpm83 &

# Verificar configuración de Nginx
echo "Verificando configuración de Nginx..."
nginx -t

# Iniciar Nginx
echo "Iniciando Nginx..."
exec nginx -g "daemon off;"
