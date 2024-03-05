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
> cd mosaic-hgw/Docker/images/java
> docker build --tag="mosaicgreifswald/zulujre:17" --build-arg JAVA_VERSION=17 .

# "versions" shows all installed tools and components, with their versions
> docker run --rm mosaicgreifswald/zulujre:17 versions
  last updated               : 2023-12-21 15:10:11
  Distribution               : Debian GNU/Linux 12.4
  zulu-jre                   : 17.0.9
  
# "entrypoints" lists all registered entrypoints
> docker run --rm mosaicgreifswald/zulujre:17 entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
  ENTRY_JAVA_CACERTS         : /entrypoint-java-cacerts

# get java-version
> docker run --rm -it mosaicgreifswald/zulujre:17 java -version
openjdk version "17.0.9" 2023-10-17 LTS
```

## Special usage, multible java-versions (whoever needs it)
```shell
# build second java-image, based on the image above
> docker build --tag="mosaicgreifswald/zulujre:17-21" --build-arg JAVA_VERSION=21 --build-arg TAG=mosaicgreifswald/zulujre:17 .

# show all versions (last installed java is per default selected as "current") 
> docker run --rm mosaicgreifswald/zulujre:17-21 versions
  last updated               : 2023-12-21 15:10:11
  Distribution               : Debian GNU/Linux 12.4
  zulu-jre                   : 17.0.9
  zulu-jre                   : 21.0.1 (current)

> docker run --rm mosaicgreifswald/zulujre:17-21 java -version
openjdk version "21.0.1" 2023-10-17 LTS

# switch java-version per environment-variable
> docker run --rm -e JAVA_VERSION=17 mosaicgreifswald/zulujre:17-21 versions
  last updated               : 2023-12-21 15:10:11
  Distribution               : Debian GNU/Linux 12.4
  zulu-jre                   : 17.0.9 (current)
  zulu-jre                   : 21.0.1

> docker run --rm -e JAVA_VERSION=17 mosaicgreifswald/zulujre:17-21 java -version
openjdk version "17.0.9" 2023-10-17 LTS

# switch java-version in running container
> docker run --rm -it mosaicgreifswald/zulujre:17-21 bash
> java -version
openjdk version "21.0.1" 2023-10-17 LTS

> JAVA_VERSION=17; java -version
openjdk version "17.0.9" 2023-10-17 LTS
```

## Current Software-Versions on this Image
| Date       | Tags                                                                                                                                       | Changes                                         |
|------------|--------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------|
| 2024-03-05 | `21.0.2`, `21`, `latest` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/main/image/java/Dockerfile.jre.zulu))                     | **Debian** 12.5 "bookworm"<br>**Java** 21.0.2   |
| 2023-12-11 | `21.0.1`                                                                                                                                   | **Debian** 12.4 "bookworm"<br>**Java** 21.0.1   |
| 2023-12-11 | `17.0.9-1`, `17`                                                                                                                           | **Debian** 12.4 "bookworm"<br>**Java** 17.0.9   |
| 2023-10-30 | `17.0.9`                                                                                                                                   | **Debian** 12.2 "bookworm"<br>**Java** 17.0.9   |
| 2023-09-28 | `17.0.8.1`                                                                                                                                 | **Debian** 12.1 "bookworm"<br>**Java** 17.0.8.1 |
| 2023-04-25 | `17.0.7` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/3441209dd6b8ef2892a6e264ad58898c805e0114/image/java/Dockerfile.jre.zulu)) | **Debian** 11.6 "bullseye"<br>**Java** 17.0.7   |
