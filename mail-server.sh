#!/bin/bash

# Colores para mejor legibilidad
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para solicitar información al usuario
get_input() {
    read -p "$1: " value
    echo $value
}

# Función para manejar errores
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Función para instalar el servidor de correo
install_mail_server() {
    # Solicitar información necesaria
    DOMAIN=$(get_input "Ingrese su nombre de dominio (ej: ejemplo.com)")
    HOSTNAME=$(get_input "Ingrese el hostname completo de su servidor (ej: mail.ejemplo.com)")
    SERVER_IP=$(get_input "Ingrese la IP de su servidor de correo")
    ADMIN_EMAIL=$(get_input "Ingrese el email del administrador")
    DB_HOST=$(get_input "Ingrese la IP de su servidor de base de datos")
    DB_NAME=$(get_input "Ingrese el nombre de la base de datos para correos")
    DB_USER=$(get_input "Ingrese el nombre de usuario para la base de datos")
    DB_PASSWORD=$(get_input "Ingrese la contraseña para el usuario de la base de datos")
    SMTP_USERNAME=$(get_input "Ingrese el nombre de usuario para autenticación SMTP")
    SMTP_PASSWORD=$(get_input "Ingrese la contraseña para autenticación SMTP")

    # Actualizar el sistema
    echo "Actualizando el sistema..."
    sudo apt update && sudo apt upgrade -y || handle_error "No se pudo actualizar el sistema"

    # Instalar Postfix, Dovecot y paquetes necesarios
    echo "Instalando Postfix, Dovecot y paquetes necesarios..."
    sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix postfix-mysql dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql mysql-server || handle_error "No se pudieron instalar los paquetes necesarios"

    # Configurar Postfix
    echo "Configurando Postfix..."
    sudo postconf -e "myhostname = $HOSTNAME"
    sudo postconf -e "mydestination = localhost"
    sudo postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
    sudo postconf -e "home_mailbox = Maildir/"
    sudo postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"
    sudo postconf -e "virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf"
    sudo postconf -e "virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf"
    sudo postconf -e "virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf"
    sudo postconf -e "smtpd_sasl_type = dovecot"
    sudo postconf -e "smtpd_sasl_path = private/auth"
    sudo postconf -e "smtpd_sasl_auth_enable = yes"
    sudo postconf -e "smtpd_tls_security_level = may"
    sudo postconf -e "smtpd_tls_auth_only = yes"
    sudo postconf -e "inet_interfaces = all"
    sudo postconf -e "inet_protocols = all"

    # Crear archivos de configuración para consultas MySQL de Postfix
    echo "Creando archivos de configuración para consultas MySQL de Postfix..."
    cat << EOF | sudo tee /etc/postfix/mysql-virtual-mailbox-domains.cf
user = $DB_USER
password = $DB_PASSWORD
hosts = $DB_HOST
dbname = $DB_NAME
query = SELECT 1 FROM virtual_domains WHERE name='%s'
EOF

    cat << EOF | sudo tee /etc/postfix/mysql-virtual-mailbox-maps.cf
user = $DB_USER
password = $DB_PASSWORD
hosts = $DB_HOST
dbname = $DB_NAME
query = SELECT 1 FROM virtual_users WHERE email='%s'
EOF

    cat << EOF | sudo tee /etc/postfix/mysql-virtual-alias-maps.cf
user = $DB_USER
password = $DB_PASSWORD
hosts = $DB_HOST
dbname = $DB_NAME
query = SELECT destination FROM virtual_aliases WHERE source='%s'
EOF

    # Configurar Dovecot
    echo "Configurando Dovecot..."
    sudo sed -i "s/#mail_location = .*/mail_location = maildir:~\/Maildir/" /etc/dovecot/conf.d/10-mail.conf
    sudo sed -i "s/#disable_plaintext_auth = .*/disable_plaintext_auth = yes/" /etc/dovecot/conf.d/10-auth.conf
    sudo sed -i "s/auth_mechanisms = .*/auth_mechanisms = plain login/" /etc/dovecot/conf.d/10-auth.conf

    cat << EOF | sudo tee -a /etc/dovecot/conf.d/10-auth.conf
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/vmail/%d/%n
}
EOF

    cat << EOF | sudo tee /etc/dovecot/dovecot-sql.conf.ext
driver = mysql
connect = host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';
EOF

    # Configurar la escucha de Dovecot
    sudo sed -i "s/#listen = .*/listen = *, ::/" /etc/dovecot/dovecot.conf

    # Crear usuario y grupo vmail
    sudo groupadd -g 5000 vmail
    sudo useradd -g vmail -u 5000 vmail -d /var/vmail -m

    # Crear base de datos y tablas
    echo "Creando base de datos y tablas..."
    sudo mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD << EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;

