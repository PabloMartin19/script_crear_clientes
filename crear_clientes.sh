#!/bin/bash

# Comprobar que están los argumentos necesarios
if [ $# -ne 3 ]; then
    echo "Uso: $0 <nombre> <tamaño_volumen> <nombre_red>"
    exit 1
fi

NOMBRE=$1
TAMANIO=$2
RED=$3
PLANTILLA="/var/lib/libvirt/images/practica1.qcow2"
NUEVA_IMAGEN="/var/lib/libvirt/images/${NOMBRE}.qcow2"

# Crear una nueva imagen basada en la plantilla
echo "Creando una nueva imagen a partir de la plantilla con $TAMANIO de tamaño..."
sudo qemu-img create -f qcow2 -o backing_file=$PLANTILLA,backing_fmt=qcow2 $NUEVA_IMAGEN $TAMANIO
if [ $? -ne 0 ]; then
    echo "Error al crear la imagen $NUEVA_IMAGEN."
    exit 1
fi

# Redimensionar el sistema de ficheros en la nueva imagen
echo "Redimensionando el sistema de archivos..."
sudo virt-resize --expand /dev/sda1 $PLANTILLA $NUEVA_IMAGEN
if [ $? -ne 0 ]; then
    echo "Error al redimensionar el sistema de archivos en la imagen $NUEVA_IMAGEN."
    exit 1
fi

# Personalizar la imagen
echo "Personalizando la imagen $NUEVA_IMAGEN..."
sudo virt-customize -a $NUEVA_IMAGEN \
    --hostname $NOMBRE \
    --run-command "sed -i 's/^HOSTNAME=.*/$NOMBRE/' /etc/hostname" \
    --ssh-inject root:file:/home/$USER/.ssh/id_rsa.pub \
    --run-command "ssh-keygen -A" \
    --run-command "systemctl enable ssh" \
    --run-command "systemctl restart ssh" \
    --run-command "mkdir -p /home/pablo/.ssh && chmod 700 /home/pablo/.ssh" \
    --run-command "touch /home/pablo/.ssh/authorized_keys && chmod 600 /home/pablo/.ssh/authorized_keys" \
    --run-command "cat /root/.ssh/authorized_keys >> /home/pablo/.ssh/authorized_keys" \
    --run-command "chown -R pablo:pablo /home/pablo/.ssh" \
    --run-command "sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config" \
    --selinux-relabel

if [ $? -ne 0 ]; then
    echo "Error al personalizar la imagen $NUEVA_IMAGEN."
    exit 1
fi

# Convertir el tamaño del volumen a formato numérico
TAMANIO_G=$(echo $TAMANIO | sed 's/G//')

# Crear la máquina virtual
echo "Creando la máquina virtual $NOMBRE..."
sudo virt-install \
    --name $NOMBRE \
    --ram 2048 \
    --vcpus 2 \
    --disk path=$NUEVA_IMAGEN,format=qcow2,size=$TAMANIO_G \
    --network network=$RED \
    --import \
    --os-variant debian10 \
    --noautoconsole
if [ $? -ne 0 ]; then
    echo "Error al crear la máquina virtual $NOMBRE."
    exit 1
fi

# Esperar a que la máquina se inicie completamente
sleep 10

# Obtener la dirección IP de cliente2
BUSCAR_IP=$(sudo virsh domifaddr $NOMBRE --source agent | grep -oP '192\.168\.\d+\.\d+')

# Verifica si se obtuvo una IP válida
if [ -z "$BUSCAR_IP" ]; then
  echo "No se pudo obtener la IP de $NOMBRE"
  exit 1
fi

# Archivo de configuración SSH
SSH_CONFIG="/home/pavlo/.ssh/config"

# Añade la configuración al archivo ~/.ssh/config
echo "Añadiendo la configuración al archivo ~/.ssh/config"
cat <<EOL >> "$SSH_CONFIG"

Host $NOMBRE
  HostName $BUSCAR_IP
  User pablo
  ForwardAgent yes
  ProxyJump router

EOL

# Mensaje de éxito
echo "La configuración ha sido añadida correctamente!!!"

# Verificar el estado de la máquina
sudo virsh domstate $NOMBRE

echo "Máquina $NOMBRE creada y conectada a la red $RED con un volumen de $TAMANIO"

# Conectar por SSH y aceptar automáticamente la autenticidad del host
echo "Conectando a la máquina $NOMBRE por SSH..."
ssh -o StrictHostKeyChecking=no $NOMBRE
