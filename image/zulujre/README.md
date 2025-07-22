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


## Usage (for the average consumer)
```shell
# build java-image
> cd mosaic-hgw/Docker/images/zulujre
> docker build --tag="mosaicgreifswald/zulujre" --file="Dockerfile.zulujre" .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/zulujre versions
  last updated               : 2025-07-21 17:56:41
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 12.11
  zulu-jre                   : 21.0.8
  
# "entrypoints" lists all registered entrypoints.
> docker run --rm mosaicgreifswald/zulujre entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
  ENTRY_USAGE                : /entrypoint-help-and-usage
  ENTRY_JAVA_CACERTS         : /entrypoint-java-cacerts

# get java-version
> docker run --rm -it mosaicgreifswald/zulujre java -version
openjdk version "21.0.8" 2025-07-15 LTS
```

## Special usage, multiple java-versions (whoever needs it)
```shell
# build second java-image, based on the image above
> docker build --tag="mosaicgreifswald/zulujre:17-21" --file="Dockerfile.zulujre" --build-arg JAVA_VERSION=17 --build-arg TAG=mosaicgreifswald/zulujre:latest .

# show all versions (last installed java is per default selected as "current") 
> docker run --rm mosaicgreifswald/zulujre:17-21 versions
  last updated               : 2025-07-21 18:06:31
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 12.11
  zulu-jre                   : 21.0.8
  zulu-jre                   : 17.0.15 (current)

> docker run --rm mosaicgreifswald/zulujre:17-21 java -version
openjdk version "17.0.15" 2025-04-15 LTS

# switch java-version per environment-variable
> docker run --rm -e JAVA_VERSION=21 mosaicgreifswald/zulujre:17-21 versions
  last updated               : 2025-07-21 18:06:31
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 12.11
  zulu-jre                   : 21.0.8 (current)
  zulu-jre                   : 17.0.15

> docker run --rm -e JAVA_VERSION=21 mosaicgreifswald/zulujre:17-21 java -version
openjdk version "21.0.8" 2025-07-15 LTS

# switch java-version in running container
> docker run --rm -it mosaicgreifswald/zulujre:17-21 bash
> java -version
openjdk version "17.0.15" 2025-04-15 LTS

> JAVA_VERSION=21; java -version
openjdk version "21.0.8" 2025-07-15 LTS
```

## Current Software-Versions on this Image
| Date               | Tags                                                                                                                                                                                                                                     | Changes                                         |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------|
| 2025-07-22<br><br> | [21.0.8](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=21.0.8), [21](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=21), [latest](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=latest)<br><br> | **Debian** 12.11 "bookworm"<br>**Java** 21.0.8  |
| 2025-04-25<br><br> | [21.0.7](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=21.0.7) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/5a4e7537aa5a67634c13662101f5f6ca44ac30d2/image/zulujre/Dockerfile.zulujre))<br><br>                 | **Debian** 12.10 "bookworm"<br>**Java** 21.0.7  |
| 2025-01-24<br><br> | [21.0.6](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=21.0.6) <br><br>                                                                                                                                                    | **Debian** 12.9 "bookworm"<br>**Java** 21.0.6   |
| 2025-01-13<br><br> | [21.0.5](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=21.0.5)<br><br>                                                                                                                                                     | **Debian** 12.8 "bookworm"<br>**Java** 21.0.5   |
| 2024-09-09<br><br> | [21.0.4](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=21.0.4) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/081d44affc8e3048c38689d3e2780ad777b915f5/image/zulujre/Dockerfile.zulujre))<br><br>                 | **Debian** 12.7 "bookworm"<br>**Java** 21.0.4   |
| 2024-03-05<br><br> | [21.0.2](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=21.0.2)<br><br>                                                                                                                                                     | **Debian** 12.5 "bookworm"<br>**Java** 21.0.2   |
| 2023-12-11         | [21.0.1](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=21.0.1)                                                                                                                                                             | **Java** 21.0.1                                 |
| 2023-12-11         | [17.0.9-1](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=17.0.9-1), [17](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=17)                                                                                   | **Debian** 12.4 "bookworm"                      |
| 2023-10-30<br><br> | [17.0.9](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=17.0.9)<br><br>                                                                                                                                                     | **Debian** 12.2 "bookworm"<br>**Java** 17.0.9   |
| 2023-09-28<br><br> | [17.0.8.1](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=17.0.8.1)<br><br>                                                                                                                                                 | **Debian** 12.1 "bookworm"<br>**Java** 17.0.8.1 |
| 2023-04-25<br><br> | [17.0.7](https://hub.docker.com/r/mosaicgreifswald/wildfly/tags?name=17.0.7) ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/3441209dd6b8ef2892a6e264ad58898c805e0114/image/java/Dockerfile.jre.zulu))<br><br>                   | **Debian** 11.6 "bullseye"<br>**Java** 17.0.7   |
