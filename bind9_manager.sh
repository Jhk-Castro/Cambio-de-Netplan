#!/bin/bash

# Función para instalar y configurar BIND9
install_bind9() {
    echo "Instalando BIND9..."
    sudo apt-get update
    sudo apt-get install -y bind9 bind9utils bind9-doc

    # Solicitar información
    read -p "Ingrese la dirección IP del servidor DNS: " ip_address
    read -p "Ingrese el nombre de dominio a resolver: " domain_name
    read -p "Ingrese la red en notación CIDR (ej. 192.168.1.0/24): " network_cidr

    # Extraer información de la red
    IFS='/' read -r network_address subnet_mask <<< "$network_cidr"
    reverse_zone=$(echo $network_address | awk -F. '{print $3"."$2"."$1}')

    # Configurar named.conf.options
    cat << EOF | sudo tee /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-recursion { any; };
    listen-on { $ip_address; };
    allow-transfer { none; };
};
EOF

    # Configurar named.conf.local
    cat << EOF | sudo tee /etc/bind/named.conf.local
zone "$domain_name" {
    type master;
    file "/etc/bind/zones/db.$domain_name";
};

zone "$reverse_zone.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.$reverse_zone";
};
EOF

    # Crear zona directa
    sudo mkdir -p /etc/bind/zones
    cat << EOF | sudo tee /etc/bind/zones/db.$domain_name
\$TTL    604800
@       IN      SOA     ns1.$domain_name. root.$domain_name. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$domain_name.
@       IN      A       $ip_address
ns1     IN      A       $ip_address
www     IN      A       $ip_address
mail    IN      A       $ip_address
ftp     IN      A       $ip_address
@       IN      MX  10  mail.$domain_name.
EOF

    # Crear zona inversa
    cat << EOF | sudo tee /etc/bind/zones/db.$reverse_zone
\$TTL    604800
@       IN      SOA     ns1.$domain_name. root.$domain_name. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$domain_name.
$(echo $ip_address | awk -F. '{print $4}')      IN      PTR     ns1.$domain_name.
$(echo $ip_address | awk -F. '{print $4}')      IN      PTR     www.$domain_name.
$(echo $ip_address | awk -F. '{print $4}')      IN      PTR     mail.$domain_name.
$(echo $ip_address | awk -F. '{print $4}')      IN      PTR     ftp.$domain_name.
EOF

    # Configurar resolv.conf
    echo "Configurando resolv.conf..."
    if systemctl is-active systemd-resolved >/dev/null 2>&1; then
        sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    else
        sudo cp /etc/resolv.conf /etc/resolv.conf.backup
        cat << EOF | sudo tee /etc/resolv.conf
nameserver $ip_address
search $domain_name
EOF
    fi

    if grep -q "nameserver $ip_address" /etc/resolv.conf && grep -q "search $domain_name" /etc/resolv.conf; then
        echo "resolv.conf actualizado correctamente"
    else
        echo "No se pudo actualizar resolv.conf automáticamente"
        echo "Por favor, agregue manualmente las siguientes líneas a /etc/resolv.conf:"
        echo "nameserver $ip_address"
        echo "search $domain_name"
    fi

    # Si usa NetworkManager, también configuramos allí
    if command -v nmcli >/dev/null 2>&1; then
        connection=$(nmcli -t -f NAME c show --active | head -n1)
        sudo nmcli con mod "$connection" ipv4.dns "$ip_address"
        sudo nmcli con mod "$connection" ipv4.dns-search "$domain_name"
        sudo nmcli con up "$connection"
    fi

    # Reiniciar BIND9
    sudo systemctl restart bind9

    # Crear carpeta con ubicaciones de archivos modificados
    sudo mkdir -p /etc/bind9_configs
    echo "/etc/bind/named.conf.options" | sudo tee /etc/bind9_configs/modified_files.txt
    echo "/etc/bind/named.conf.local" | sudo tee -a /etc/bind9_configs/modified_files.txt
    echo "/etc/bind/zones/db.$domain_name" | sudo tee -a /etc/bind9_configs/modified_files.txt
    echo "/etc/bind/zones/db.$reverse_zone" | sudo tee -a /etc/bind9_configs/modified_files.txt
    echo "/etc/resolv.conf" | sudo tee -a /etc/bind9_configs/modified_files.txt

    echo "BIND9 ha sido instalado y configurado. Los archivos modificados se encuentran listados en /etc/bind9_configs/modified_files.txt"
}

# Función para desinstalar BIND9
uninstall_bind9() {
    echo "Deteniendo y desinstalando BIND9..."
    sudo systemctl stop bind9
    sudo apt-get remove --purge -y bind9 bind9utils bind9-doc
    sudo rm -rf /etc/bind
    sudo rm -rf /etc/bind9_configs
    sudo mv /etc/resolv.conf.backup /etc/resolv.conf
    echo "BIND9 ha sido detenido y desinstalado."
}

# Menú principal
echo "Seleccione una opción:"
echo "1. Instalar y configurar BIND9"
echo "2. Desinstalar BIND9"
read -p "Opción: " option

case $option in
    1) install_bind9 ;;
    2) uninstall_bind9 ;;
    *) echo "Opción no válida" ;;
esac
