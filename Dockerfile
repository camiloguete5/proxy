FROM nginx:alpine

# Instalar gettext, PHP y curl
RUN apk add --no-cache gettext php83 php83-fpm php83-curl php83-json php83-openssl curl

# Copiar plantilla de configuración de nginx
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Copiar script proxy de Telegram
COPY telegram-proxy.php /var/www/html/telegram-proxy.php

# Copiar script de inicio
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Crear directorios para logs, cache y PHP
RUN mkdir -p /var/log/nginx /var/cache/nginx /var/www/html /run/php

# Exponer el puerto (Render usa la variable de entorno PORT)
EXPOSE 8080

CMD ["/entrypoint.sh"]