CREATE TABLE IF NOT EXISTS \`virtual_domains\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`name\` varchar(50) NOT NULL,
  PRIMARY KEY (\`id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS \`virtual_users\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`domain_id\` int(11) NOT NULL,
  \`password\` varchar(106) NOT NULL,
  \`email\` varchar(100) NOT NULL,
  PRIMARY KEY (\`id\`),
  UNIQUE KEY \`email\` (\`email\`),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS \`virtual_aliases\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`domain_id\` int(11) NOT NULL,
  \`source\` varchar(100) NOT NULL,
  \`destination\` varchar(100) NOT NULL,
  PRIMARY KEY (\`id\`),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO \`virtual_domains\` (\`id\`, \`name\`) VALUES ('1', '$DOMAIN');
INSERT INTO \`virtual_users\` (\`id\`, \`domain_id\`, \`password\`, \`email\`)
VALUES ('1', '1', ENCRYPT('$SMTP_PASSWORD', CONCAT('\$6\$', SUBSTRING(SHA(RAND()), -16))), '$SMTP_USERNAME@$DOMAIN');
EOF

    # Reiniciar servicios
    echo "Reiniciando servicios..."
    sudo systemctl restart postfix dovecot

    echo -e "${GREEN}Instalación completada.${NC}"
    echo "Dominio: $DOMAIN"
    echo "Hostname: $HOSTNAME"
    echo "IP del servidor: $SERVER_IP"
    echo "IP de la base de datos: $DB_HOST"
    echo "Email de administrador: $ADMIN_EMAIL"
    echo "Usuario SMTP: $SMTP_USERNAME@$DOMAIN"
    echo "Contraseña SMTP: $SMTP_PASSWORD"

    # Verificar la instalación
    echo "Verificando la instalación..."
    if sudo systemctl is-active --quiet postfix && sudo systemctl is-active --quiet dovecot; then
        echo -e "${GREEN}Los servicios Postfix y Dovecot están activos.${NC}"
    else
        echo -e "${RED}Hubo un problema al iniciar los servicios. Por favor, revise los logs para más detalles.${NC}"
    fi
}

# Función para desinstalar el servidor de correo
uninstall_mail_server() {
    echo -e "${YELLOW}Desinstalando el servidor de correo...${NC}"
    
    # Detener servicios
    sudo systemctl stop postfix dovecot

    # Desinstalar paquetes
    sudo apt-get remove --purge postfix postfix-mysql dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql -y
    sudo apt-get autoremove -y
    sudo apt-get autoclean

    # Eliminar archivos de configuración
    sudo rm -rf /etc/postfix
    sudo rm -rf /etc/dovecot

    # Eliminar base de datos (opcional)
    read -p "¿Desea eliminar la base de datos de correos? (s/n): " delete_db
    if [[ $delete_db == "s" || $delete_db == "S" ]]; then
        DB_HOST=$(get_input "Ingrese la IP del servidor de base de datos")
        DB_NAME=$(get_input "Ingrese el nombre de la base de datos de correos")
        DB_USER=$(get_input "Ingrese el nombre de usuario de la base de datos")
        DB_PASSWORD=$(get_input "Ingrese la contraseña de la base de datos")
        sudo mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e "DROP DATABASE IF EXISTS $DB_NAME;"
    fi

    echo -e "${GREEN}Desinstalación completada.${NC}"
}

# Función para agregar un usuario de correo
add_mail_user() {
    DB_HOST=$(get_input "Ingrese la IP del servidor de base de datos")
    DB_NAME=$(get_input "Ingrese el nombre de la base de datos de correos")
    DB_USER=$(get_input "Ingrese el nombre de usuario de la base de datos")
    DB_PASSWORD=$(get_input "Ingrese la contraseña de la base de datos")
    NEW_USER=$(get_input "Ingrese el nombre de usuario para el nuevo correo (sin @dominio)")
    DOMAIN=$(get_input "Ingrese el dominio para el nuevo correo")
    PASSWORD=$(get_input "Ingrese la contraseña para el nuevo usuario")

    # Insertar nuevo usuario en la base de datos
    sudo mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME << EOF
INSERT INTO \`virtual_users\` (\`domain_id\`, \`password\`, \`email\`)
SELECT id, ENCRYPT('$PASSWORD', CONCAT('\$6\$', SUBSTRING(SHA(RAND()), -16))), '$NEW_USER@$DOMAIN'
FROM \`virtual_domains\` WHERE name='$DOMAIN';
EOF

    echo -e "${GREEN}Usuario $NEW_USER@$DOMAIN agregado exitosamente.${NC}"
}

# Función para eliminar un usuario de correo
remove_mail_user() {
    DB_HOST=$(get_input "Ingrese la IP del servidor de base de datos")
    DB_NAME=$(get_input "Ingrese el nombre de la base de datos de correos")
    DB_USER=$(get_input "Ingrese el nombre de usuario de la base de datos")
    DB_PASSWORD=$(get_input "Ingrese la contraseña de la base de datos")
    USER_EMAIL=$(get_input "Ingrese el email completo del usuario a eliminar")

    # Eliminar usuario de la base de datos
    sudo mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME -e "DELETE FROM \`virtual_users\` WHERE email='$USER_EMAIL';"

    echo -e "${GREEN}Usuario $USER_EMAIL eliminado exitosamente.${NC}"
}

# Menú principal
while true; do
    echo -e "\n${YELLOW}=== Menú de Gestión del Servidor de Correo ===${NC}"
    echo "1. Instalar servidor de correo"
    echo "2. Desinstalar servidor de correo"
    echo "3. Agregar usuario de correo"
    echo "4. Eliminar usuario de correo"
    echo "5. Salir"
    read -p "Seleccione una opción: " choice

    case $choice in
        1) install_mail_server ;;
        2) uninstall_mail_server ;;
        3) add_mail_user ;;
        4) remove_mail_user ;;
        5) echo -e "${GREEN}Saliendo...${NC}"; exit 0 ;;
        *) echo -e "${RED}Opción inválida. Por favor, intente de nuevo.${NC}" ;;
    esac
done
