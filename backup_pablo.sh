#!/bin/bash

LOGFILE="/home/cellosofia/logsbackup/backup_pablo_$(date +%Y%m%d%H%M%S).log";
ERRORFILE="/home/cellosofia/logsbackup/backup_pablo_$(date +%Y%m%d%H%M%S).err";
vmup=0

logerror() {
  mensaje=$1
  echo $mensaje >> $ERRORFILE
  notify-send -i error -u critical -a backup_pablo.sh -t 10000 "Backup Pablo. ERROR" "$mensaje"
  exit 1
}

loginfo() {
  mensaje=$1
  echo $mensaje >> $LOGFILE
  notify-send -i error -u normal -a backup_pablo.sh -t 10000 "Backup Pablo. INFO" "$mensaje"
}

if [ ! $EUID == 0 ]; then
  logerror "Se debe ejecutar este comando como root"
fi

if [ ! -d /run/media/cellosofia/Backup/backupHP4540s ]; then
  logerror "No esta montada la unidad de backup"
fi

if [ "$(vmrun list | tail -n+2 | grep 'Windows 7.vmx')x" != "x" ]; then
  vmup=1
  $hour=$(date +%H)
  if [ $hour -ge 8 -a $hour -le 20 ]; then
    loginfo "Hola, estoy haciendo el backup que me ha solicitado Sr. Pablo. Puedo suspender un rato su maquina?"
    zenity --question --text="Puedo suspender un rato su maquina virtual Sr. Pablo?" --ok-label="OK, metele nomas" --cancel-label="Emm... Mejor no por ahora"
    if [ $? == 0 ]; then
      loginfo "Suspendiendo maquina virtual"
      vmrun suspend "/home/cellosofia/vmware/Windows 7/Windows 7.vmx"
    else
      logerror "Se me ha instruido abortar la operacion. Que tenga un buen resto de jornada =)"
      exit 1
    fi
  else
     loginfo "Suspendiendo maquina virtual"
     vmrun suspend "/home/cellosofia/vmware/Windows 7/Windows 7.vmx"
  fi
fi

echo "#######################" >> $LOGFILE
echo "# INICIANDO BACKUP    #" >> $LOGFILE
echo "#######################" >> $LOGFILE

loginfo "INICIANDO BACKUP"

ionice -c 3 rsync -Pav /home/cellosofia/ /etc /run/media/cellosofia/Backup/backupHP4540s/ >> $LOGFILE 2>> $ERRORFILE
#ionice -c 3 rsync -Pav --exclude='*.vmdk' /home/cellosofia/ /etc /run/media/cellosofia/Backup/backupHP4540s/ >> $LOGFILE 2>> $ERRORFILE

if [ $? != 0 ]; then
  logerror "Hubo un error al realizar el backup. Por favor verifique los logs. :("
fi

 
echo "#######################" >> $LOGFILE
echo "# BACKUP FINALIZADO   #" >> $LOGFILE
echo "#######################" >> $LOGFILE

loginfo "BACKUP FINALIZADO"

if [ $vmup == 1 ]; then
  loginfo "Ahora voy a iniciar otra vez la maquina virtual"
  vmrun start "/home/cellosofia/vmware/Windows 7/Windows 7.vmx"
fi
