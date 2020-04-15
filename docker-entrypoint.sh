#!/bin/bash

info() { logger "DOCKER_NTP: $*"; }

/etc/init.d/rsyslog start
/etc/init.d/cron start

ntp_configfile="/etc/ntp.conf"

cp -a /etc/ntp.conf_default ${ntp_configfile}

#disable/remove all default ntpservers
sed -i "s/server.*//" ${ntp_configfile}
sed -i "s/pool.*//" ${ntp_configfile}

if [ $(echo ${#DOCKERNTP_NTPSERVERS}) > 0 ]
then
  IFS=","
  for server in $DOCKERNTP_NTPSERVERS; do
    # strip any quotes found before or after ntp server
    info "server ${server//\"} iburst"
    echo "server ${server//\"} iburst" >> ${ntp_configfile}
  done
fi

if [ $(echo ${#DOCKERNTP_NTPPOOLSERVERS}) > 0 ]
then
  IFS=","
  for poolserver in $DOCKERNTP_NTPPOOLSERVERS; do
    # strip any quotes found before or after ntp server
    info "pool ${poolserver//\"} iburst"
    echo "pool ${poolserver//\"} iburst" >> ${ntp_configfile}
  done
fi

if [ "${DOCKERNTP_ENABLE_STATS}" = "true" ]
then
  info "statsdir=/var/log/ntpstats/"
  sed -i "s!#statsdir.*!statsdir=/var/log/ntpstats/!" ${ntp_configfile}
fi

if [ "${DOCKERNTP_CUSTOMFILE}" != "" ] && [ -f ${DOCKERNTP_CUSTOMFILE} ]
then
  info "append custom configuration file ${DOCKERNTP_CUSTOMFILE}"
  cat ${DOCKERNTP_CUSTOMFILE} >> ${ntp_configfile}
fi

if [ "${DOCKERNTP_BROADCASTADDRESS}" != "" ]
then
  info "broadcast=${DOCKERNTP_BROADCASTADDRESS}"
  sed -i "s/#broadcast.*/broadcast=${DOCKERNTP_BROADCASTADDRESS}/" ${ntp_configfile}
fi

/etc/init.d/ntp start

while [ ! -f /var/log/syslog ]
do
  sleep 1s
done

tail -f /var/log/syslog
