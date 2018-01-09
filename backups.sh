#!/bin/bash
#variables
backup_user='maria.romero'
backup_description='Incremental'

for (( i = 1; i < 4; i++ )); do
	case $i in
		1)
			host='mickey'
			backup_host='172.22.200.40'
			;;
		2)
			host='minnie'
			backup_host='172.22.200.36'
			;;
		3)
			host='donald'
			backup_host='172.22.200.56'
			;;
	esac
	#datos de la copia
	datos=$( mariadb -u root -e "select Job, Level, JobStatus, RealEndTime from bacula.Job where RealEndTime in (select max(RealEndTime) from bacula.Job group by Name) and Name='$host' group by Name;" )
	
	backup_label=$( echo $datos | cut -d " " -f 5 )
	
	backup_Level=$( echo $datos | cut -d " " -f 6 ) # F or I
	if [[ $backup_level == 'F' ]]; then
		backup_description='Full'
	fi
	
	backup_JobStatus=$( echo $datos | cut -d " " -f 7 ) # T or f
	if [[ $backup_JobStatus == 'T' ]]; then
		backup_status='200'
		backup_mode='Automatic'
	else
		backup_status='400'
		backup_mode='Failed'
		echo "Fallo en la copia del host '$host' con fecha '$backup_date"  | mail -s "Error en Bacula" m.romeroangulo@gmail.com
	fi

	backup_date=$( echo $datos | cut -d " " -f 8 )
	
	psql -h 172.22.200.110 -U maria.romero -d db_backup -c "insert into backups values('$backup_user', '$backup_host', '$backup_label', '$backup_description', '$backup_status', '$backup_date', '$backup_mode' );"
done 
