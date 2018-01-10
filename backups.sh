#!/bin/bash

#constant values
backup_user='maria.romero'
backup_description='Incremental'
backup_mode='Automatica'
backup_node_dir="172.22.200.110"

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
        
        #check connection to host
        if [[ "fping $backup_host" ]]; then
                datos=$( mariadb -u root -e "select Job, Level, JobStatus, RealEndTime from bacula.Job where RealEndTime in (select max(RealEndTime) from bacula.Job group by Name) and Name='$host' group by Name;" )

                backup_label=$( echo $datos | cut -d " " -f 5 )

                backup_Level=$( echo $datos | cut -d " " -f 6 ) # F or I
                if [[ $backup_level == 'F' ]]; then
                        backup_description='Full'
                fi

                backup_JobStatus=$( echo $datos | cut -d " " -f 7 ) # T or f
                if [[ $backup_JobStatus == 'T' ]]; then
                        backup_status='200'
                else
                        backup_status='400'
                        echo "$host backup on $backup_date failed."  | mail -s "Bacula backup error" m.romeroangulo@gmail.com
                fi

                backup_date=$( echo $datos | cut -d " " -f 8 )

        else
                backup_status='100'
                echo "$host backup on $backup_date failed. No connection to host."  | mail -s "Bacula host error" m.romeroangulo@gmail.com

        fi

        #check connection to db
        if [[ !("fping $backup_node_dir") ]]; then
                backup_status='500'
                echo "$host backup on $backup_date failed. No connection to db."  | mail -s "Bacula db error" m.romeroangulo@gmail.com
        else    
                psql -h $backup_node_dir -U maria.romero -d db_backup -c "insert into backups values('$backup_user', '$backup_host','$backup_label','$backup_description', '$backup_status', '$backup_date', '$backup_mode' );"
        fi
       
done 
