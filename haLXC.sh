#!/bin/bash

# how to ckeck connection
#until fping $IP &>/dev/null
#do 
#	echo "No hay ping" 
#done

# check free mem
# lxc-info -n name -S | grep Memory | tr -f " " | cut -d " " -f 3 | cut -d "." -f 1

check_mem_1='OK'
check_mem_2='OK'
# cont status
cont1_status=$(lxc-info -n cont1 -sH)
echo $cont1_status
# if not running, start and add aditional disk
if [[ $cont_status != "RUNNING" ]];
then
	
	lxc-start -n cont1
	cont1_status=$(lxc-info -n cont1 -sH)
	echo $cont1_status

	until  [[ $cont1_status == "RUNNING" ]]
		do
			echo "Up"
		done
	echo $cont1_status


	echo "adding device"
	lxc-device -n cont1 add /dev/lxc/additional
	echo "1"
	lxc-attach -n cont1 -- mount /dev/lxc/additional /var/www/html
	echo "2"
	lxc-attach -n cont1 -- systemctl restart apache2

	echo "3"
	lxc-cgroup -n cont1 memory.limit_in_bytes 512M

else
	lxc-cgroup -n cont1 memory.limit_in_bytes 512M
	cont1_IP=$(lxc-info -n cont1 -iH)
fi

#once the container is running, we add iptables rules so the web server can be seen from another host
cont1_IP=$(lxc-info -n cont1 -iH)
echo $cont1_IP

sleep 5

iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $cont1_IP:80

echo "check website"
# once is up and running, check memory
while [[ $check_mem_1 == "OK" ]];
do
	cont1_mem=$(lxc-info -n cont1 -S | grep Memory | tr -s " " | cut -d " " -f 3 | cut -d "." -f 1)
	
	
	# if free memory is greater than 500, start migration
	if 	[[ $cont1_mem -ge '500' ]];
	then
		check_mem_1='NOT OK'
		
		# cont1 down
		echo "attach1 1"
		# umount disk
		# lxc-attach -n cont1 -- umount /dev/lxc/additional /var/www/html
		
		lxc-stop -n cont1
		# cont2 up
		echo "starting cont2"
		lxc-start -n cont2
		
		cont2_status=$(lxc-info -n cont2 -sH)

		# check cont2 conn
		until  [[ $cont2_status == "RUNNING" ]]
		do
			echo "Up"
		done

		# if there's connection, proceed
			# add disk
			lxc-cgroup -n cont2 memory.limit_in_bytes 1024M
			lxc-device -n cont2 add /dev/lxc/additional
			lxc-attach -n cont2 -- mount /dev/lxc/additional /var/www/html
			
			# reload apache
			lxc-attach -n cont2 -- systemctl restart apache2
			
			cont2_IP=$(lxc-info -n cont2 -iH)
			echo $cont2_IP

			sleep 5 
			# iptables
			iptables -t nat -D PREROUTING 1			
			iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $cont2_IP:80
			
			echo "DONE"
	fi
done	

		
# we'll suppose cont2 is only up and running if cont2 is down
while [[ $check_mem_2 == "OK" ]];
do
	cont2_mem=$(lxc-info -n cont2 -S | grep Memory | tr -s " " | cut -d " " -f 3 | cut -d "." -f 1)
	

	# if used memory is greater  than 1000, add memory limits
	if 	[[ $cont2_mem -ge '1000' ]];
	then
		check_mem_2='NOT OK'
			
		# add memory limits
		lxc-cgroup -n cont2 memory.limit_in_bytes 2048M
#lxc-attach -n cont1 -- stress -m 1 --vm-bytes 512M --vm-keep -t 70s
	fi
done	
