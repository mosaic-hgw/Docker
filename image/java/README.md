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
| JAVA_VERSION | \<VALID_JAVA_MAJOR_VERSION\> | 17      | Here you can modify the java version with which the image is to be built. |


## Usage
```shell
# build java-image
> cd mosaic-hgw/Docker/images/java
> docker build --tag="mosaicgreifswald/zulujre:latest" --file="Dockerfile.jre.zulu" --build-arg JAVA_VERSION=17 .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/zulujre:latest versions
  last updated               : 2023-09-28 10:45:51
  Distribution               : Debian GNU/Linux 12.1
  zulu-jre                   : 17.0.8.1
  
# "entrypoints" lists all registered entrypoints.
> docker run --rm mosaicgreifswald/zulujre:latest entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
  ENTRY_JAVA_CACERTS         : /entrypoint-java-cacerts

# get java-version
> docker run --rm -it mosaicgreifswald/zulujre:latest java -version
openjdk version "17.0.8.1" 2023-08-24 LTS
OpenJDK Runtime Environment Zulu17.44+53-CA (build 17.0.8.1+1-LTS)
OpenJDK 64-Bit Server VM Zulu17.44+53-CA (build 17.0.8.1+1-LTS, mixed mode, sharing)
```

## Current Software-Versions on this Image
| Date       | Tags                                                                                                   | Changes                                         |
|------------|--------------------------------------------------------------------------------------------------------|-------------------------------------------------|
| 2023-09-28 | `17`, `17.0.8.1`, `latest`                                                                             | **Debian** 12.1 "bookworm"<br>**Java** 17.0.8.1 |
| 2023-04-25 | `17.0.7` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/main/image/java/Dockerfile.jre.zulu)) | **Debian** 11.6 "bullseye"<br>**Java** 17.0.7   |
