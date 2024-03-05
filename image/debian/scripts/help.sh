#!/bin/bash

# get colors
source $(dirname $(realpath $0))/colors.sh

HEADER="${NC}${UNDERLINE}${WHITE}"
TEXT="${NC}"
CODE="${YELLOW}"

echo -e "
 ${HEADER}Usage:${NC}
 You can also use podman instead of docker.
 > ${CODE}docker run --rm ${CYAN}<IMAGE> ${BLUE}<COMMAND>${TEXT}

 ${HEADER}available mosaicgreifswald-IMAGEs:${NC}
 ${CYAN}mosaicgreifswald/debian${TEXT}
   This is the base image for all MOSAIC images. Some scripts are predefined
   here that are useful for health checks, start order and version information.
   Each new layer should "register" for this so that the new attributes are
   known and can be used.
   -> https://hub.docker.com/r/mosaicgreifswald/debian/
 ${CYAN}mosaicgreifswald/zulujre${TEXT}
   This layer is mainly needed for our MOSIAC-Images WildFly and jMeter, as
   only these require an installed Java. Only the slimmer JRE from Azul-Zulu
   is installed.
   -> https://hub.docker.com/r/mosaicgreifswald/zulujre/
 ${CYAN}mosaicgreifswald/wildfly${TEXT}
   The WildFly image has the most use cases for us. It can be used directly
   with Docker Compose, or serves as the basis for other images itself. This
   image can be started directly without having to build your own image
   beforehand, as all adjustments are made in advance using jboss-cli files.
   Of course, you can still build your own image.
   -> https://hub.docker.com/r/mosaicgreifswald/wildfly/
 ${CYAN}mosaicgreifswald/jmeter${TEXT}
   This layer is only used to automatically execute tests without a GUI. The
   layer can be used to create your own jMeter image, which is integrated via
   Docker-Compose or a complete test image, which is based on a wildfly image.
   -> https://hub.docker.com/r/mosaicgreifswald/jmeter/
 ${TEXT}
 You can find more images on our Docker Hub page:
   -> https://hub.docker.com/u/mosaicgreifswald

 ${HEADER}available COMMANDs:${NC}${TEXT}
 If no command is specified, the standard function is executed by the image.
 ${BLUE}versions${TEXT}
   Displays all versions of the relevant installed software. This is also
   displayed when the image is started with the standard-command.
 ${BLUE}entrypoints${TEXT}
   Display all registered entry-points with corresponding
   environment-variables. The environment-variables can be used inside the
   image to easier reference the entry-points.
 ${BLUE}env${TEXT}
   This is a standard Docker command to display all current defined
   environment-variables.
 ${BLUE}envs${TEXT}
   This is an extended function of ${BLUE}env${TEXT}, to display all available
   environment-variables, with their current and default values. In addition,
   all obsolete and next ignored variables are shown and, if available, which
   variable they have been replaced by. By default, the value-column is limited
   to 40 characters. With the parameter ${BLUE}--dont-cut-values${TEXT}, values are displayed
   in full length.
 ${BLUE}help${TEXT}
   Shows this help. This help has been implemented in all
   mosaicgreifswald-images since 2024.

 ${HEADER}Examples:${NC}
 > ${CODE}docker run --rm ${CYAN}mosaicgreifswald/zulujre ${BLUE}envs${DARK_GRAY}


 > ${CODE}docker run --rm ${CYAN}mosaicgreifswald/wildfly:26 ${BLUE}versions${DARK_GRAY}
 last updated               : 2023-12-19 14:56:32
 Distribution               : Debian GNU/Linux 12.4
 zulu-jre                   : 17.0.9
 WildFly                    : 26.1.3.Final
 MySQL-Connector            : 8.0.33
 EclipseLink                : 2.7.14
 KeyCloak-Client            : 19.0.2

 ${HEADER}Additional help and examples:${NC}${TEXT}

 You can copy additional files from this image. These can help you to start
 your own project more quickly. Included are various README.md and lots of
 examples. There are several ways to view these files:

 ${HEADER}Explore the files directly in the running container:${NC}
 > ${CODE}docker run --rm -it ${CYAN}<IMAGE>${CODE} bash -c \"cd \\\$ENTRY_USAGE ; ls -la ; bash\"

 ${HEADER}Copy files to your host system${NC}
 > ${CODE}docker run --rm -v \"your/path\":\"\$(pwd)\" ${CYAN}<IMAGE>${CODE} bash -c \"cp -R \$ENTRY_USAGE\* \$(pwd)/\"

 ${TEXT}License-information
 Copyright (C) 2009 - 2024 Institute for Community Medicine
 University Medicine of Greifswald - mosaic-project@uni-greifswald.de
 GNU Affero General Public License version 3
"