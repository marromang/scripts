#!/bin/bash
#DATOS PUESTOS A MANO DURANTE LA CONFIGURACIÓN
ip_mv1='192.168.122.94'
ip_mv2='192.168.122.93'
flagmv1='correcto'
flagmv2='correcto'

echo 'Configurando la red...'
ip l add br0 type bridge
ip a add 192.168.122.3/24 dev br0
ip l set br0 up


#levantar mv1
virsh start mv1

echo 'Configuración de acceso por ssh: '


eval "$(ssh-agent -s)"
ssh-add /home/maria/.ssh/openstack


#reglas de iptables en anfitrion:
iptables -I FORWARD -d 192.168.122.94 -p tcp --dport 22 -j ACCEPT
iptables -I FORWARD -d 192.168.122.94 -p tcp --dport 80 -j ACCEPT

#comprobar conexion a ssh
echo 'Prueba de conexion:'
iptables -L
msg=$(ssh -i /home/maria/.ssh/openstack root@192.168.122.94 echo 'conectado')
if [[ $msg == 'conectado' ]];
then
	echo 'Prueba realizada con exito.'
	while [[ $flagmv1 == 'correcto' ]]; do
		#se comprueba la memoria
		echo 'Comprobando...'

		memoria=$(ssh -i /home/maria/.ssh/openstack root@192.168.122.94 free -m | grep 'Mem' | tr -s " " ";"| cut -d ";" -f 4)
		if [[ $memoria -le '10000' ]];
		then
			echo 'La memoria de la maquina 1 está llena. Se va a cambiar a la máquina 2.'
			#desasociamos el volumen 
			ssh -i home/maria/.ssh/openstack root@192.168.122.94 umount /mnt
			virsh -c qemu:///system detach-disk mv1 /dev/logVol/mv1
			#se apaga la maquina
			virsh shutdown mv1

			#se redimensiona el volumen
			
			lvextend -L +1G /dev/logVol/mv1
			mount /dev/logVol/mv1 /mnt
			xfs_growfs /dev/logVol/mv1
			umount /mnt

			#se incia la maquina 2
			echo 'Iniciando mv2'
			virsh start mv2
			sleep 30

			#cambio de reglas de iptables
			echo 'Reglas de iptables'
			iptables -F
			iptables -I FORWARD -d 192.168.122.93 -p tcp --dport 22 -j ACCEPT
			iptables -I FORWARD -d 192.168.122.93 -p tcp --dport 80 -j ACCEPT

			#asociar el nuevo volumen
			virsh -c qemu:///system attach-disk mv2 /dev/logVol/mv1 vdb

			#montar para que los datos de la web vayan a /var/www/html/
			ssh -i /home/maria/.ssh/openstack root@192.168.122.93 mount /dev/vdb /var/

			echo 'Cambio realizado.'
			flagmv1='error'
		fi
	done

	while [[ $flagmv2 == 'correcto' ]]; do
		#se comprueba la memoria
		mem=$(ssh -i /home/maria/.ssh/openstack root@192.168.122.93 free -m | grep 'Mem' | tr -s " " ";"| cut -d ";" -f 4)
		if [[ $mem -le '10000' ]];
		then
			echo 'La memoria de la maquina 2 está llena. Se va a redimensionar.'

			#redimension en vivo
			virsh setmem mv2 --size 2G --live

			#memoria redimensionada
			flagmv2='error'
		fi
	done
	echo 'Informacion de mv1: '
	virsh dominfo mv1
	echo 'Informacion de mv2: '
	virsh dominfo mv2

else 	
	echo 'No se ha podido conectar con la máquina.'
fi
