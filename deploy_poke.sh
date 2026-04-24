#!/bin/bash

set -e  # Detiene el script si hay error

# VARIABLES
APP_NAME="pokeale"
APP_DIR="/var/www/html/${APP_NAME}"
NGINX_CONF="/etc/nginx/sites-available/${APP_NAME}"
INDEX_FILE="${APP_DIR}/index.html"

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

# 3 - Copiar el archivo HTML (ajusta la ruta de origen si es necesario)
#    Asumo que tu archivo pokeale.html está en el mismo directorio que el script
if [ -f "./pokeale.html" ]; then
    sudo cp ./pokeale.html ${INDEX_FILE}
    echo "📄 Archivo HTML copiado correctamente."
elif [ -f "./index.html" ]; then
    sudo cp ./index.html ${INDEX_FILE}
    echo "📄 Archivo index.html copiado correctamente."
else
    echo "⚠️  No se encontró el archivo HTML. Creando uno de prueba..."
    sudo tee ${INDEX_FILE} > /dev/null <<'HTML'
<!DOCTYPE html>
<html>
<head><title>Pokédex</title><meta charset="UTF-8"></head>
<body>
    <h1>Pokédex - Sube tu archivo HTML</h1>
    <p>Por favor, copia el código de la aplicación en este archivo.</p>
</body>
</html>
HTML
fi

# 4 - Asignar permisos correctos
sudo chown -R www-data:www-data ${APP_DIR}
sudo chmod -R 755 ${APP_DIR}

# 5 - Configurar Nginx (CORREGIDO)
echo "⚙️  Configurando Nginx..."
sudo tee ${NGINX_CONF} > /dev/null <<EOL
server {
    listen 80;
    server_name ${APP_NAME}.local;  # ← punto y coma y nombre válido

    root ${APP_DIR};
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;  # ← CORREGIDO para SPA
    }

    # Opcional: caché para assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Opcional: logs específicos
    access_log /var/log/nginx/${APP_NAME}_access.log;
    error_log /var/log/nginx/${APP_NAME}_error.log;
}
EOL

# 6 - Activar el sitio (habilitar si no está linkeado)
if [ ! -L "/etc/nginx/sites-enabled/${APP_NAME}" ]; then
    sudo ln -s ${NGINX_CONF} /etc/nginx/sites-enabled/
    echo "🔗 Sitio habilitado."
else
    echo "ℹ️  El sitio ya estaba habilitado."
fi

# 7 - Validar configuración de Nginx
echo "🔍 Validando configuración..."
sudo nginx -t

# 8 - Recargar Nginx (más suave que restart)
sudo systemctl reload nginx

# 9 - Mensaje final
echo "========================================="
echo "✅ ¡Despliegue completado con éxito!"
echo "🌐 Tu aplicación: http://${APP_NAME}.local"
echo "📂 Directorio: ${APP_DIR}"
echo "========================================="

# Extra: mostrar IP local útil
echo "📍 También puedes acceder con: http://$(hostname -I | awk '{print $1}')"

