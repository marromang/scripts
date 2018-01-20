#!/bin/bash
#vars
check_mem_1='OK'
check_mem_2='OK'

# cont status
cont1_status=$(lxc-info -n cont1 -sH)

# if not running, start and add aditional disk
if [[ $cont_status != "RUNNING" ]];
then
	 # start cont1
	lxc-start -n cont1

	# check cont1 status
	cont1_status=$(lxc-info -n cont1 -sH)

	until  [[ $cont1_status == "RUNNING" ]]
		do
			echo "Initializing cont1"
		done

	#attach the additional disk
	echo "Adding volume to cont1"
	lxc-device -n cont1 add /dev/lxc/additional

	echo "Mounting"
	lxc-attach -n cont1 -- mount /dev/lxc/additional /var/www/html
	echo "Mounted"
fi

# once the container is running, we add iptables rules so the web server can be seen from another host
# limit ram
echo "Limiting ram"
lxc-cgroup -n cont1 memory.limit_in_bytes 512M

# get ip
until [[ -n "${cont1_IP}" ]] 
		do
			echo "Getting cont1 IP"
			sleep 1
			cont1_IP=$(lxc-info -n cont1 -iH)
		done

echo "iptables cont2"
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $cont1_IP:80

echo "Restarting apache"
lxc-attach -n cont1 -- systemctl restart apache2

echo "You can now check the website"

# once is up and running, check memory
while [[ $check_mem_1 == "OK" ]];
do
	cont1_mem=$(lxc-info -n cont1 -S | grep Memory | tr -s " " | cut -d " " -f 3 | cut -d "." -f 1)
	
	# if free memory is greater than 500, start migration
	if 	[[ $cont1_mem -ge '500' ]];
	then
		check_mem_1='NOT OK'
		
		# cont1 down
		echo "Stopping cont1"
		lxc-stop -n cont1
		
		# umount disk
		# lxc-attach -n cont1 -- umount /dev/lxc/additional /var/www/html
		
		# cont2 up
		echo "Starting cont2"
		lxc-start -n cont2
		
		cont2_status=$(lxc-info -n cont2 -sH)

		# check cont2 status
		until  [[ $cont2_status == "RUNNING" ]]
		do
			echo "Initializing cont2"
		done

		# whene there's connection, proceed
			# add disk
		lxc-cgroup -n cont2 memory.limit_in_bytes 1024M
		lxc-device -n cont2 add /dev/lxc/additional
		lxc-attach -n cont2 -- mount /dev/lxc/additional /var/www/html
		
		#get ip

		until [[ -n "${cont2_IP}" ]] 
		do
			echo "Getting cont2 IP"
			sleep 1
			cont2_IP=$(lxc-info -n cont2 -iH)
		done
			
		# iptables
		# get line number of rule to delete
		echo "iptables cont2"
		rule_no=$(iptables -t nat -L --line-number | grep $cont1_IP | cut -d " " -f 1)
		iptables -t nat -D PREROUTING $rule_no
		iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $cont2_IP:80

		# reload apache
		echo "Restarting apache"
		lxc-attach -n cont2 -- systemctl restart apache2
		
		echo "You can now check the website"
			
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
		echo "Resizing cont2"			
		# add memory limits
		lxc-cgroup -n cont2 memory.limit_in_bytes 2048M
		echo "Cont2 resized"

	fi
done	

echo "Cleaning iptables"
rule_no=$(iptables -t nat -L --line-number | grep $cont2_IP | cut -d " " -f 1)
iptables -t nat -D PREROUTING $rule_no

echo "Stoppping containers"
# lxc-stop -n cont1
lxc-stop -n cont2


# How to stress cont1
# lxc-attach -n cont1 -- stress -m 1 --vm-bytes 512M --vm-keep -t 3s

# How to stress cont2
# lxc-attach -n cont2 -- stress -m 1 --vm-bytes 1024M --vm-keep -t 3s
