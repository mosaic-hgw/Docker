## General
This image is a direct extension of our image [mosaicgreifswald/wildfly](https://hub.docker.com/r/mosaicgreifswald/wildfly).\
You can use this image wherever you would use mosaicgreifswald/wildfly.\
All functions, environment-variables and entry-points have been retained.\
The only modifications are the installation of Google Chrome and ChromeDriver, which enables a clean generation of PDF files.

## Usage
`versions` shows all installed tools and components, with their versions.
```shell
> docker run --rm mosaicgreifswald/wildfly-gc versions
  last updated               : 2026-01-21 16:03:42
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 13.3 (trixie)
  zulu-jre                   : 21.0.10 
  WildFly                    : 38.0.0.Final
  MySQL-Connector            : 9.5.0
  MariaDB-Connector          : 3.5.7
  PostgreSQL-Connector       : 42.7.9
  EclipseLink                : 4.0.9
  Chrome-Headless-Shell      : 145.0.7619.0
  Chrome-Driver              : 145.0.7619.0
```
