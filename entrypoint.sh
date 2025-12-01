#!/bin/sh
set -e

# Valores por defecto
PORT=${PORT:-8080}
MAX_UPLOAD_SIZE=${MAX_UPLOAD_SIZE:-100}
PROXY_TIMEOUT=${PROXY_TIMEOUT:-60}
BLOCKED_PATHS=${BLOCKED_PATHS:-^/\.env|^/\.git.*}

# Extraer el backend de LARAVEL_APP_URL
# Ejemplo: http://servidor.com:8000 -> servidor.com:8000
LARAVEL_BACKEND=$(echo $LARAVEL_APP_URL | sed -e 's|^[^/]*//||' -e 's|/$||')

# Extraer solo el hostname (sin puerto) para el header Host
# Ejemplo: https://servidor.com:443 -> servidor.com
LARAVEL_HOST=$(echo $LARAVEL_BACKEND | sed -e 's|:.*||')

# Si ALLOWED_PATHS está vacío, permitir todas las rutas
if [ -z "$ALLOWED_PATHS" ]; then
    ALLOWED_PATHS=".*"
    ALLOWED_DEFAULT="1"
else
    ALLOWED_DEFAULT="0"
fi

# Imprimir configuración para debugging
echo "========================================="
echo "Configuración del Proxy Reverso"
echo "========================================="
echo "Puerto: $PORT"
echo "Aplicación Laravel: $LARAVEL_APP_URL"
echo "Backend: $LARAVEL_BACKEND"
echo "Host: $LARAVEL_HOST"
echo "Rutas permitidas: $ALLOWED_PATHS"
echo "Rutas bloqueadas: $BLOCKED_PATHS"
echo "Tamaño máx. upload: ${MAX_UPLOAD_SIZE}M"
echo "Timeout: ${PROXY_TIMEOUT}s"
echo "Redirección raíz: ${ROOT_REDIRECT:-ninguna}"
echo "========================================="

# Reemplazar variables en la plantilla
export PORT
export MAX_UPLOAD_SIZE
export PROXY_TIMEOUT
export BLOCKED_PATHS
export ALLOWED_PATHS
export ALLOWED_DEFAULT
export LARAVEL_BACKEND
export LARAVEL_HOST
export LARAVEL_APP_URL
export ROOT_REDIRECT

envsubst '${PORT} ${MAX_UPLOAD_SIZE} ${PROXY_TIMEOUT} ${BLOCKED_PATHS} ${ALLOWED_PATHS} ${ALLOWED_DEFAULT} ${LARAVEL_BACKEND} ${LARAVEL_HOST} ${LARAVEL_APP_URL} ${ROOT_REDIRECT}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Verificar configuración de Nginx
echo "Verificando configuración de Nginx..."
nginx -t

# Iniciar Nginx
echo "Iniciando Nginx..."
exec nginx -g "daemon off;"
