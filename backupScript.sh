#!/bin/bash

# Version 0.2
# Backup nextcloud, expected folder structure:
#   ./nextcloud/data
#   ./nextcloud/html
#   ./nextcloud/config
#   ./nextcloud/custom_apps
#   ./nextcloud/theme

# - check folders exists
# - check remote folder exists
# - create backup folder on remote
# - put server in maintenance mode
# - copy & compress folders to remote
# - dump db
# - disable maintenance mode 
# - delete oldest folder


source .env
set -e # to exit on exit 1

user="$(whoami)"
workingDir=$(dirname "$(realpath "$0")")
dateToday="$(date -d "today" +"%Y%m%d")"
cd ${workingDir}

logFileName="backUpLog.log"
logPath="${workingDir}/${logFileName}"

remoteRootBackupDir="${workingDir}/ChangeThis_BackUpFolder/"
remoteBackupDir=""

nextcloudRoot="./nextcloud"
nextcloudDataDir="./nextcloud/data"
nextcloudHtmlDir="./nextcloud/html"
nextcloudConfigDir="./nextcloud/config"
nextcloudCustomAppsDir="./nextcloud/custom_apps"
nextcloudThemeDir="./nextcloud/theme"
nextcloudFolderSize=""

mariaDbUser=$MYSQL_USER
mariaDbPassw=$MYSQL_PASSWORD
mariaDbName=$MYSQL_DATABASE
mariaDbLocalBindMount="./nextcloud/mariadb_dumps"
mariaDbDockerName='nextcloud-mariadb'

function isRoot(){
        if [ "$(id -u)" != "0" ]
        then
                printf "Not root! Exiting... \n"
                exit 1
        fi
}

function removeOldLog(){
        if [ -d "${logPath}" ]
        then
                printf "Found old log, removing ${logPath}\n"
                rm ${logPath}
        else
                printf "No log found at ${logPath}, continue\n"
        fi
}

function checkFolderExist(){
        if [ -d "$1" ]
        then
                printf "\t$1 --> OK\n"
        else
                printf "\t$1 --> does NOT exist! Exiting 1\n"
                exit 1
        fi
}

function checkNextcloudLocalFoldersExist(){
        printf "Checking Nextcloud local folders:\n"
        checkFolderExist ${nextcloudDataDir}
        checkFolderExist ${nextcloudHtmlDir}
        checkFolderExist ${nextcloudConfigDir}
        checkFolderExist ${nextcloudCustomAppsDir}
        checkFolderExist ${nextcloudThemeDir}
        nextcloudFolderSize=$(du -hs ${nextcloudRoot}| cut -f1)
        printf "Nextcloud local folders: OK\n\tSize is ${nextcloudFolderSize}\n"
}

function checkRemoteBackupFolderExist(){
        printf "Checking if remotebackup is reachable:\n\t"
        checkFolderExist ${remoteRootBackupDir}
        printf "Remotebackup is reachable: OK\n"
}

function createBackupFolderWithDate(){
        backupFolderName='nextcloudBackup_'$(date +%Y_%m_%d)
        remoteBackupDir="${remoteRootBackupDir}/${backupFolderName}"
        if [ -d "$remoteBackupDir" ]
        then
                printf "backupfolder already exists, exit\n"
                exit 1
        else
                printf "Creating backupfolder: $backupFolderName\n"
                mkdir ${remoteBackupDir}
        fi
}

function enableNextcloudMaintenanceMode(){
        printf "Enabling Maintenance Mode on Server \n"
        docker exec -u www-data nextcloud php occ maintenance:mode --on
}

function disableMaintenanceMode() {
        printf "Disable Maintenance Mode on Server \n"
        docker exec -u www-data nextcloud php occ maintenance:mode --off
}

function tar_copy() {
        printf "Copying $1 --> $2 with name: $3\n"
        tar cf - $1 -P | pv -s $(du -sb $1 | awk '{print $1}') | gzip > $2/$3.tar.gz
        printf "Done tar\n"
}
function copyNextcloudFolders(){
        tar_copy $nextcloudDataDir $remoteBackupDir "${dateToday}_nextcloudDataDir"
        tar_copy $nextcloudHtmlDir $remoteBackupDir "${dateToday}_nextcloudHtmlDir"
        tar_copy $nextcloudConfigDir $remoteBackupDir "${dateToday}_nextcloudConfigDir"
        tar_copy $nextcloudCustomAppsDir $remoteBackupDir "${dateToday}_nextcloudCustomAppsDir"
        tar_copy $nextcloudThemeDir $remoteBackupDir "${dateToday}_nextcloudThemeDir"
        chmod 777 -R ${remoteBackupDir}
}

function dumpAndCopyDataBase(){
        fileName="${dateToday}_Db_dump"
        printf "Dumping database\n"
        docker exec ${mariaDbDockerName} sh -c "mariadb-dump --single-transaction --default-character-set=utf8mb4 -u ${mariaDbUser} -p"${mariaDbPassw}" "${mariaDbName}" > /mnt/data_dump/${fileName}.sql"
        tar_copy "${mariaDbLocalBindMount}/${fileName}.sql" $remoteBackupDir "${fileName}_mariaDbDump"
}

function removeOldest(){
        minNrFolder=2
        nrOfFolders=$(find ${remoteRootBackupDir} -maxdepth 1 -type d|wc -l)
        printf "Found $nrOfFolders folders in ${remoteRootBackupDir}\n"
        if [[ $nrOfFolders-1 -gt $minNrFolder ]];
        then
                echo "Number of folders greater then $minNrFolder \n"
                dir=${remoteRootBackupDir}
                IFS= read -r -d $'\0' line < <(find "$dir" -maxdepth 1 -printf '%T@ %p\0' 2>/dev/null | sort -z -n)
                file="${line#* }"
                printf "Oldest folder is ${file}\n"
                rm -r "$file"
        else
                echo "Nr of folders < min nr of folders, do not delete oldest\n"
        fi
}

## Main logic here ! 
isRoot
removeOldLog
printf "############## Starting backup ${datetoday}_$(date +"%H:%M:%S") ##############\n" 
checkNextcloudLocalFoldersExist
printf "\n"
checkRemoteBackupFolderExist
printf "\n"
createBackupFolderWithDate
printf "\n"
enableNextcloudMaintenanceMode
printf "\n"
copyNextcloudFolders
printf "\n"
dumpAndCopyDataBase
printf "\n"
disableMaintenanceMode
printf "\n"
removeOldest
printf "\n" 
printf "############## Backup finished ${datetoday}_$(date +"%H:%M:%S") ##############\n"
