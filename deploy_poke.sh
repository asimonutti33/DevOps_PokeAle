#!/bin/bash

set -e

# VARIABLES
APP_NAME="pokeale"
APP_DIR="/var/www/html/${APP_NAME}"
NGINX_CONF="/etc/nginx/sites-available/${APP_NAME}"
INDEX_FILE="${APP_DIR}/index.html"

# Detectar usuario de Nginx (www-data en Debian/Ubuntu, nginx en otros)
if id "www-data" &>/dev/null; then
    NGINX_USER="www-data"
elif id "nginx" &>/dev/null; then
    NGINX_USER="nginx"
else
    echo "⚠️ No se encontró usuario www-data ni nginx. Usando el usuario actual."
    NGINX_USER=$(whoami)
fi
echo "✅ Usuario de Nginx detectado: ${NGINX_USER}"

# 1 - Verificar/Instalar Nginx
if ! command -v nginx &> /dev/null; then
    echo "🔧 Nginx no está instalado. Procediendo a instalar..."
    sudo apt update
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "✅ Nginx instalado y ejecutándose."
else
    echo "✅ Nginx ya está instalado."
fi

# 2 - Crear directorio de la aplicación
echo "📁 Creando directorio ${APP_DIR}..."
sudo mkdir -p ${APP_DIR}

# 3 - Copiar el archivo HTML
if [ -f "./index.html" ]; then
    sudo cp ./index.html ${INDEX_FILE}
    echo "📄 Archivo index.html copiado correctamente."
else
    echo "❌ ERROR: No se encontró el archivo index.html en el directorio actual."
    exit 1
fi

# 4 - Asignar permisos con el usuario correcto
sudo chown -R ${NGINX_USER}:${NGINX_USER} ${APP_DIR}
sudo chmod -R 755 ${APP_DIR}
echo "🔒 Permisos asignados a ${NGINX_USER}"

# 5 - Configurar Nginx
echo "⚙️ Configurando Nginx..."
sudo tee ${NGINX_CONF} > /dev/null <<EOL
server {
    listen 80;
    server_name ${APP_NAME}.local;

    root ${APP_DIR};
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    access_log /var/log/nginx/${APP_NAME}_access.log;
    error_log /var/log/nginx/${APP_NAME}_error.log;
}
EOL

# 6 - Activar el sitio
if [ ! -L "/etc/nginx/sites-enabled/${APP_NAME}" ]; then
    sudo ln -s ${NGINX_CONF} /etc/nginx/sites-enabled/
    echo "🔗 Sitio habilitado."
else
    echo "ℹ️ El sitio ya estaba habilitado."
fi

# 7 - Validar configuración
echo "🔍 Validando configuración..."
sudo nginx -t

# 8 - Recargar Nginx
sudo systemctl reload nginx

# 9 - Mensaje final
echo "========================================="
echo "✅ ¡Despliegue completado con éxito!"
echo "🌐 Tu aplicación: http://${APP_NAME}.local"
echo "📂 Directorio: ${APP_DIR}"
echo "🔒 Usuario Nginx: ${NGINX_USER}"
echo "========================================="
echo "📍 También puedes acceder con: http://$(hostname -I | awk '{print $1}')"

