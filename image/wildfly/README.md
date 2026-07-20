## General
The WildFly image has the most use cases for us.
It can be used directly with Docker Compose, or serves as the basis for other images itself.
This image can be started directly without building your own image first.
Of course, you can still build your own image.

## About Health-Check-Strategies
There are 3 strategies built into this docker image.

* Microprofile-Health<br>
  This is the default strategy and only works if the `WF_ADMIN_PASS` variable is set. Then the WildFly management automatically
  checks all deployments that have the microprofile installed (see https://microprofile.io/specifications/microprofile-health/).
* URL-check<br>
  For this strategy at least one accessible URL must be specified as ENV-variable `WF_HEALTHCHECK_URLS`.
  If a URL is not reachable or does not return the HTTP status code 200, the health status is set to "unhealthy".
  This strategy can be combined with Microprofile-Health.
* Running-Deployments<br>
  This solution only works if neither of the other two strategies is used.
  It only checks that none of the deployments has booted incorrectly.


## Relevant ENV Variables
| Category   | Variable                                   | Available values or scheme                           | Default           | Purpose                                                                                                                |
|------------|--------------------------------------------|------------------------------------------------------|-------------------|------------------------------------------------------------------------------------------------------------------------|
| WF-Admin   | WF_NO_ADMIN                                | true \| false                                        | false             | set `true` if you don't need wildfly-admin                                                                             |
| WF-Admin   | WF_ADMIN_USER                              | \<STRING\>                                           | admin             | define username for wildfly-admin                                                                                      |
| WF-Admin   | WF_ADMIN_PASS                              | \<STRING\>                                           | -random-          | to set password for wildfly-admin                                                                                      |
| Quality    | WF_HEALTHCHECK_URLS                        | \<NEWLINE-SEPARATED-URLs\>                           | -                 | contain a list of urls to check the health of this container                                                           |
| Optimizing | TZ                                         | \<STRING\>                                           | Europe/Berlin     | timezone                                                                                                               |
| Optimizing | WF_ADD_CLI_FILTER                          | \<PIPE-SEPARATED-STRING\>                            | -                 | define additional pipe-separated file-extensions that jboss-cli should process                                         |
| Optimizing | WF_MARKERFILES                             | true \| false \| auto                                | auto              | these affect the creation of marker-files (.isdeploying or .deployed) in the deployment-directory                      |
| Optimizing | WF_MAX_POST_SIZE                           | \<BYTES\>                                            | 10485760          | the maximum size of a post that will be accepted, in bytes                                                             |
| Optimizing | WF_MAX_PARAMETERS                          | \<NUMBER\>                                           | 100000            | the maximum number of parameters that will be parsed                                                                   |
| Optimizing | WF_MAX_CHILD_ELEMENTS                      | \<NUMBER\>                                           | 50000             | the maximum number of children that will be allow in xml-post                                                          |
| Optimizing | WF_BLOCKING_TIMEOUT                        | \<SECONDS\>                                          | 300               | this can be used to change the time until processes are cancelled                                                      |
| Optimizing | WF_TRANSACTION_TIMEOUT                     | \<SECONDS\>                                          | 300               | this can be used to change the time after which a transaction is automatically terminated                              |
| Optimizing | WF_DATASOURCES_QUERY_TIMEOUT **new**       | \<SECONDS\>                                          | 30                | timeout for datasource queries                                                                                         |
| Optimizing | WF_DEPLOYMENT_TIMEOUT **new**              | \<SECONDS\>                                          | 600               | timeout for the deployment scanner to allow a deployment attempt before being canceled                                 |
| Optimizing | WF_ENABLE_HTTP2                            | true \| false                                        | false             | HTTP2 support                                                                                                          |
| Optimizing | WF_ENABLE_PROXY_ADDRESS_FORWARDING **new** | true \| false                                        | false             | use this option when the wildfly is running behind a reverse proxy or load balancer (e.g., NGINX, Apache, etc.).       |
| Optimizing | JAVA_OPTS                                  | \<STRING\>                                           | -Xms1G -Xmx6G ... | you need more memory? then give yourself more memory or define any system-variables                                    |
| Processing | MOS_WAIT_FOR_PORTS                         | \<HOST\>:\<PORT\>\[:\<TIMEOUT\>\[:\<SLEEP\>]],...    | -                 | comma- or semicolon-separated list of endpoints that should wait before starting wildfly. defaults timeout=300,sleep=0 |
| Processing | WF_WAIT_FOR_PORTS                          | \<HOST\>:\<PORT\>\[:\<TIMEOUT\>\[:\<SLEEP\>]],...    | -                 | just like MOS_WAIT_FOR_PORTS, but waits after JBoss-CLI                                                                |
| Security   | WF_SERVER_KEYSTORE_PASSWORD                | \<STRING\>                                           | -                 | this password is only used in combination with /entrypoint-wildfly-server-keystore to access the keystore              |
| Security   | WF_SERVER_KEYSTORE_ALIAS                   | \<STRING\>                                           | -                 | if there is more than one certificate in the keystore, this alias must be specified                                    |
| Logging    | WF_SYSTEM_LOG_LEVEL **improved**           | SEVERE\|FATAL\|ERROR\|WARN\|INFO\|DEBUG\|TRACE\|FINE | INFO              | this can be used to set the log level of the console                                                                   |
| Logging    | WF_SYSTEM_LOG_COLORS **new**               | \<LEVEL\>:\<COLOR\>\[,\<LEVEL\>:\<COLOR\>\[,...]]    | -                 | this map allows a comma delimited list of colors to be used for different levels with a pattern formatter              |
| Logging    | WF_SYSTEM_LOG_TO **improved**              | CONSOLE;FILE;SYSLOG                                  | CONSOLE           | multiple values semicolon-separated possible                                                                           |
| Logging    | WF_SYSTEM_SYSLOG_HOST **new**              | \<HOST\>                                             | syslog            | value will be taken from WF_SYSLOG_HOST if not set                                                                     |
| Logging    | WF_SYSTEM_SYSLOG_PORT **new**              | \<PORT\>                                             | 514               | value will be taken from WF_SYSLOG_PORT if not set                                                                     |
| Logging    | WF_SYSTEM_SYSLOG_FORMAT **new**            | RFC3164 \| RFC5424                                   | RFC3164           | value will be taken from WF_SYSLOG_FORMAT if not set                                                                   |
| Debugging  | WF_DEBUG                                   | true \| false                                        | false             | set `true` to enable debug-mode in wildfly                                                                             |
| Debugging  | DEBUG_PORT                                 | \<IP\>:\<PORT\>                                      | *:8787            | for debugging you can change the ip:port                                                                               |

```shell
# more with "envs"
> docker run --rm mosaicgreifswald/wildfly envs
```

## Relevant Entrypoints
| Path                                | ref. ENV-Variable             | Type   | Purpose                                                                                                                                  |
|-------------------------------------|-------------------------------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
| /entrypoint-logs                    | ENTRY_LOGS                    | folder | all further layers can store their own log files here in subdirectories.                                                                 |
| /entrypoint-help-and-usage          | ENTRY_USAGE                   | folder | Here you will find README-files for each docker-image-layer, including examples.                                                         |
| /entrypoint-java-cacerts            | ENTRY_JAVA_CACERTS            | file   | the entrypoint can be used to store its own cacerts, e.g. containing public-keys of server certificates for specific web requests or CA. |
| /entrypoint-wildfly-cli             | ENTRY_WILDFLY_CLI             | folder | to execute JBoss-cli-files before start WildFly (read-only access)                                                                       |
| /entrypoint-wildfly-deployments     | ENTRY_WILDFLY_DEPLOYS         | folder | to import your deployments, also ear- and/or war-files (read-only access, optional write access)                                         |
| /entrypoint-wildfly-addins          | ENTRY_WILDFLY_ADDINS          | folder | to import additional files for deployments (read-only access)                                                                            |
| /entrypoint-wildfly-logs            | ENTRY_WILDFLY_LOGS            | folder | to export all available log-files (read/write access)                                                                                    |
| /entrypoint-wildfly-server-keystore | ENTRY_WILDFLY_SERVER_KEYSTORE | file   | to use your own keystore for server certificate (read-only access)                                                                       |

```shell
# similar with "entrypoints"
> docker run --rm mosaicgreifswald/wildfly entrypoints
```

## Usage
```shell
# build wildfly-image (required java-image mosaicgreifswald/zulujre:25)
> git clone https://github.com/mosaic-hgw/Docker.git
> cd mosaic-hgw/Docker/image/wildfly
> docker build --tag="mosaicgreifswald/wildfly" --file="Dockerfile.wildfly.40" .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/wildfly versions
  last updated               : 2026-06-23 14:29:25
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 13.5 (trixie)
  zulu-jre                   : 25.0.3 
  WildFly                    : 40.0.1.Final
  MySQL-Connector            : 9.7.0
  MariaDB-Connector          : 3.5.9
  PostgreSQL-Connector       : 42.7.11
  EclipseLink                : 4.0.9

# simple start with your deployments and without wildfly-admin-user
> docker run --rm \
    -e WF_NO_ADMIN=true \
    -p 8080:8080 \
    -v /path/to/your/deployments:/entrypoint-wildfly-deployments \
    mosaicgreifswald/wildfly

# if your deployment folder is write-protected, you can explicitly switch off the markerfiles
> docker run --rm \
    -e WF_ADMIN_PASS=top-secret \
    -e WF_MARKERFILES=false \
    -e WF_HEALTHCHECK_URLS=http://localhost:8080\nhttp://localhost:8080/your-app.html \
    -p 8080:8080 \
    -p 9990:9990 \
    -v /path/to/your/cli-files:/entrypoint-wildfly-cli \
    -v /path/to/readonly/deployments:/entrypoint-wildfly-deployments \
    mosaicgreifswald/wildfly
```

## Change write permissions
If data is stored on the host-system (via volume), it is created by default with the internal mosaic-user (UID:GID = 1111:1111).
Accordingly, the writable directories on the host-system must be unlocked for the mosaic-user.

```sh
# at host-system
chown -R 1111:1111 deployments logs
```
**Note:** The deployment directory does not necessarily have to have write permissions.
If these are omitted here, no WildFly marker-files are set.

### The alternative, change write-user
You can change the write-user by using the Docker parameter --user/-u.

```sh
# change write-user (UID:GID) for writable volumes like logs/
> docker run --rm -d \
    -u 1006:1001 \
    -e WF_SYSTEM_LOG_TO=FILE \
    -v /path/to/your/logs:/entrypoint-wildfly-logs \
    mosaicgreifswald/wildfly

> ls -la /path/to/your/logs
insgesamt 8
drwxr-xr-x  2 1006 1001 4096 11. Jun 10:25 .
drwxrwxrwt 10 root root 4096 11. Jun 10:26 ..
-rw-r--r--  1 1006 1001    0 11. Jun 10:25 server.log
drwxr-xr-x  2 1006 1001 4096 11. Jun 10:25 system
```

## Usage with docker compose
over docker-compose with dependent on mysql-db (example)
```yml
# docker-compose.yml

services:
  mysql:
    image: mysql
    environment:
      MYSQL_ROOT_PASSWORD: top-secret
    volumes:
      - /path/to/your/init-sql-files:/docker-entrypoint-initdb.d
  wildfly:
    image: mosaicgreifswald/wildfly
    ports:
      - 8080:8080
      - 9990:9990
    depends_on:
      - mysql
    environment:
      WF_ADMIN_PASS: top-secret
      WF_HEALTHCHECK_URLS: |
        http://localhost:8080
        http://localhost:8080/your-app.html
      WF_WAIT_FOR_PORTS: mysql:3306
    volumes:
      - /path/to/your/cli-files:/entrypoint-wildfly-cli
      - /path/to/your/deployments:/entrypoint-wildfly-deployments
```


## What are JBoss-CLI-File?
CLI-files are text files that contain a list of CLI commands to execute on a JBoss-server.
They are useful for scripting and batch processing tasks, such as deploying applications,
configuring system settings, or performing administrative operations.
**In this way it is possible to use our WildFly-image without having to modify it for your own purposes.**
All relevant adjustments can be written into a CLI-file and passed to WildFly.

### Examples for create JBoss-CLI-File
* add mysql-datasource
  ```sh
  # add-mysql-datasource.cli

  data-source add \
    --name=MySQLPool \
    --jndi-name=java:/jboss/MySQLDS \
    --connection-url=jdbc:mysql://mysql:3306/dbName \
    --user-name=mosaic \
    --password=top-secret \
    --driver-name=mysql
  ```

## Additional files
```shell
# explore all additional files
> docker run --rm -it mosaicgreifswald/wildfly examples

# explore and copy interesting files to your local host
> docker run --rm -itv "/your/local/path/:/tmp/" mosaicgreifswald/wildfly examples --target-dir /tmp

# or copy directly all files to your host
> docker run --rm -v "/your/local/path/:/tmp/" mosaicgreifswald/wildfly examples --copy-all --target-dir /tmp"
```
You will receive the following directory-tree and can start playing immediately:
```
├─┬─ layer-readme/
│ ├─── README-debian.md
│ ├─── README-wildfly.md
│ └─── README-zulujre.md
└─┬─ examples/
  ├─┬─ compose-wildfly-empty/
  │ ├─── addins/
  │ ├─── deployments/
  │ ├─┬─ envs/
  │ │ └─── wf_commons.env
  │ ├─── jboss/
  │ ├─── logs/
  │ ├─── sqls/
  │ └─── docker-compose.yml
  └─┬─ pure-envs/
    ├─── debian.env
    ├─── wf_commons.env
    └─── zulujre.env
```


## Current Software-Versions on this Image
| Date                                   | Tags                                                                                                                                                                                                                                                                                                                                                                                          | Changes                                                                                                                                                                                               |
|----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2026-07-20<br><br><br>                 | [40-20260720](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=40-20260720), [40](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=40), [latest](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=latest) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/9208508b4a798785d81358ee45cca00e55dbec89/image/wildfly/Dockerfile.wildfly.40))<br><br><br> | **Debian** 13.6 "trixie"<br>**PostgreSQL-Connector** 42.7.13<br>**fixed** schema definition in ajp listener                                                                                           |
| 2026-06-23<br><br><br>                 | [40-20260623](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=40-20260623) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/92227e5edb6aa67f130126a59ad74f87f303836c/image/wildfly/Dockerfile.wildfly.40))<br><br><br>                                                                                                                                                     | **WildFly** 40.0.1.Final<br>**openJRE** 25.0.3<br>**MariaDB-Connector** 3.5.9                                                                                                                         |
| 2026-05-20<br><br><br><br><br>         | [38-20260520](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=38-20260520), [38](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=38) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/27824125287209dd59253f5a5f155cc9dead7787/image/wildfly/Dockerfile.wildfly.38))<br><br><br><br><br>                                                                       | **Debian** 13.5 "trixie"<br>**openJRE** 21.0.11<br>**MySQL-Connector** 9.7.0<br>**MariaDB-Connector** 3.5.8<br>**PostgreSQL-Connector** 42.7.11                                                       |
| 2026-03-09                             | [38-20260309](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=38-20260309) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/f363ed74591a391300df0b15bd4dbc1c145bb29e/image/wildfly/Dockerfile.wildfly.38))                                                                                                                                                                 | **fixed** cli reinitializing                                                                                                                                                                          |
| 2026-03-03<br><br><br>                 | [38-20260303](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=38-20260303) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/ae5fe9e3cbc931311c7af8e82d54c1a2c67c0d7e/image/wildfly/Dockerfile.wildfly.38))<br><br><br>                                                                                                                                                     | **WildFly** 38.0.1.Final<br>**MySQL-Connector** 9.6.0<br>**PostgreSQL-Connector** 42.7.10                                                                                                             |
| 2026-01-26<br><br><br><br><br>         | [38-20260126](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=38-20260126) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/edf0ca327bc7a7c9c6c10f78b37eb2ffd0e8aad3/image/wildfly/Dockerfile.wildfly.38))<br><br><br><br><br>                                                                                                                                             | **Debian** 13.3 "trixie"<br>**openJRE** 21.0.10<br>**MariaDB-Connector** 3.5.7<br>**PostgreSQL-Connector** 42.7.9<br>**EclipseLink** 4.0.9                                                            |
| 2025-12-10                             | [38-20251210](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=38-20251210)                                                                                                                                                                                                                                                                                                        | **Debian** 13.2 "trixie"                                                                                                                                                                              |
| 2025-10-29<br><br><br><br><br><br><br> | [38-20251029](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=38-20251029) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/ecb95c6bb8ec6f3ae076db198bcf43000e3da7c7/image/wildfly/Dockerfile.wildfly.38))<br><br><br><br><br><br><br>                                                                                                                                     | **Debian** 13.1 "trixie"<br>**openJRE** 21.0.9<br>**WildFly** 38.0.0.Final<br>**MySQL-Connector** 9.5.0<br>**MariaDB-Connector** 3.5.6<br>**PostgreSQL-Connector** 42.7.8<br>**EclipseLink** 4.0.8    |
| 2025-07-22                             | [36-20250722](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=36-20250722), [36](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=36)                                                                                                                                                                                                                                  | **openJRE** 21.0.8                                                                                                                                                                                    |
| 2025-06-13<br><br><br>                 | [36-20250613](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=36-20250613) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/60eba00105594e9926993fcbab8da803494a5d26/image/wildfly/Dockerfile.wildfly.36))<br><br><br>                                                                                                                                                     | **Debian** 12.11 "bookworm"<br>**PostgreSQL-Connector** 42.7.7<br>**EclipseLink** 4.0.7                                                                                                               |
| 2025-05-16                             | [36-20250516](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=36-20250516) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/b9aff4016adff28c984443545026c4bd218ea2c8/image/wildfly/Dockerfile.wildfly.36))                                                                                                                                                                 | **WildFly** 36.0.1.Final                                                                                                                                                                              |
