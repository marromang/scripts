#!/bin/bash
#variables
coconutUser='maria.romero'

#cadenas de conexion
connMysql='mariadb -u root'
connPsql='psql -h 172.22.200.110 -U maria.romero -d db_backup'

for (( i = 0; i < 4; i++ )); do
	case $i in
		1)
			host='mickey'
			direccion='172.22.200.40'
			;;
		2)
			host='minnie'
			direccion='172.22.200.36'
			;;
		3)
			host='donald'
			direccion='172.22.200.56'
			;;
	esac
	#datos de la copia
	datos=connMysql -e 'select Level, JobStatus, RealEndTime, from bacula.Job where RealEndTime in (select max(RealEndTime) from bacula.Job group by Name) and Name=$host group by Name;'
	label= 
	description=
	status= JobStatus
	fecha= RealEndTime
	modo= 

	connPsql -c 'insert into backups values($coconuUser, $direccion, $label, $description, $codigo, $fecha, $modo);'
done

echo "adgfsdgdfgd" | mail -s "Test Postfix" m.romeroangulo@gmail.com
