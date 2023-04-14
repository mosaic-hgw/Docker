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
> docker build --tag="mosaicgreifswald/java:latest" --file="Dockerfile.jre.zulu" --build-arg JAVA_VERSION=17 .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/java:latest versions
  last updated               : 2023-04-14 10:45:51
  Distribution               : Debian GNU/Linux 11.6
  zulu-jre                   : 17.0.6
  
# "entrypoints" lists all registered entrypoints.
> docker run --rm mosaicgreifswald/java:latest entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
  ENTRY_JAVA_CACERTS         : /entrypoint-java-cacerts

# get java-version
> docker run --rm -it mosaicgreifswald/java:latest java -version
openjdk version "17.0.6" 2023-01-17 LTS
OpenJDK Runtime Environment Zulu17.40+19-CA (build 17.0.6+10-LTS)
OpenJDK 64-Bit Server VM Zulu17.40+19-CA (build 17.0.6+10-LTS, mixed mode, sharing)
```

