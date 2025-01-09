## General
The WildFly image has the most use cases for us.
It can be used directly with Docker Compose, or serves as the basis for other images itself.
This image can be started directly without building your own image first.
Of course, you can still build your own image.

## About Health-Check-Strategies
There are 3 strategies built into this docker image.

* Microprofile-Health<br>
  This is the default strategy and only works if the `WF_ADMIN_PASS` variable is set. Then the WildFly management automatically checks all deployments that have the microprofile installed (see https://microprofile.io/project/eclipse/microprofile-health).
* URL-check<br>
  For this strategy at least one accessible URL must be specified as ENV-variable `WF_HEALTHCHECK_URLS`. If a URL is not reachable or does not return the HTTP status code 200, the health status is set to "unhealthly". This strategy can be combined with Microprofile-Health.
* Running-Deployments<br>
  This solution only works if neither of the other two strategies is used. It only checks that none of the deployments has booted incorrectly.


## Relevant ENV Variables
| Category   | Variable                     | Available values or scheme                       | Default           | Purpose                                                                                                   |
|------------|------------------------------|--------------------------------------------------|-------------------|-----------------------------------------------------------------------------------------------------------|
| WF-Admin   | WF_NO_ADMIN                  | true \| false                                    | false             | set `true` if you don't need wildfly-admin                                                                |
| WF-Admin   | WF_ADMIN_USER                | \<STRING\>                                       | admin             | define username for wildfly-admin                                                                         |
| WF-Admin   | WF_ADMIN_PASS                | \<STRING\>                                       | -random-          | to set password for wildfly-admin                                                                         |
| Quality    | WF_HEALTHCHECK_URLS          | \<NEWLINE-SEPARATED-URLs\>                       | -                 | contain a list of urls to check the health of this container                                              |
| Optimizing | TZ                           | \<STRING\>                                       | Europe/Berlin     | timezone                                                                                                  |
| Optimizing | WF_ADD_CLI_FILTER            | \<PIPE-SEPARATED-STRING\>                        | -                 | define additional pipe-separated file-extensions that jboss-cli should process                            |
| Optimizing | WF_MARKERFILES               | true \| false \| auto                            | auto              | these affect the creation of marker-files (.isdeploying or .deployed) in the deployment-directory         |
| Optimizing | WF_MAX_POST_SIZE             | \<BYTES\>                                        | 10485760          | the maximum size of a post that will be accepted, in bytes                                                |
| Optimizing | WF_MAX_PARAMETERS            | \<NUMBER\>                                       | 100000            | the maximum number of parameters that will be parsed                                                      |
| Optimizing | WF_MAX_CHILD_ELEMENTS        | \<NUMBER\>                                       | 50000             | the maximum number of children that will be allow in xml-post                                             |
| Optimizing | WF_BLOCKING_TIMEOUT          | \<SECONDS\>                                      | 300               | this can be used to change the time until processes are cancelled                                         |
| Optimizing | WF_TRANSACTION_TIMEOUT       | \<SECONDS\>                                      | 300               | this can be used to change the time after which a transaction is automatically terminated                 |
| Optimizing | WF_ENABLE_HTTP2              | true \| false                                    | false             | HTTP2 support                                                                                             |
| Optimizing | JAVA_OPTS                    | \<STRING\>                                       | -Xms1G -Xmx6G ... | you need more memory? then give yourself more memory or define any system-variables                       |
| Security   | WF_SERVER_KEYSTORE_PASSWORD  | \<STRING\>                                       | -                 | this password is only used in combination with /entrypoint-wildfly-server-keystore to access the keystore |
| Security   | WF_SERVER_KEYSTORE_ALIAS     | \<STRING\>                                       | -                 | if there is more than one certificate in the keystore, this alias must be specified                       |
| Logging    | WF_SYSTEM_LOG_LEVEL          | TRACE \| DEBUG \| INFO \| WARN \| ERROR \| FATAL | INFO              | this can be used to set the log level of the console                                                      |
| Logging    | WF_SYSTEM_LOG_TO             | CONSOLE, FILE                                    | CONSOLE           | multiple values semicolon-separated possible                                                              |
| Debugging  | WF_DEBUG                     | true \| false                                    | false             | set `true` to enable debug-mode in wildfly                                                                |
| Debugging  | DEBUG_PORT                   | \<IP\>:\<PORT\>                                  | *:8787            | for debugging you can change the ip:port                                                                  |

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
# build wildfly-image (required java-image mosaicgreifswald/zulujre:21)
> git clone https://github.com/mosaic-hgw/Docker.git
> cd mosaic-hgw/Docker/image/wildfly
> docker build --tag="mosaicgreifswald/wildfly" --file="Dockerfile.wildfly.35" .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/wildfly versions
  last updated               : 2025-01-09 09:59:53
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 12.8
  zulu-jre                   : 21.0.5
  WildFly                    : 35.0.0.Final
  MySQL-Connector            : 9.1.0
  EclipseLink                : 4.0.5

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
drwxr-xr-x  2 1006 1001 4096 11. Dez 10:25 .
drwxrwxrwt 10 root root 4096 11. Dez 10:26 ..
-rw-r--r--  1 1006 1001    0 11. Dez 10:25 server.log
drwxr-xr-x  2 1006 1001 4096 11. Dez 10:25 system
```

## Usage with docker compose
over docker-compose with dependent on mysql-db (example)
```yml
# docker-compose.yml

version: '3'
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
    volumes:
      - /path/to/your/cli-files:/entrypoint-wildfly-cli
      - /path/to/your/deployments:/entrypoint-wildfly-deployments
    entrypoint: /bin/bash
    command: -c "./wait-for-it.sh mysql:3306 -t 60 && ./run.sh"
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

* add postgresql-jdbc-driver-module and datasource
  ```sh
  # add-postgre-datasource.cli

  batch

  module add \
    --name=org.postgre \
    --resources=/entrypoint-wildfly-cli/postgresql.jar \
    --dependencies=javax.api,javax.transaction.api

  /subsystem=datasources/jdbc-driver=postgre: \
    add( \
      driver-name="postgre", \
      driver-module-name="org.postgre", \
      driver-class-name=org.postgresql.Driver \
    )

  data-source add \
    --name=PostgreSQLPool \
    --jndi-name=java:/jboss/PostgreSQLDS \
    --connection-url=jdbc:postgresql://app-db:5432/dbName \
    --user-name=mosaic \
    --password=top-secret \
    --driver-name=postgre

  run-batch
  ```

## Additional files
```shell
# see all additional files
> docker run --rm -it mosaicgreifswald/wildfly bash -c "cd /entrypoint-help-and-usage; ls -lah --color; bash"

# or copy all to local host
> docker run --rm -v "$(pwd)":"$(pwd)" mosaicgreifswald/wildfly bash -c "cp -R /entrypoint-help-and-usage $(pwd)/help-and-usage"
```
You will receive the following directory-tree and can start playing immediately:
```
├─┬─ layer-readme/
│ ├─── README-debian.md
│ ├─── README-wildfly.md
│ └─── README-zulujre.md
└─┬─ examples/
  ├─┬─ compose-wildfly-dbdriver/
  │ ├─── jboss/
  │ └─┬─ add_x_driver.cli
  │   └─── docker-compose.yml
  ├─┬─ compose-wildfly-empty/
  │ ├─── addins/
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
| Date                               | Tags                                                                                                                                                                             | Changes                                                                                                                                                            |
|------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2025-01-09<br><br><br>             | `35-20250109`, `35`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/b665e95c2d14b6aedcd4a166690dd9dbd12a55d9/image/wildfly/Dockerfile.wildfly.34))<br><br><br> | **WildFly** 35.0.0.Final<br>**EclipseLink** 4.0.5<br>added support for docker-parameter --user/-u                                                                  |
| 2025-01-09<br><br>                 | `34-20250109`, `34` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/93e62f93916fcf485357a40b835eb98a6c103a1e/image/wildfly/Dockerfile.wildfly.34))<br><br>               | **EclipseLink** 4.0.5<br>added support for docker-parameter --user/-u                                                                                              |
| 2024-11-26                         | `34-20241126` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/36531af13f029f03a4781d42ebf647ff2deaafcd/image/wildfly/Dockerfile.wildfly.34))                             | **WildFly** 34.0.1.Final                                                                                                                                           |
| 2024-11-11<br><br><br><br>         | `34-20241111` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/36531af13f029f03a4781d42ebf647ff2deaafcd/image/wildfly/Dockerfile.wildfly.34))<br><br><br><br>             | **Debian** 12.8 "bookworm"<br>**openJRE** 21.0.5<br>**WildFly** 34.0.0.Final<br>**MySQL-Connector** 9.1.0                                                          |
| 2024-11-11<br><br><br>             | `32-20241111`, `32` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/24838931a9c6d473a1d18377a79df9ef9674a872/image/wildfly/Dockerfile.wildfly.32))<br><br><br>           | **Debian** 12.8 "bookworm"<br>**openJRE** 21.0.5<br>**MySQL-Connector** 9.1.0                                                                                      |
| 2024-09-09<br><br>                 | `32-20240909` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/77443c702b70f94709874960b54328a478d6c880/image/wildfly/Dockerfile.wildfly.32))<br><br>                     | **Debian** 12.7 "bookworm"<br>experimental keystore for server-certificate                                                                                         |
| 2024-07-22<br><br><br>             | `32-20240722` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/29efa4dff981372bf2b64b1ec87d5138af89dd37/image/wildfly/Dockerfile.wildfly.32))<br><br><br>                 | **Debian** 12.6 "bookworm"<br>**openJRE** 21.0.4<br>**EclipseLink** 4.0.4                                                                                          |
| 2024-06-10                         | `32-20240610` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/d1c1e88fcfd5584f998ece1a355e9be6f34cb579/image/wildfly/Dockerfile.wildfly.32))                             | **MySQL-Connector** 8.4.0                                                                                                                                          |
| 2024-06-03                         | `32-20240603` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/af941b41a16285b1789fe36ea0af2bb7a3b7f70f/image/wildfly/Dockerfile.wildfly.32))                             | **WildFly** 32.0.1.Final                                                                                                                                           |
| 2024-05-23                         | `32-20240523` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/ad6ba5ba960d9e29f00cbe8bc92b4fcdb0d5aec1/image/wildfly/Dockerfile.wildfly.32))                             | **EclipseLink** 4.0.3                                                                                                                                              |
| 2024-05-13                         | `32-20240513`                                                                                                                                                                    | fixed vulnerabilities in libc                                                                                                                                      |
| 2024-04-29                         | `32-20240429` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/c6a78e0ada518ee18f08aaa19a6e1b57441317c9/image/wildfly/Dockerfile.wildfly.32))                             | **WildFly** 32.0.0.Final                                                                                                                                           |
| 2024-04-18<br><br><br><br>         | `31` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/a5e21db40b173fb988d9bb8eebc2807f646f7004/image/wildfly/Dockerfile.wildfly.31))<br><br><br><br>                      | **Debian** 12.5 "bookworm"<br>**openJRE** 21.0.3<br>**WildFly** 31.0.1.Final<br>**MySQL-Connector** 8.3.0                                                          |
| 2024-01-11<br><br><br><br><br>     | `30` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/7377469445d77d08e4556d4158cfc52df7a45410/image/appserver/Dockerfile.app.wf30))<br><br><br><br><br>                  | **Debian** 12.4 "bookworm"<br>**openJRE** 21.0.1<br>**WildFly** 30.0.1.Final<br>**MySQL-Connector** 8.2.0<br>**EclipseLink** 4.0.2                                 |
| 2023-10-30<br><br><br><br><br>     | `29`<br><br><br><br><br>                                                                                                                                                         | **Debian** 12.2 "bookworm"<br>**openJRE** 17.0.9<br>**WildFly** 29.0.1.Final<br>**EclipseLink** 4.0.2<br>**KeyCloak-Client** deleted                               |
| 2023-12-19<br><br>                 | `26-20231219`, `26` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/7377469445d77d08e4556d4158cfc52df7a45410/image/appserver/Dockerfile.app.wf26))<br><br>               | **Debian** 12.4 "bookworm"<br>**EclipseLink** 2.7.14                                                                                                               |
| 2023-10-30<br><br>                 | `26-20231030`<br><br>                                                                                                                                                            | **Debian** 12.2 "bookworm"<br>**openJRE** 17.0.9                                                                                                                   |
| 2023-07-13                         | `26-20230713`                                                                                                                                                                    | **Debian** 12.0 "bookworm"                                                                                                                                         |
| 2023-05-23                         | `26-20230523`                                                                                                                                                                    | **Debian** 11.7 "bullseye"                                                                                                                                         |
| 2023-04-25<br><br><br><br><br><br> | `26-20230425`<br><br><br><br><br><br>                                                                                                                                            | **Debian** 11.6 "bullseye"<br>**ZuluJRE** 17.0.7<br>**WildFly** 26.1.3.Final<br>**MySQL-Connector** 8.0.33<br>**EclipseLink** 2.7.12<br>**KeyCloak-Client** 19.0.2 |
