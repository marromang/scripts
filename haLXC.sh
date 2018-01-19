#!/bin/bash

# how to ckeck connection
#until fping $IP &>/dev/null
#do 
#	echo "No hay ping" 
#done

# check free mem
# lxc-info -n name -S | grep Memory | tr -f " " | cut -d " " -f 3 | cut -d "." -f 1

check_mem_1='OK'
# cont status
cont1_status=$(lxc-info -n cont1 -sH)

# if not running, start and add aditional disk
if [[ $cont_status != "RUNNING" ]];
then
	
	lxc-start -n cont1

	until  [[ $cont1_status == "RUNNING" ]]
		do
			echo "Up"
		done
	echo "fping"
	cont1_IP=$(lxc-info -n cont1 -iH)
	echo $cont1_IP
	until fping $cont1_IP
	do 
		echo "Initializing cont1."
	done

	echo "adding device"
	lxc-device -n cont1 add /dev/lxc/additional
	lxc-attach -n cont1 -- mount /dev/lxc/additional /var/www/html
	lxc-cgroup -n cont1 memory.limit_in_bytes 512M
else
	lxc-cgroup -n cont1 memory.limit_in_bytes 512M
cont1_IP=$(lxc-info -n cont1 -iH)
fi

#once the container is running, we add iptables rules so the web server can be seen from another host
iptables -F
iptables -t nat -D PREROUTING 1
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $cont1_IP:80

# once is up and running, check memory
while [[ $check_mem_1 == "OK" ]];
do
	cont1_mem=$(lxc-info -n cont1 -S | grep Memory | tr -s " " | cut -d " " -f 3 | cut -d "." -f 1)
	
	echo "Cheking memory on cont1"
	# if free memory is greater than 500, start migration
	if 	[[ $cont1_mem -ge '500' ]];
	then
		check_mem_1='NOT OK'
		
		# cont1 down
		lxc-stop -n cont1
		echo "attach1 1"
		# umount disk
		lxc-attach -n cont1 -- umount /dev/lxc/additional /var/www/html
		
		# cont2 up
		echo "starting cont2"
		lxc-start -n cont2
		
		cont2_status=$(lxc-info -n cont2 -sH)

		# check cont2 conn
		until  [[ "$cont2_status" == "RUNNING" ]]
		do
			sleep 1
		done

		cont2_IP=$(lxc-info -n cont2 -iH)

		until fping $cont2_IP
		do 
			echo "Initializing cont2."
		done
		
		# if there's connection, proceed
			# add disk
			lxc-device -n cont2 add /dev/lxc/additional
			lxc-attach -n cont2 -- mount /dev/lxc/additional /var/www/html
			
			# reload apache
			lxc-attach -n cont2 -- systemctl restart apache2

			# iptables
			iptables -F 
			iptables -t nat -D PREROUTING 1
			iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $cont2_IP:80
	fi
done	
		
# we'll suppose cont2 is only up and running if cont2 is down
# cont2 status

# get cont2 IP

# check connection

# once is up and running, check memory
	# if used memory is greater  than 1000, add memory limits
		# add memory limits
