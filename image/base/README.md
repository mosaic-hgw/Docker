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
  --add-run-script="10:service:/opt/database/run.sh:/opt/database/started.sh"
```
**Explanation**<br>
- `--os-updated` is an attribute that should be specified if OS updates have been applied in addition to the actual layer.
- The parameter `--add-version="NAME:VERSION"` is used to announce a new tool and how its version can be queried. It is also possible to simply pass the version number directly or as a variable if it should not change in this image.
- The parameter `--add-entrypoint="NAME:PATH"` specifies a new entry point in the image that can be referenced at start-up via `--volume "*:*"` to exchange data with the host system.
- `--add-healthcheck-script=SCRIPT` is used to announce a bash script to be used for health checking the layer. The script to be executed may generate output, but must be terminated with exit code 1 if the corresponding layer is no longer functioning properly. Exit code 0 means "All is well".
- With the last parameter `--add-run-script="ORDER:TYPE:RUN:STARTED"` at least 3, but maximum 4 values must be passed.
  - ORDER' determines the start order, whereby a larger value means a later start. As a rough guide, databases should start with `10`, app servers with `20` and tests from `30`.
  - With `TYPE` the start type of the layer is defined, which can contain the characteristics "*action*" and "*service*".
  - With "*action*" the `RUN` script is started and no further `RUN` scripts are executed until this one is finished.
  - "*service*" starts the `RUN` script in the background. If the optional `STARTED` script is specified, this is used to check and wait when the services has started up correctly and then start the other `RUN` scripts.


## Relevant ENV variables
| Category   | Variable     | Available values or scheme            | Default       |
|------------|--------------|---------------------------------------|---------------|
| Optimizing | TZ           | \<STRING\>                            | Europe/Berlin |
| Optimizing | MOS_RUN_MODE | action / service / cascade / external | service       |

The `MOS_RUN_MODE`, in contrast to the `TYPE` in the `--add-run-script`, does not affect the individual layer, but the behaviour in the whole image:
- `action` will wait until all action-run-scripts are successful finished and then also stop the service-run-scripts
- `service` starts all run-scripts and tries to restart services if they quit
- `cascade` like `service` but stops them again as soon as a service ends
- `external` like `service` but does not restart the services

## Relevant Entrypoints
| Path             | ref. ENV-Variable  | Type   | Purpose                                                                  |
|------------------|--------------------|--------|--------------------------------------------------------------------------|
| /entrypoint-logs | ENTRY_LOGS         | folder | All further layers can store their own log files here in subdirectories. |

## Usage
```shell
# build base-image
> cd mosaic-hgw/Docker/image/base
> docker build --tag="mosaicgreifswald/base:latest" --file="Dockerfile.base.deb" .

# "versions" shows all installed tools and components, with their versions.
> docker run --rm mosaicgreifswald/debian:latest versions
  last updated               : 2023-04-14 10:30:32
  Distribution               : Debian GNU/Linux 11.6
  
# "entrypoints" lists all registered entrypoints.
> docker run --rm mosaicgreifswald/debian:latest entrypoints
  ENTRY_LOGS                 : /entrypoint-logs
```
