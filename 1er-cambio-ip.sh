#!/bin/bash

CONFIG_FILE="/etc/netplan/00-installer-config.yaml"

set_static_ip() {
  read -p "Ingrese la dirección IP (formato: xxx.xxx.xxx.xxx/xx): " IP_ADDRESS
  read -p "Ingrese la puerta de enlace (formato: xxx.xxx.xxx.xxx): " GATEWAY
  read -p "Ingrese el servidor DNS (formato: xxx.xxx.xxx.xxx): " DNS

  sudo bash -c "cat > $CONFIG_FILE << EOL
network:
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - $IP_ADDRESS
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
          - $DNS
  version: 2
EOL"

  sudo netplan generate
  sudo netplan apply
  echo "Configuración de IP estática aplicada."
}

set_dynamic_ip() {
  sudo bash -c "cat > $CONFIG_FILE << EOL
network:
  ethernets:
    ens33:
      dhcp4: true
  version: 2
EOL"

  sudo netplan generate
  sudo netplan apply
  echo "Configuración de IP dinámica aplicada."
}

clear_config_file() {
  sudo bash -c "cat > $CONFIG_FILE << EOL
network:
  version: 2
EOL"
}

echo "Seleccione una opción:"
echo "1. Configurar IP estática"
echo "2. Configurar IP dinámica"
read -p "Opción [1-2]: " OPTION

case $OPTION in
  1)
    clear_config_file
    set_static_ip
    ;;
  2)
    clear_config_file
    set_dynamic_ip
    ;;
  *)
    echo "Opción inválida. Saliendo."
    ;;
esac
