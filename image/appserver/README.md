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
| Category   | Variable            | Available values or scheme | Default  | Purpose                                                                                           |
|------------|---------------------|----------------------------|----------|---------------------------------------------------------------------------------------------------|
| WF-Admin   | WF_NO_ADMIN         | true, false                | false    | set `true` if you don't need wildfly-admin                                                        |
| WF-Admin   | WF_ADMIN_USER       | \<STRING\>                 | admin    | define username for wildfly-admin                                                                 |
| WF-Admin   | WF_ADMIN_PASS       | \<STRING\>                 | -random- | to set password for wildfly-admin                                                                 |
| Quality    | WF_HEALTHCHECK_URLS | \<NEWLINE-SEPARATED-URLs\> | -        | contain a list of urls to check the health of this container                                      |
| Optimizing | WF_ADD_CLI_FILTER   | \<PIPE-SEPARATED-STRING\>  | -        | define additional pipe-separated file-extensions that jboss-cli should process                    |
| Optimizing | WF_MARKERFILES      | true, false, auto          | auto     | these affect the creation of marker-files (.isdeploying or .deployed) in the deployment-directory |
| Optimizing | JAVA_OPTS           | \<STRING\>                 | -        | you need more memory? then give yourself more memory and any more                                 |
| Debugging  | WF_DEBUG            | true, false                | false    | set `true` to enable debug-mode in wildfly                                                        |
| Debugging  | DEBUG_PORT          | \<IP\>:\<PORT\>            | *:8787   | for debugging you can change the ip:port                                                          |


## Relevant Entrypoints
| Path                            | ref. ENV-Variable     | Type   | Purpose                                                                                          |
|---------------------------------|-----------------------|--------|--------------------------------------------------------------------------------------------------|
| /entrypoint-wildfly-cli         | ENTRY_WILDFLY_CLI     | folder | to execute JBoss-cli-files before start WildFly (read-only access)                               |
| /entrypoint-wildfly-deployments | ENTRY_WILDFLY_DEPLOYS | folder | to import your deployments, also ear- and/or war-files (read-only access, optional write access) |
| /entrypoint-wildfly-addins      | ENTRY_WILDFLY_ADDINS  | folder | to import additional files for deployments (read-only access)                                    |
| /entrypoint-wildfly-logs        | ENTRY_WILDFLY_LOGS    | folder | to export all available log-files (read/write access)                                            |


## Usage
```shell
# build wildfly-image (required java-image mosaicgreifswald/java:latest)
> cd mosaic-hgw/Docker/image/appserver
> docker build --tag="mosaicgreifswald/wildfly:latest" --file="Dockerfile.app.wf26" .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/wildfly:latest versions
  last updated               : 2023-04-14 11:01:17
  Distribution               : Debian GNU/Linux 11.6
  zulu-jre                   : 17.0.6
  WildFly                    : 26.1.3.Final
  MySQL-Connector            : 8.0.32
  EclipseLink                : 2.7.12
  KeyCloak-Client            : 19.0.2

# "entrypoints" lists all registered entrypoints.
> docker run --rm mosaicgreifswald/wildfly:latest entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
  ENTRY_JAVA_CACERTS         : /entrypoint-java-cacerts
  ENTRY_WILDFLY_CLI          : /entrypoint-wildfly-cli
  ENTRY_WILDFLY_DEPLOYS      : /entrypoint-wildfly-deployments
  ENTRY_WILDFLY_ADDINS       : /entrypoint-wildfly-addins
  ENTRY_WILDFLY_LOGS         : /entrypoint-wildfly-logs

# simple start with your deployments and without admin-user
> docker run --rm \
    -e WF_NO_ADMIN=true \
    -p 8080:8080 \
    -v /path/to/your/deployments:/entrypoint-wildfly-deployments \
    mosaicgreifswald/wildfly:latest

# if your deployment folder is write-protected, you can explicitly switch off the markerfiles
> docker run --rm \
    -e WF_ADMIN_PASS=top-secret \
    -e WF_MARKERFILES=false \
    -e WF_HEALTHCHECK_URLS=http://localhost:8080\nhttp://localhost:8080/your-app.html \
    -p 8080:8080 \
    -p 9990:9990 \
    -v /path/to/your/deployments:/entrypoint-wildfly-deployments \
    -v /path/to/your/batch-files:/entrypoint-wildfly-cli \
    mosaicgreifswald/wildfly:latest

```
