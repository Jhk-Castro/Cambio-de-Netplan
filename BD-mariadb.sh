#!/bin/bash

# Función para solicitar información al usuario
get_input() {
    read -p "$1: " value
    echo $value
}

# Función para manejar errores
handle_error() {
    echo "Error: $1"
    exit 1
}

# Función para instalar y configurar MariaDB
install_mariadb() {
    # Solicitar información necesaria
    DB_SERVER_IP=$(get_input "Ingrese la IP de su servidor MariaDB")
    DB_ROOT_PASSWORD=$(get_input "Ingrese la contraseña para el usuario root de MariaDB")
    DB_NAME=$(get_input "Ingrese el nombre de la base de datos a crear")
    DB_USER=$(get_input "Ingrese el nombre de usuario para la base de datos")
    DB_PASSWORD=$(get_input "Ingrese la contraseña para el usuario de la base de datos")

    # Actualizar el sistema
    echo "Actualizando el sistema..."
    sudo apt update && sudo apt upgrade -y || handle_error "No se pudo actualizar el sistema"

    # Desenmascara el servicio MariaDB si está enmascarado
    sudo systemctl unmask mariadb || true

    # Eliminar instalaciones previas de MariaDB
    echo "Eliminando instalaciones previas de MariaDB..."
    sudo apt-get purge mariadb-* -y || handle_error "No se pudo eliminar MariaDB"
    sudo apt-get autoremove -y || handle_error "No se pudo ejecutar autoremove"
    sudo apt-get autoclean || handle_error "No se pudo ejecutar autoclean"

    # Instalar MariaDB y paquetes relacionados
    echo "Instalando MariaDB y paquetes relacionados..."
    sudo apt-get install mariadb-server mariadb-client libmariadb3 mariadb-backup mariadb-common -y || handle_error "No se pudo instalar MariaDB"

    # Iniciar y habilitar el servicio MariaDB
    echo "Iniciando y habilitando el servicio MariaDB..."
    sudo systemctl start mariadb || handle_error "No se pudo iniciar MariaDB"
    sudo systemctl enable mariadb || handle_error "No se pudo habilitar MariaDB"

    # Asegurar la instalación de MariaDB
    echo "Asegurando la instalación de MariaDB..."
    sudo mysql_secure_installation <<EOF || handle_error "No se pudo asegurar la instalación de MariaDB"
y
$DB_ROOT_PASSWORD
$DB_ROOT_PASSWORD
y
y
y
y
EOF

    # Crear base de datos y usuario
    echo "Creando base de datos y usuario..."
    sudo mysql -u root -p$DB_ROOT_PASSWORD <<EOF || handle_error "No se pudo crear la base de datos y el usuario"
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Configurar MariaDB para escuchar en la IP especificada
    echo "Configurando MariaDB para escuchar en $DB_SERVER_IP..."
    sudo sed -i "s/^#*bind-address.*/bind-address = $DB_SERVER_IP/" /etc/mysql/mariadb.conf.d/50-server.cnf || handle_error "No se pudo configurar la dirección de escucha"

    # Reiniciar MariaDB
    echo "Reiniciando MariaDB..."
    sudo systemctl restart mariadb || handle_error "No se pudo reiniciar MariaDB"

    echo "Instalación y configuración de MariaDB completada."
    echo "Base de datos: $DB_NAME"
    echo "Usuario: $DB_USER"
    echo "Contraseña: $DB_PASSWORD"
    echo "IP del servidor: $DB_SERVER_IP"

    # Verificar la instalación
    echo "Verificando la instalación..."
    if sudo mysql -u root -p$DB_ROOT_PASSWORD -e "SHOW DATABASES;" > /dev/null 2>&1; then
        echo "La instalación de MariaDB se ha completado con éxito."
    else
        echo "La instalación de MariaDB parece haber fallado. Por favor, revise los logs para más detalles."
    fi
}

# Función para desinstalar completamente MariaDB
uninstall_mariadb() {
    echo "Desinstalando MariaDB completamente..."
    
    # Detener el servicio MariaDB
    sudo systemctl stop mariadb

    # Desinstalar MariaDB y todos sus componentes
    sudo apt-get purge mariadb-* -y
    sudo apt-get autoremove -y
    sudo apt-get autoclean

    # Eliminar archivos de configuración residuales
    sudo rm -rf /etc/mysql /var/lib/mysql

    echo "MariaDB ha sido completamente desinstalado."
}

# Menú principal
while true; do
    echo ""
    echo "Menú de MariaDB"
    echo "1. Instalar y configurar MariaDB"
    echo "2. Desinstalar completamente MariaDB"
    echo "3. Salir"
    echo ""
    read -p "Seleccione una opción: " choice

    case $choice in
        1)
            install_mariadb
            ;;
        2)
            uninstall_mariadb
            ;;
        3)
            echo "Saliendo del script."
            exit 0
            ;;
        *)
            echo "Opción no válida. Por favor, seleccione una opción válida."
            ;;
    esac
done
