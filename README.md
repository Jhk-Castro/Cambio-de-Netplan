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

7. Para el script de Raid verificar que no tenga un montaje definido en esta carpeta 
   ```sh
   nano /etc/fstab
   ```
## Script: BD-mariadb.sh
Para esta instalación, tener en cuenta que lo instala de manera básica y que al reiniciar su servidor puede que lo tenga que reinstalar. 

## Script: 1er-cambio-ip.sh
Para el cambio de IP:


## Script: bind9_manager.sh
Para el uso de DNS por bind:


## Script: cms-web.sh
Para el CMS que se instale, antes instalar los paquetes de PHP:
    ```sh
    sudo apt-get install php php-mysql php-gd php-curl php-xml php-mbstring php-json php-zip php-fileinfo php-intl php-exif php-opcache php-imagick php-memcached php-soap php-ldap php-gmp
    ```

## Script: mail-server.sh
Para el servidor de correo:
- El `admin@tudominio.com` no tiene contraseña cuando se crea por primera vez con el script.
- Verificar tener la base de datos de mariadb activa.



