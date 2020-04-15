# docker-ntp installation

A docker container with ntp installed. 
Features:
* basic configuration vie environment variables 
* additional customization possible via a custom configuration file
  
## Configuration
 
### Configuration files, log files, business data
The following directories can be loaded from the host to keep the data and configuration files out of the container:

 | PATH in container | Description |
 | ---------------------- | ----------- |
 | /var/log | Default Logging Directory of the container. Logging information can be found in the syslog file.|
 | /var/log/ntpstats | Storage folder for ntp statistics files if enabled |
 | /var/lib/ntp | Storage folder of the ntp drift file |
 
### Environment variables
The following environment variables are available to configure the container on startup.

 | Environment Variable | Description |
 | ---------------------- | ----------- |
 | DOCKERNTP_NTPSERVERS | Comma separated list of ntp servers to be used at upstream ntp servers. |
 | DOCKERNTP_NTPPOOLSERVERS | Comma separated list of ntp server pool addresses to be used. |
 | DOCKERNTP_ENABLE_STATS | Set to "true" to enable storage of ntpstats |
 | DOCKERNTP_CUSTOMFILE | Path to custom configuration file which is _append_ to the auto generated configuration. Take care to bind/import this file via the volume commands, and provide the _internal_ path in the docker container. |
 | DOCKERNTP_BROADCASTADDRESS | Broadcastaddress to advertise the time. Should only be used if the docker container is running in network_mode host. |
 
### Custom configuration file

The custom configuration file includes the normal entries of the ntp.conf file.

## Container Tags

 | Tag name | Description |
 | ---------------------- | ----------- |
 | latest | Latest stable version of the container |
 | stable | Latest stable version of the container |
 | dev | latest development version of the container. Do not use in production environments! |

## Usage

### docker-compose

```
version: "3"
services:
  ntp:
    image: foxcris/docker-ntp:stable
    environment:
      - DOCKERNTP_NTPSERVERS=10.10.10.1,10.10.10.2
      - DOCKERNTP_NTPPOOLSERVERS=0.debian.pool.ntp.org,1.debian.pool.ntp.org,2.debian.pool.ntp.org,3.debian.pool.ntp.org
      - DOCKERNTP_ENABLE_STATS=true
      - DOCKERNTP_CUSTOMFILE=/etc/customntpfile.conf
      - DOCKERNTP_BROADCASTADDRESS=192.168.178.255
    volumes:
      - ./customntpfile.conf:/etc/customntpfile.conf:ro
      - ./data/var/log/ntpstats:/var/log/ntpstats
    ports:
      - 123:123/udp
    restart: always
    networks:
      - backend
    cap_add:
      - SYS_TIME

networks:
  backend:
    driver: bridge
```

### docker command line

To run the container and store the data and configuration on the local host run the following commands:
1. Create storage directroy for the configuration files, log files and data. Also create a directory to store the necessary script to create the docker container and replace it (if not using eg. watchtower)
```
mkdir /srv/docker/ntp
mkdir /srv/docker-config/ntp
```

2. Create an file to store the configuration of the environment variables
```
touch /srv/docker-config/ntp/env_file
``` 
```
DOCKERNTP_NTPSERVERS=10.10.10.1,10.10.10.2
DOCKERNTP_NTPPOOLSERVERS=0.debian.pool.ntp.org,1.debian.pool.ntp.org,2.debian.pool.ntp.org,3.debian.pool.ntp.org
DOCKERNTP_ENABLE_STATS=true
DOCKERNTP_CUSTOMFILE=/etc/customntpfile.conf
DOCKERNTP_BROADCASTADDRESS=192.168.178.255
```

3. Create the docker container and configure the docker networks for the container. I always create a script for that and store it under
```
touch /srv/docker-config/ntp/create.sh
```
Content of create.sh:
```
#!/bin/bash

version=stable

docker pull foxcris/docker-ntp
docker create\
 --restart always\
 --name ntp\
 --volume "./customntpfile.conf:/etc/customntpfile.conf:ro"
 --volume "./data/var/log/ntpstats:/var/log/ntpstats"
 --env-file=/srv/docker-config/ntp/env_file\
 foxcris/docker-ntp:${version}
```

4. Create replace.sh to install/update the container. Store it in
```
touch /srv/docker-config/ntp/replace.sh
```
```
#/bin/bash
docker stop ntp
docker rm ntp
./create.sh
docker start ntp
```
