## General
This layer is mainly needed for our mosaicgreifswald-images WildFly and jMeter, as only these require an installed Java.
Only the slimmer JRE from Azul-Zulu is installed.


## Relevant Entrypoints
| Path                     | ref. ENV-Variable  | Type | Purpose                                                                                                                             |
|--------------------------|--------------------|------|-------------------------------------------------------------------------------------------------------------------------------------|
| /entrypoint-java-cacerts | ENTRY_JAVA_CACERTS | file | The entrypoint can be used to store its own cacerts, e.g. containing public-keys of server certificates for specific web requests.  |
| /entrypoint-java-trusts  | ENTRY_JAVA_TRUSTS  | dir  | Public server certificates placed here are automatically imported into cacerts at startup, allowing the JVM to trust those servers. |

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
  last updated               : 2026-01-21 15:54:53
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 13.3 (trixie)
  zulu-jre                   : 21.0.10
  
# "entrypoints" lists all registered entrypoints.
> docker run --rm mosaicgreifswald/zulujre entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
  ENTRY_USAGE                : /entrypoint-help-and-usage
  ENTRY_JAVA_CACERTS         : /entrypoint-java-cacerts
  ENTRY_JAVA_TRUSTS          : /entrypoint-java-trusts

# get java-version
> docker run --rm -it mosaicgreifswald/zulujre java -version
openjdk version "21.0.10" 2026-01-20 LTS
```
## Usage with untrusted servers
```shell
# with already customized cacerts
> docker run --rm -v /path/to/your/custom-cacerts:/entrypoint-java-cacerts mosaicgreifswald/zulujre bash -c "\
    keytool -printcert -sslserver your-untrustet-server.example.com"

# or with separate public certificates
> docker run --rm -v /path/to/your/public-certificates:/entrypoint-java-trusts mosaicgreifswald/zulujre bash -c "\
    ./import_to_cacerts.sh && \
    keytool -printcert -sslserver your-untrustet-server.example.com"
10:06:27.340 start action jdk-trusts
10:06:27.596 Importing certificate '/entrypoint-java-trusts/your-untrustet-server.example.com.pem' (alias='your-untrustet-server.example.com')
Certificate was added to keystore
10:06:28.050 Importing certificate '/entrypoint-java-trusts/other-untrustet-server.example.com.pem' (alias='other-untrustet-server.example.com')
Certificate was added to keystore
10:06:28.491 Certificate import completed.
```
Note: If the image starts normally, `import_to_cacerts.sh` will run automatically.

## Special usage, multiple java-versions (whoever needs it)
```shell
# build second java-image, based on the image above
> docker build --tag="mosaicgreifswald/zulujre:17-21" --file="Dockerfile.zulujre" --build-arg JAVA_VERSION=17 --build-arg TAG=mosaicgreifswald/zulujre:latest .

# show all versions (last installed java is per default selected as "current") 
> docker run --rm mosaicgreifswald/zulujre:17-21 versions
  last updated               : 2026-01-26 14:24:54
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 13.3 (trixie)
  zulu-jre                   : 21.0.10 
  zulu-jre                   : 17.0.18 (current)

> docker run --rm mosaicgreifswald/zulujre:17-21 java -version
openjdk version "17.0.18" 2026-01-20 LTS

# switch java-version per environment-variable
> docker run --rm -e JAVA_VERSION=21 mosaicgreifswald/zulujre:17-21 versions
  last updated               : 2026-01-26 14:24:54
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 13.3 (trixie)
  zulu-jre                   : 21.0.10 (current)
  zulu-jre                   : 17.0.18

> docker run --rm -e JAVA_VERSION=21 mosaicgreifswald/zulujre:17-21 java -version
openjdk version "21.0.10" 2026-01-20 LTS

# switch java-version in running container
> docker run --rm -it mosaicgreifswald/zulujre:17-21 bash
> java -version
openjdk version "17.0.18" 2026-01-20 LTS

