# Seafile in Docker with Memcached
This is a docker image made for running seafile in a container using sqlite with a built-in memcached server. Supervisord is used in order to start memcached, seafile and seahub automatically.

As seafile is automatically configured using docker build arguments, this should be either built locally, or reconfigured using a volume, as described below.

A python script is used to download the latest version of seafile, so unless they make breaking changes to the seafile configuration or the download page, this should always work fine. I will try to keep this updated, but pull requests are always welcome.

**Pull:**
```bash
docker pull redprog/seafile
```

## Prerequisites
For the following to work, you need to spin up a temporary seafile instance. It's not necessary to configure volumes for this.

Pull requests are more than welcome if you find a better way of solving this issue, as it does not seem very "docker-like" to me.

### Copy `seahub.db` **[Important]**
For this step it's important, that `/opt/seafile/seahub.db` is **not** mounted on the host. If this step is skipped, seahub will create a new default library each time the container is restarted, as well as show the welcome message once you log in.

Run the following command replacing the dummy ID with the temporary setup container ID, and the path to point to the place where you want to store the database on your host:

```bash
sudo docker cp 123456789abc:/opt/seafile/seahub.db ./seafile
```

### Copy config files to host and add a volume **[Optional]**
If you want to add custom configurations to seafile, you need to copy the existing seafile configuration from the temporary container to your host and add a volume to your docker configuration.

Just run the following script replacing the dummy ID with the temporary setup container ID, and the path to point to the place where you want to store the configuration files on your host:

```bash
ID=123456789abc
PATH=./seafile/conf

/usr/bin/docker cp $ID:/opt/seafile/conf/ccnet.conf $PATH
/usr/bin/docker cp $ID:/opt/seafile/conf/gunicorn.conf $PATH
/usr/bin/docker cp $ID:/opt/seafile/conf/seafdav.conf $PATH
/usr/bin/docker cp $ID:/opt/seafile/conf/seafile.conf $PATH
/usr/bin/docker cp $ID:/opt/seafile/conf/seahub_settings.py $PATH
/usr/bin/docker cp $ID:/opt/seafile/conf/seahub_settings.pyc $PATH
```

Afterwards, add a volume to your docker configuration to mount the config path on your host to `/opt/seafile/conf` in the container. **Example:**

```yaml
...
services:
  seafile:
    ...
    volumes:
      ...
      - ./seafile/conf:/opt/seafile/conf
    ...
```

## Volumes
| Container path              | Description                                                                                                           |
|-----------------------------|-----------------------------------------------------------------------------------------------------------------------|
| `/opt/seafile/seafile-data` | Data stored by the seafile server (e.g. libraries, uploaded files).                                                   |
| `/opt/seafile/seahub-data`  | Data stored by the seahub server (e.g. thumbnails, avatars).                                                          |
| `/opt/seafile/seahub.db`    | SQLite database of the seahub server. Contains library metadata, etc.                                                 |
| `/var/log`                  | Log files of memcached, seafile and seahub are stored here.                                                           |
| `/opt/seafile/conf`         | Configuration files are here. Read [this section](#copy-config-files-to-host-and-add-a-volume-optional)  *(Optional)* |

## Logs
Three log files are created in `/var/logs` in the container, `memcached.log`, `seafile.log` and `seahub.log`. Refer to those files in case you experience trouble to investigate the issue.

## `docker-compose.yml`
A seafile container can be run easily using `docker-compose`. Refer to the example config below:

```yaml
version: "3"

services:
  seafile:
    image: redprog/seafile
    volumes:
      - ./seafile/seafile-data:/opt/seafile/seafile-data
      - ./seafile/seahub-data:/opt/seafile/seahub-data
      - ./seafile/seahub.db:/opt/seafile/seahub.db
      - ./seafile/logs:/var/log
    restart: always
    networks:
      - web
```

## Supervisor
All processes are managed using [Supervisor](http://supervisord.org/). To manage them, you can execute a new bash session in the container and run `supervisorctl [stop|start|restart] [memcached|seafile|seahub]`.

This however should in theory not be necessary under normal circumstances and only described here for the sake of completeness.
