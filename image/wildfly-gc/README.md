## General
This image is a direct extension of our image [mosaicgreifswald/wildfly](https://hub.docker.com/r/mosaicgreifswald/wildfly).\
You can use this image wherever you would use mosaicgreifswald/wildfly.\
All functions, environment-variables and entry-points have been retained.\
The only modifications are the installation of Google Chrome and ChromeDriver, which enables a clean generation of PDF files.

## Usage
`versions` shows all installed tools and components, with their versions.
```shell
> docker run --rm mosaicgreifswald/wildfly-gc versions
  last updated               : 2026-07-20 10:20:09
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 13.6 (trixie)
  zulu-jre                   : 25.0.3 
  WildFly                    : 40.0.1.Final
  MySQL-Connector            : 9.7.0
  MariaDB-Connector          : 3.5.9
  PostgreSQL-Connector       : 42.7.13
  EclipseLink                : 4.0.9
  Chrome-Headless-Shell      : 151.0.7922.34
  Chrome-Driver              : 151.0.7922.34
```
