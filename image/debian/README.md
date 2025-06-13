## General
This is the base image for all MOSAIC images.
Some scripts are predefined here that are useful for health checks, start order and version information.
Each new layer should "register" for this so that the new attributes are known and can be used.

Registration is explained using the example of a simple database:
```shell
register \
  --os-updated \
  --add-version="Database-Server:\$(/opt/database/bin/daemon -v)" \
  --add-entrypoint="ENTRY_DB_CONFIG:/opt/database/config" \
  --add-entrypoint="ENTRY_DB_DATADIR:/opt/database/data" \
  --add-healthcheck-script="/opt/database/healthcheck.sh" \
  --add-process="database:10:service:/opt/database/run.sh:/opt/database/started.sh"
```
**Explanation**<br>
- `--os-updated` is an attribute that should be specified if OS updates have been applied in addition to the actual layer.
- The parameter `--add-version="NAME:VERSION"` is used to announce a new tool and how its version can be queried. It is also possible to simply pass the version number directly or as a variable if it should not change in this image.
- The parameter `--add-entrypoint="NAME:PATH"` specifies a new entry point in the image that can be referenced at start-up via `--volume "*:*"` to exchange data with the host system.
- `--add-healthcheck-script=SCRIPT` is used to announce a bash script to be used for health checking the layer. The script to be executed may generate output, but must be terminated with exit code 1 if the corresponding layer is no longer functioning properly. Exit code 0 means "All is well".
- The value of parameter `--add-process` is needed to register a new process and must have the format `NAME:ORDER:TYPE:RUN:STARTED`, whereby the last segment is optional.
  - The value `NAME` is used to identify the process. The name can be used to filter processes and start or stop them individually.
  - `ORDER` determines the start order, whereby a larger value means a later start. As a rough guide, databases should start with `10`, app servers with `20` and tests from `30`.
  - With `TYPE` the start type of the layer is defined, which can contain the characteristics `action` and `service`.
  - If `TYPE` has value `action` the `RUN` script is started and no further `RUN` scripts are executed until this one is finished.
  - With `service` as `TYPE` value starts the `RUN` script in the background. If the optional `STARTED` script is specified, this is used to check and wait when the services has started up correctly and then start the other `RUN` scripts.


## Relevant ENV variables
| Category   | Variable              | Available values or scheme            | Default       |
|------------|-----------------------|---------------------------------------|---------------|
| Optimizing | TZ                    | \<STRING\>                            | Europe/Berlin |
| Optimizing | MOS_RUN_MODE          | action / service / cascade / external | service       |
| Testing    | MOS_SHUTDOWN_DELAY    | \<SECONDS\>                           |               |
| Processing | MOS_INCLUDE_PROCESSES | \<REGEX\>                             |               |
| Processing | MOS_EXCLUDE_PROCESSES | \<REGEX\>                             |               |

The `MOS_RUN_MODE`, in contrast to the `TYPE` in the `--add-run-script`, does not affect the individual layer, but the behaviour in the whole image:
- `action` will wait until all action-run-scripts are successful finished and then also stop the service-run-scripts
- `service` starts all run-scripts and tries to restart services if they quit
- `cascade` like `service` but also stops all other services as soon as a service ends
- `external` like `service` but does not restart an ended service nor does it stop the others

The `MOS_SHUTDOWN_DELAY` variable defines the duration, in seconds, after which all services should be gracefully terminated.
The `MOS_INCLUDE_PROCESSES` variable can contain a regular expression that includes one or more processes to be started by name.
The variable `MOS_EXCLUDE_PROCESSES` does exactly the opposite. It ignores processes that match the regular expression.

## Relevant Entrypoints
| Path                       | ref. ENV-Variable | Type   | Purpose                                                                          |
|----------------------------|-------------------|--------|----------------------------------------------------------------------------------|
| /entrypoint-logs           | ENTRY_LOGS        | folder | All further layers can store their own log files here in subdirectories.         |
| /entrypoint-help-and-usage | ENTRY_USAGE       | folder | Here you will find README-files for each docker-image-layer, including examples. |

## Usage
```shell
# build base-image
> cd mosaic-hgw/Docker/images/debian
> docker build --tag="mosaicgreifswald/debian:latest" --file="Dockerfile.debian" .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/debian:latest versions
  last updated               : 2025-04-25 11:16:21
  Architecture               : x86_64
  Distribution               : Debian GNU/Linux 12.10
  
# "entrypoints" lists all registered entrypoints.
> docker run --rm mosaicgreifswald/debian:latest entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
```

## Current Software-Versions on this Image
| Date               | Tags                                                                                                                                                              | Changes                                                                    |
|--------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------|
| 2025-06-13         | `12.11`, `12`, `latest`                                                                                                                           | **Debian** 12.11 "bookworm"                                                |
| 2025-04-25<br><br> | `12.10` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/a370600c41ce8b19f2b0ed55be81a6aa3000cdf2/image/debian/Dockerfile.debian))<br><br> | **Debian** 12.10 "bookworm"<br>improved process control                    |
| 2025-03-05<br><br> | `12.9` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/d5ee0894caa3033284d3caaf4d6373a8810cfb96/image/debian/Dockerfile.debian))<br><br>                  | **Debian** 12.9 "bookworm"<br>added support for docker-parameter --user/-u |
| 2025-01-13         | `12.8`                                                                                                                                                            | **Debian** 12.8 "bookworm"                                                 |
| 2024-09-09         | `12.7` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/75e66a88eb961ca664eb754cb9c0c20ee9197c3d/image/debian/Dockerfile.debian))                          | **Debian** 12.7 "bookworm"                                                 |
| 2024-07-22         | `12.6` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/d60333bba59fc8c1c6dbbcb3cad5b6180e3e5105/image/debian/Dockerfile.debian))                          | **Debian** 12.6 "bookworm"                                                 |
| 2024-05-13         | `12.5`                                                                                                                                                            | **Debian** 12.5 "bookworm"                                                 |
| 2023-12-11         | `12.4` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/5981092ec91894fdcdc6961a79b3b45b2e141b1c/image/base/Dockerfile.base.deb))                          | **Debian** 12.4 "bookworm"                                                 |
| 2023-10-30         | `12.2`                                                                                                                                                            | **Debian** 12.2 "bookworm"                                                 |
| 2023-09-28         | `12.1`                                                                                                                                                            | **Debian** 12.1 "bookworm"                                                 |
| 2023-07-13         | `12.0`                                                                                                                                                            | **Debian** 12.0 "bookworm"                                                 |
| 2023-04-25         | `11.7`, `11` ([Dockerfile](https://github.com/mosaic-hgw/Docker/blob/2af37800a94baed6dff61d6533c499dfb42cd545/image/base/Dockerfile.base.deb))                    | **Debian** 11.7 "bullseye"                                                 |
