#!/bin/bash
# backup.sh

# get config values
. /home/theotruvelott/backup.config
NOW=`date '+%F'`

mkdir "${backupfile}_${NOW}"
mkdir "${backupfile}_${NOW}/sql"
mkdir "${backupfile}_${NOW}/logs"
mkdir "${backupfile}_${NOW}/vh"

# func for logs
logs() {

    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "${outputlogs}/logs_$NOW.log"
}
#  launching backup

backup() {
    logs "------------------------------------------"
    logs "-- logs du $(date '+%Y-%m-%d %H:%M:%S') --"
    logs "------------------------------------------"
    logs ""
    # Backup of the www files
    logs "DÉBUT DE LA COPIE DES FICHIER WWW"
   
     case $arewww in
        Y) 
            logs "DÉBUT DE LA COPIE DES FICHIER www"
            case $? in
                0) cp -R "${wwwfile}" -t "${backupfile}_${NOW}"
                    case $? in
                        0) 
                            logs "COPIE DU DOSSIER WWW EFFECTUÉ"
                        ;;
                        1)
                            logs "ERREUR DANS LA COPIE DU DOSSIER WWW"
                            exit
                        ;;
                        *) 
                            logs "ERREUR SYSTEME (cp) ! code d'erreur : $?"
                            exit
                        ;;
                esac ;;
                N)
                ;;
                *) echo "ERREUR CONFIG FILE"
                exit;;
            esac
    esac

    # backup of virtualhost
    case $arevh in
        Y) 
            logs "DÉBUT DE LA COPIE DES FICHIER VH"
            case $? in
                0) cp -R "${vhfile}" -t "${backupfile}_${NOW}/vh"
                    case $? in
                        0) 
                            logs "COPIE DU DOSSIER VIRTUALS HOSTS EFFECTUÉ"
                        ;;
                        1)
                            logs "ERREUR DANS LA COPIE DES VIRTUALS HOSTS"
                            exit
                        ;;
                        *) 
                            logs "ERREUR SYSTEME (cp) ! code d'erreur : $?"
                            exit
                        ;;
                esac ;;
                N)
                ;;
                *) echo "ERREUR CONFIG FILE"
                exit;;
            esac
    esac

    # backup of database
    case $aredb in
        Y) case $SGBD in
                MYSQL)
                   
                    logs "DEBUT DE LA COPIE DE LA DB MYSQL"
                    mysqldump -h $dbhost --user="$dbuser" --password="$dbpsswd" $dbname > ${backupfile}_${NOW}/sql/dump_bdd_mysql.sql
                    if [ $? -eq 0 ]
                    then
                      
                        logs "COPIE DE LA DB EFFECTUÉ"
                    else
                       
                        logs "ERREUR DE LA COPIE DE LA DB ! code d'erreur : $?"
                    fi
                ;;
                POSTGRESQL)
                    
                    logs "DEBUT DE LA COPIE DE LA DB POSTGRESQL"
                    pg_dump -h $dbhost -u $dbuser -w $dbpsswd -d $dbname > ${backupfile}_${NOW}/sql/dump_bdd_Postgre.sql
                    if [ $? -eq 0 ]
                    then
                        logs "COPIE DE LA DB EFFECTUÉ"
                    else
                        logs "ERREUR DE LA COPIE DE LA DB ! code d'erreur : $?"
                    fi
                ;;
                SQLSERVER)
                    logs "DEBUT DE LA COPIE DE LA DB SQL SERVER"
                    sqlcmd -S $dbhost -U $dbuser -P $dbpsswd -Q "BACKUP DATABASE [$dbname] TO DISK = N'${backupfile}_${NOW}/sql/dump_bdd_SQLserv.sql"
                    if [ $? -eq 0 ]
                    then
                        logs "COPIE DE LA DB EFFECTUÉ"
                    else
                        logs "ERREUR DE LA COPIE DE LA DB ! code d'erreur : $?"
                    fi
                ;;
                N)
                ;;
                *) 
                    logs "SGBD NON SUPPORTÉ"
                    logs "ERREUR DANS LE CONFIG FILE"
                ;;
            esac
    esac

    # backup of logs
    case $arelogs in
        Y) 
            logs "DÉBUT DE LA COPIE DES LOGS"
            case $? in
                0) cp -R "${logfile}" -t "${backupfile}_${NOW}/logs"
                    case $? in
                        0) 
                            logs "COPIE DES LOGS EFFECTUÉ"
                        ;;
                        1) 
                            logs "ERREUR DANS LA COPIE DES LOGS"
                            exit
                        ;;
                        *) 
                            logs "ERREUR SYSTEM (cp) ! code d'erreur : $?"
                            exit
                        ;;
                esac ;;
                N)
                ;;
                *) echo "ERREUR CONFIG FILE"
                exit;;
            esac
    esac

    # zip files
    echo ${backupfile}_${NOW}
    cd ${backupfile}_${NOW}
    zip -q -r ${backupfile}_${NOW}.zip ./*
    case $? in
        0) logs "ZIP EFFECTUÉ"
        ;;
        1) logs "ERREUR DANS LE ZIP"
        ;;
        *) logs "ERREUR SYSTEME (zip) ! code d'erreur : $?"
        ;;
    esac
    # remove not needed files
	rm -R ${backupfile}_${NOW}
    case $? in
        0) logs "SUPPRESSION DU DOSSIER ${backupfile}_${NOW} EFFECTUÉ"
        ;;
        1) logs "ERREUR DANS LA SUPPRESSION DU DOSSIER ${backupfile}_${NOW}"
        ;;
        *) logs "ERREUR SYSTEME (rm) ! code d'erreur : $?"
        
    esac
    # send files to sftp server 
	sftp pi@77.200.162.217 <<< $"put ${backupfile}_${NOW}.zip"
    case $? in
        0) logs "ENVOI DU FICHIER ZIP EFFECTUÉ"
        ;;
        1) logs "ERREUR DANS L\'ENVOI DU FICHIER ZIP"
        ;;
        *) logs "ERREUR SYSTEME (sftp) ! code d'erreur : $?"
        ;;
    esac



    logs "FIN DU SCRIPT"


	exit	
}
backup

