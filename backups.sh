#!/bin/bash
#variables
backup_user='maria.romero'

#cadenas de conexion
connMysql='mariadb -u root'
connPsql='psql -h 172.22.200.110 -U maria.romero -d db_backup'

for (( i = 0; i < 4; i++ )); do
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
	echo $datos
	#level = F / I
	#jobStatus = T / f
	#RealEndTime =  2018-01-05 23:55:04
	
	backup_label=$( echo $datos | cut -d " " -f 5 )
	
	backup_Level=$( echo $datos | cut -d " " -f 6 ) # F or I
	backup_description= Depende de backupType #full or incremental
	
	backup_JobStatus=$( echo $datos | cut -d " " -f 7 ) # T or f
	backup_status= depende de backup_JobStatus
	backup_mode= depende de status #auto or failed, if failed there should be a manual copy

	backup_date=$( echo $datos | cut -d " " -f 8 )
	

	#connPsql -c 'insert into backups values($backup_user, $backup_host, $backup_label,$backup_description, $backup_status, $backup_date, $backup_mode);'
done 
