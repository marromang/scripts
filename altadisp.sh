#!/bin/bash
#DATOS PUESTOS A MANO DURANTE LA CONFIGURACIÓN
ip_mv1='192.168.122.94'
ip_mv2='192.168.122.93'
flagmv1='correcto'
flagmv2='correcto'

unset SSH_AUTH_SOCK
unset KRB5CCNAME
ç
echo 'Configurando la red...'
ip l add br0 type bridge
ip a add 192.168.122.3/24 dev br0
ip l set br0 up


#levantar mv1
virsh start mv1

#reglas de iptables en anfitrion:
/sbin/iptables -F
/sbin/iptables -I FORWARD -d 192.168.122.94 -p tcp --dport 22 -j ACCEPT
/sbin/iptables -I FORWARD -d 192.168.122.94 -p tcp --dport 80 -j ACCEPT
ip r del 192.168.122.0/24 dev virbr0 proto kernel scope link src 192.168.122.1

#comprobar conexion a ssh
echo 'Prueba de conexion:'
/sbin/iptables -L
sleep 15
msg=$(/usr/bin/ssh -i ~/cron-rsa root@192.168.122.94 echo 'conectado')
echo $msg

if [[ $msg == 'conectado' ]];
then
	echo 'Prueba realizada con exito.'
	while [[ $flagmv1 == 'correcto' ]]; do
		#se comprueba la memoria
		echo 'Comprobando...'

		memoria=$(/usr/bin/ssh -i ~/cron-rsa root@192.168.122.94 free -m | grep 'Mem' | tr -s " " ";"| cut -d ";" -f 4)
		if [[ $memoria -le '100' ]];
		then
			echo 'La memoria de la maquina 1 está llena. Se va a cambiar a la máquina 2.'
			#desasociamos el volumen 
			/usr/bin/ssh -i ~/cron-rsa root@192.168.122.94 umount /mnt
			virsh -c qemu:///system detach-disk mv1 /dev/logVol/mv1
			#se apaga la maquina
			virsh shutdown mv1

			#se redimensiona el volumen
			
			/sbin/lvextend -L +1G /dev/logVol/mv1
			/bin/mount /dev/logVol/mv1 /mnt
			/sbin/xfs_growfs /dev/logVol/mv1
			/bin/umount /mnt

			#se incia la maquina 2
			echo 'Iniciando mv2'
			virsh start mv2
			sleep 30

			#cambio de reglas de iptables
			echo 'Reglas de iptables'
			/sbin/iptables -F
			/sbin/iptables -I FORWARD -d 192.168.122.93 -p tcp --dport 22 -j ACCEPT
			/sbin/iptables -I FORWARD -d 192.168.122.93 -p tcp --dport 80 -j ACCEPT

			#asociar el nuevo volumen
			virsh -c qemu:///system attach-disk mv2 /dev/logVol/mv1 vdb

			#montar para que los datos de la web vayan a /var/www/html/
			/usr/bin/ssh -i ~/cron-rsa root@192.168.122.93 mount /dev/vdb /var/www/

			echo 'Cambio realizado.'
			flagmv1='error'
		fi
	done

	while [[ $flagmv2 == 'correcto' ]]; do
		echo 'Comprobando...'
		#se comprueba la memoria
		mem=$(/usr/bin/ssh -i ~/cron-rsa root@192.168.122.93 free -m | grep 'Mem' | tr -s " " ";"| cut -d ";" -f 4)
		if [[ $mem -le '100' ]];
		then
			echo 'La memoria de la maquina 2 está llena. Se va a redimensionar.'

			#redimension en vivo
			virsh setmem mv2 --size 2G --live
			echo 'redimension hecha'
			#memoria redimensionada
			flagmv2='error'
		fi
	done
	echo 'FIN'
else 	
	echo 'No se ha podido conectar con la máquina.'
fi
