# Script de creación de clientes

Escribe un script llamado crear_cliente.sh que va a automatizar la tarea de crear máquinas clientes a partir de la plantilla plantilla-cliente. Este script creará una nueva máquina con el nombre que le indiquemos, con un volumen con el tamaño que le indiquemos (y el sistema de ficheros redimensionado) y conectada a la red que le indiquemos. El script cambiará el hostname de la máquina para poner el mismo nombre que hemos indicado como nombre de la máquina virtual. Se deben añadir las claves ssh necesarias para el acceso por ssh. La nueva máquina se debe iniciar. Utiliza la utilidad virt-customize para configurar la máquina antes de crearla.

Por lo tanto el script recibe los siguientes argumentos en la línea de comandos:

- Nombre: nombre de la nueva máquina y hostname.
- Tamaño del volumen: Tamaño del volumen que tendrá la nueva máquina.
- Nombre de la red a la que habrá que conectar la máquina.
