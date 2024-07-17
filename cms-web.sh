#!/bin/bash

# Función para instalar WordPress
install_wordpress() {
    echo "Instalando WordPress..."
    
    # Solicitar información necesaria
    read -p "Ingrese el nombre de la base de datos para WordPress: " db_name
    read -p "Ingrese el usuario de la base de datos: " db_user
    read -p "Ingrese la contraseña de la base de datos: " db_pass
    
    # Crear base de datos y usuario
    sudo mysql -e "CREATE DATABASE $db_name;"
    sudo mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    # Descargar y configurar WordPress
    cd /var/www/html
    sudo wget https://wordpress.org/latest.tar.gz
    sudo tar -xzvf latest.tar.gz
    sudo mv wordpress/* .
    sudo rm -rf wordpress latest.tar.gz
    
    # Configurar wp-config.php
    sudo cp wp-config-sample.php wp-config.php
    sudo sed -i "s/database_name_here/$db_name/" wp-config.php
    sudo sed -i "s/username_here/$db_user/" wp-config.php
    sudo sed -i "s/password_here/$db_pass/" wp-config.php
    
    # Establecer permisos
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    
    echo "WordPress instalado. Por favor, complete la instalación en su navegador."
}

# Función para instalar Drupal
install_drupal() {
    echo "Instalando Drupal..."
    
    # Solicitar información necesaria
    read -p "Ingrese el nombre de la base de datos para Drupal: " db_name
    read -p "Ingrese el usuario de la base de datos: " db_user
    read -p "Ingrese la contraseña de la base de datos: " db_pass
    
    # Crear base de datos y usuario
    sudo mysql -e "CREATE DATABASE $db_name;"
    sudo mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    # Descargar y configurar Drupal
    cd /var/www/html
    sudo wget https://www.drupal.org/download-latest/tar.gz -O drupal.tar.gz
    sudo tar -xzvf drupal.tar.gz
    sudo mv drupal-*/* .
    sudo rm -rf drupal-* drupal.tar.gz
    
    # Establecer permisos
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    
    echo "Drupal instalado. Por favor, complete la instalación en su navegador."
}

# Función para instalar Joomla
install_joomla() {
    echo "Instalando Joomla..."
    
    # Solicitar información necesaria
    read -p "Ingrese el nombre de la base de datos para Joomla: " db_name
    read -p "Ingrese el usuario de la base de datos: " db_user
    read -p "Ingrese la contraseña de la base de datos: " db_pass
    
    # Crear base de datos y usuario
    sudo mysql -e "CREATE DATABASE $db_name;"
    sudo mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    # Descargar y configurar Joomla
    cd /var/www/html
    sudo wget https://downloads.joomla.org/cms/joomla4/4-2-5/Joomla_4-2-5-Stable-Full_Package.tar.gz -O joomla.tar.gz
    sudo tar -xzvf joomla.tar.gz
    sudo mv joomla/* .
    sudo rm -rf joomla joomla.tar.gz
    
    # Establecer permisos
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    
    echo "Joomla instalado. Por favor, complete la instalación en su navegador."
}

# Función para desinstalar CMS
uninstall_cms() {
    echo "Desinstalando CMS..."
    
    # Eliminar archivos
    sudo rm -rf /var/www/html/*
    
    # Solicitar información de la base de datos
    read -p "Ingrese el nombre de la base de datos a eliminar: " db_name
    read -p "Ingrese el usuario de la base de datos a eliminar: " db_user
    
    # Eliminar base de datos y usuario
    sudo mysql -e "DROP DATABASE IF EXISTS $db_name;"
    sudo mysql -e "DROP USER IF EXISTS '$db_user'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    echo "CMS desinstalado y base de datos eliminada."
}

# Menú principal
echo "Seleccione una opción:"
echo "1. Instalar WordPress"
echo "2. Instalar Drupal"
echo "3. Instalar Joomla"
echo "4. Desinstalar CMS"
read -p "Opción: " option

case $option in
    1) install_wordpress ;;
    2) install_drupal ;;
    3) install_joomla ;;
    4) uninstall_cms ;;
    *) echo "Opción no válida" ;;
esac
