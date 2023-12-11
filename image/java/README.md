## General
This layer is mainly needed for our MOSIAC-Images WildFly and jMeter, as only these require an installed Java.
Only the slimmer JRE from Azul-Zulu is installed.


## Relevant Entrypoints
| Path                     | ref. ENV-Variable  | Type | Purpose                                                                                                                            |
|--------------------------|--------------------|------|------------------------------------------------------------------------------------------------------------------------------------|
| /entrypoint-java-cacerts | ENTRY_JAVA_CACERTS | file | The entrypoint can be used to store its own cacerts, e.g. containing public-keys of server-certificates for specific web requests. |


## Relevant Build Arguments
| Varaible     | Available values or scheme   | Default | Purpose                                                                   |
|--------------|------------------------------|---------|---------------------------------------------------------------------------|
| JAVA_VERSION | \<VALID_JAVA_MAJOR_VERSION\> | 21      | Here you can modify the java version with which the image is to be built. |


## Usage
```shell
# build java-image
> cd mosaic-hgw/Docker/images/java
> docker build --tag="mosaicgreifswald/zulujre:latest" --file="Dockerfile.jre.zulu" --build-arg JAVA_VERSION=21 .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/zulujre:latest versions
  last updated               : 2023-12-11 10:23:10
  Distribution               : Debian GNU/Linux 12.4
  zulu-jre                   : 21.0.1
  
# "entrypoints" lists all registered entrypoints.
> docker run --rm mosaicgreifswald/zulujre:latest entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
  ENTRY_JAVA_CACERTS         : /entrypoint-java-cacerts

# get java-version
> docker run --rm -it mosaicgreifswald/zulujre:latest java -version
openjdk version "21.0.1" 2023-10-17 LTS
OpenJDK Runtime Environment Zulu21.30+15-CA (build 21.0.1+12-LTS)
OpenJDK 64-Bit Server VM Zulu21.30+15-CA (build 21.0.1+12-LTS, mixed mode, sharing)
```

## Current Software-Versions on this Image
| Date       | Tags                                                                                                   | Changes                                         |
|------------|--------------------------------------------------------------------------------------------------------|-------------------------------------------------|
| 2023-12-11 | `21.0.1`, `21`, `latest`                                                                               | **Debian** 12.4 "bookworm"<br>**Java** 21.0.1   |
| 2023-12-11 | `17.0.9-1`, `17`                                                                                       | **Debian** 12.4 "bookworm"<br>**Java** 17.0.9   |
| 2023-10-30 | `17.0.9`                                                                                               | **Debian** 12.2 "bookworm"<br>**Java** 17.0.9   |
| 2023-09-28 | `17.0.8.1`                                                                                             | **Debian** 12.1 "bookworm"<br>**Java** 17.0.8.1 |
| 2023-04-25 | `17.0.7` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/main/image/java/Dockerfile.jre.zulu)) | **Debian** 11.6 "bullseye"<br>**Java** 17.0.7   |
