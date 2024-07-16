#!/bin/bash

# Función para instalar y configurar Apache
install_apache() {
    echo "Instalando Apache..."
    sudo apt-get update
    sudo apt-get install -y apache2

    # Solicitar el título de la página
    read -p "Ingrese el título para la página de prueba: " page_title

    # Crear una página HTML personalizada
    cat << EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$page_title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f0f0f0;
        }
        .container {
            text-align: center;
            padding: 20px;
            background-color: white;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$page_title</h1>
        <p>Si puedes ver esta página, Apache está funcionando correctamente.</p>
    </div>
</body>
</html>
EOF

    # Reiniciar Apache
    sudo systemctl restart apache2

    # Obtener la dirección IP del servidor
    server_ip=$(hostname -I | awk '{print $1}')

    echo "Apache ha sido instalado y configurado."
    echo "Puede acceder a la página de prueba en: http://$server_ip"
}

# Función para desinstalar Apache
uninstall_apache() {
    echo "Deteniendo y desinstalando Apache..."
    sudo systemctl stop apache2
    sudo apt-get remove --purge -y apache2
    sudo rm -rf /var/www/html
    echo "Apache ha sido detenido y desinstalado."
}

# Menú principal
echo "Seleccione una opción:"
echo "1. Instalar y configurar Apache"
echo "2. Desinstalar Apache"
read -p "Opción: " option

case $option in
    1) install_apache ;;
    2) uninstall_apache ;;
    *) echo "Opción no válida" ;;
esac
