## General
This image is a direct extension of our image [mosaicgreifswald/wildfly](https://hub.docker.com/r/mosaicgreifswald/wildfly).\
You can use this image wherever you would use mosaicgreifswald/wildfly.\
All functions, environment-variables and entry-points have been retained.\
The only modifications are the installation of Google Chrome and ChromeDriver, which enables a clean generation of PDF files.

## Usage
`versions` shows all installed tools and components, with their versions.
```shell
> docker run --rm mosaicgreifswald/wildfly-gc versions
  last updated               : 2025-07-22 10:39:34
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 12.11
  zulu-jre                   : 21.0.8
  WildFly                    : 36.0.1.Final
  MySQL-Connector            : 9.3.0
  MariaDB-Connector          : 3.5.4
  PostgreSQL-Connector       : 42.7.7
  EclipseLink                : 4.0.7
  Chrome-Headless-Shell      : 135.0.7049.114
  Chrome-Driver              : 135.0.7049.114
```
