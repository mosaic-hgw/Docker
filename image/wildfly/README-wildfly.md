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
| Category   | Variable            | Available values or scheme               | Default       | Purpose                                                                                           |
|------------|---------------------|------------------------------------------|---------------|---------------------------------------------------------------------------------------------------|
| Optimizing | TZ                  | \<STRING\>                               | Europe/Berlin |                                                                                                   |
| Optimizing | MOS_RUN_MODE        | action \| service \| cascade \| external | service       |                                                                                                   |
| WF-Admin   | WF_NO_ADMIN         | true \| false                            | false         | set `true` if you don't need wildfly-admin                                                        |
| WF-Admin   | WF_ADMIN_USER       | \<STRING\>                               | admin         | define username for wildfly-admin                                                                 |
| WF-Admin   | WF_ADMIN_PASS       | \<STRING\>                               | -random-      | to set password for wildfly-admin                                                                 |
| Quality    | WF_HEALTHCHECK_URLS | \<NEWLINE-SEPARATED-URLs\>               | -             | contain a list of urls to check the health of this container                                      |
| Optimizing | WF_ADD_CLI_FILTER   | \<PIPE-SEPARATED-STRING\>                | -             | define additional pipe-separated file-extensions that jboss-cli should process                    |
| Optimizing | WF_MARKERFILES      | true \| false \| auto                    | auto          | these affect the creation of marker-files (.isdeploying or .deployed) in the deployment-directory |
| Optimizing | JAVA_OPTS           | \<STRING\>                               | -             | you need more memory? then give yourself more memory or define any system-variables               |
| Debugging  | WF_DEBUG            | true \| false                            | false         | set `true` to enable debug-mode in wildfly                                                        |
| Debugging  | DEBUG_PORT          | \<IP\>:\<PORT\>                          | *:8787        | for debugging you can change the ip:port                                                          |

```shell
# more with "envs"
> docker run --rm mosaicgreifswald/wildfly envs
```

## Relevant Entrypoints
| Path                            | ref. ENV-Variable     | Type   | Purpose                                                                                                                            |
|---------------------------------|-----------------------|--------|------------------------------------------------------------------------------------------------------------------------------------|
| /entrypoint-logs                | ENTRY_LOGS            | folder | All further layers can store their own log files here in subdirectories.                                                           |
| /entrypoint-java-cacerts        | ENTRY_JAVA_CACERTS    | file   | The entrypoint can be used to store its own cacerts, e.g. containing public-keys of server-certificates for specific web requests. |
| /entrypoint-wildfly-cli         | ENTRY_WILDFLY_CLI     | folder | to execute JBoss-cli-files before start WildFly (read-only access)                                                                 |
| /entrypoint-wildfly-deployments | ENTRY_WILDFLY_DEPLOYS | folder | to import your deployments, also ear- and/or war-files (read-only access, optional write access)                                   |
| /entrypoint-wildfly-addins      | ENTRY_WILDFLY_ADDINS  | folder | to import additional files for deployments (read-only access)                                                                      |
| /entrypoint-wildfly-logs        | ENTRY_WILDFLY_LOGS    | folder | to export all available log-files (read/write access)                                                                              |

```shell
# similar with "entrypoints"
> docker run --rm mosaicgreifswald/wildfly entrypoints
```

## Usage
```shell
# build wildfly-image (required java-image mosaicgreifswald/java:latest)
> cd mosaic-hgw/Docker/image/appserver
> docker build --tag="mosaicgreifswald/wildfly" --file="Dockerfile.app.wf26" .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/wildfly versions
  last updated               : 2023-12-19 14:56:32
  Distribution               : Debian GNU/Linux 12.4
  zulu-jre                   : 17.0.9
  WildFly                    : 26.1.3.Final
  MySQL-Connector            : 8.0.33
  EclipseLink                : 2.7.14
  KeyCloak-Client            : 19.0.2

# simple start with your deployments and without admin-user
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
> docker run --rm -it mosaicgreifswald/wildfly bash -c "cd /entrypoint-help-and-usage; ls -lah; bash"

# or copy all to local host
> docker run --rm -v "$(pwd)":"$(pwd)" mosaicgreifswald/wildfly bash -c "cp -R /entrypoint-help-and-usage $(pwd)/help-and-usage"
```
You will receive the following directory-tree and can start playing immediately:
```
|___layer-readme/
| |___README-debian.md
  |___README-wildfly.md
| |___README-zulujre.md
|___examples/
  |___compose-wildfly-dbdriver/
  | |___jboss/
  | | |___add_x_driver.cli
  | |___docker-compose.yml
  |___compose-wildfly-empty/
  | |___addins/
  | |___envs/
  | | |___wf_commons.env
  | |___jboss/
  | |___logs/
  | |___sqls/
  | |___docker-compose.yml
  |___pure-envs/
    |___debian.env
    |___wf_commons.env
    |___zulujre.env
```


## Current Software-Versions on this Image
| Date                               | Tags                                                                                                                                                  | Changes                                                                                                                                                            |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2024-03-05<br><br><br><br><br>     | `31-20240305`, `31`, `preview` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/main/image/appserver/Dockerfile.app.wf31))<br><br><br><br><br> | **Debian** 12.5 "bookworm"<br>**openJRE** 21.0.2<br>**WildFly** 31.0.1.Final<br>**MySQL-Connector** 8.3.0<br>**EclipseLink** 4.0.2                                 |
| 2024-01-11<br><br><br><br><br>     | `30` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/main/image/appserver/Dockerfile.app.wf30))<br><br><br><br><br>                           | **Debian** 12.4 "bookworm"<br>**openJRE** 21.0.1<br>**WildFly** 30.0.1.Final<br>**MySQL-Connector** 8.2.0<br>**EclipseLink** 4.0.2                                 |
| 2023-10-30<br><br><br><br><br>     | `29`<br><br><br><br><br>                                                                                                                              | **Debian** 12.2 "bookworm"<br>**openJRE** 17.0.9<br>**WildFly** 29.0.1.Final<br>**EclipseLink** 4.0.2<br>**KeyCloak-Client** deleted                               |
| 2023-12-19<br><br>                 | `26-20231219`, `26`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/main/image/appserver/Dockerfile.app.wf26))<br><br>              | **Debian** 12.4 "bookworm"<br>**EclipseLink** 2.7.14                                                                                                               |
| 2023-10-30<br><br>                 | `26-20231030`<br><br>                                                                                                                                 | **Debian** 12.2 "bookworm"<br>**openJRE** 17.0.9                                                                                                                   |
| 2023-07-13                         | `26-20230713`                                                                                                                                         | **Debian** 12.0 "bookworm"                                                                                                                                         |
| 2023-05-23                         | `26-20230523`                                                                                                                                         | **Debian** 11.7 "bullseye"                                                                                                                                         |
| 2023-04-25<br><br><br><br><br><br> | `26-20230425`<br><br><br><br><br><br>                                                                                                                 | **Debian** 11.6 "bullseye"<br>**ZuluJRE** 17.0.7<br>**WildFly** 26.1.3.Final<br>**MySQL-Connector** 8.0.33<br>**EclipseLink** 2.7.12<br>**KeyCloak-Client** 19.0.2 |