> JAVA_VERSION=21 java -version
openjdk version "21.0.10" 2026-01-20 LTS
```

## Current Software-Versions on this Image
| Date                       | Tags                                                                                                                                                                                                                                                                                                                                                                                  | Changes                                                                                                                         |
|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| 2026-02-04<br><br><br><br> | [21.0.10](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.10), [21](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21), [latest](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=latest)<br>([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/ae5fe9e3cbc931311c7af8e82d54c1a2c67c0d7e/image/zulujre/Dockerfile.zulujre))<br><br><br> | **Debian** 13.3 "trixie"<br>**Java** 21.0.10<br>**fixed** signal forwarding<br>**added** new handling with public certificates  |
| 2026-01-26<br><br>         | 21.0.10<br><br>                                                                                                                                                                                                                                                                                                                                                                       | **Debian** 13.3 "trixie"<br>**Java** 21.0.10                                                                                    |
| 2025-10-29<br><br>         | [21.0.9](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.9)<br><br>                                                                                                                                                                                                                                                                                                  | **Debian** 13.1 "trixie"<br>**Java** 21.0.9                                                                                     |
| 2025-07-22<br><br>         | [21.0.8](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.8)<br><br>                                                                                                                                                                                                                                                                                                  | **Debian** 12.11 "bookworm"<br>**Java** 21.0.8                                                                                  |
| 2025-04-25<br><br>         | [21.0.7](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.7)<br>([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/5a4e7537aa5a67634c13662101f5f6ca44ac30d2/image/zulujre/Dockerfile.zulujre))<br>                                                                                                                                                               | **Debian** 12.10 "bookworm"<br>**Java** 21.0.7                                                                                  |
| 2025-01-24<br><br>         | [21.0.6](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.6) <br><br>                                                                                                                                                                                                                                                                                                 | **Debian** 12.9 "bookworm"<br>**Java** 21.0.6                                                                                   |
| 2025-01-13<br><br>         | [21.0.5](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.5)<br><br>                                                                                                                                                                                                                                                                                                  | **Debian** 12.8 "bookworm"<br>**Java** 21.0.5                                                                                   |
| 2024-09-09<br><br>         | [21.0.4](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.4)<br>([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/081d44affc8e3048c38689d3e2780ad777b915f5/image/zulujre/Dockerfile.zulujre))<br>                                                                                                                                                               | **Debian** 12.7 "bookworm"<br>**Java** 21.0.4                                                                                   |
| 2024-03-05<br><br>         | [21.0.2](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.2)<br><br>                                                                                                                                                                                                                                                                                                  | **Debian** 12.5 "bookworm"<br>**Java** 21.0.2                                                                                   |
| 2023-12-11                 | [21.0.1](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=21.0.1)                                                                                                                                                                                                                                                                                                          | **Java** 21.0.1                                                                                                                 |
| 2023-12-11                 | [17.0.9-1](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=17.0.9-1), [17](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=17)                                                                                                                                                                                                                                | **Debian** 12.4 "bookworm"                                                                                                      |
| 2023-10-30<br><br>         | [17.0.9](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=17.0.9)<br><br>                                                                                                                                                                                                                                                                                                  | **Debian** 12.2 "bookworm"<br>**Java** 17.0.9                                                                                   |
| 2023-09-28<br><br>         | [17.0.8.1](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=17.0.8.1)<br><br>                                                                                                                                                                                                                                                                                              | **Debian** 12.1 "bookworm"<br>**Java** 17.0.8.1                                                                                 |
| 2023-04-25<br><br>         | [17.0.7](https://hub.docker.com/r/mosaicgreifswald/zulujre/tags?name=17.0.7)<br>([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/3441209dd6b8ef2892a6e264ad58898c805e0114/image/java/Dockerfile.jre.zulu))<br>                                                                                                                                                                 | **Debian** 11.6 "bullseye"<br>**Java** 17.0.7                                                                                   |
