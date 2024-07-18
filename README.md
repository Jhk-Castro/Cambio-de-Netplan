# Pasos Generales

1. Para cualquier archivo, dar permisos de ejecución:
    ```sh
    chmod +x "Nombre del archivo"
    ```

2. Para su ejecución:
    ```sh
    sudo ./"Nombre de su archivo".sh
    ```

3. Actualizar la lista de paquetes disponibles:
    ```sh
    apt update
    ```

4. Actualizar los paquetes instalados (si fuese necesario):
    ```sh
    apt upgrade
    ```

5. Verificar tener conexión a internet.

6. Cuando modificas algo en la base de datos de MariaDB, se debe reinstalar o verificar que la base de datos siga funcionando.

## Script: 1er-cambio-ip.sh
Para el cambio de IP:
- Utilizar el siguiente comando para los permisos del archivo:
    ```sh
    chmod +x 1er-cambio-ip.sh
    ```

## Script: bind9_manager.sh
Para el uso de DNS por bind:
- Utilizar el siguiente comando para los permisos del archivo:
    ```sh
    chmod +x bind9_manager.sh
    ```

## Script: cms-web.sh
Para el CMS que se instale, antes instalar los paquetes de PHP:
    ```sh
    sudo apt-get install php php-mysql php-gd php-curl php-xml php-mbstring php-json php-zip php-fileinfo php-intl php-exif php-opcache php-imagick php-memcached php-soap php-ldap php-gmp
    ```

## Script: mail-server.sh
Para el servidor de correo:
- El `admin@tudominio.com` no tiene contraseña cuando se crea por primera vez con el script.
- Utilizar el siguiente comando para los permisos del archivo:
    ```sh
    chmod +x mail-server.sh
    ```


