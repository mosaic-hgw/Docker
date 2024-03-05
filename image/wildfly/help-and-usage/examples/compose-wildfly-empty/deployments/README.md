### Sense and Purpose ###
This directory is exclusively for deployments, such as `.ear` or `.war` files. When the WildFly deploys, it creates files with the extension `.isdeploying` and/or `.deployed`, so this directory should have read-write access.<br>
Since the introduction of the ENV variable "`WILDFLY_MARKERFILES=auto`", write access is now only optional. Only when the value is set to `true` does write access become mandatory. Only in this case must the directory owner be adjusted as follows:

```bash
sudo chown 1111:1111 deployments
```

Further details can be found here: https://access.redhat.com/documentation/en-us/jboss_enterprise_application_platform/6/html/administration_and_configuration_guide/Reference_for_Deployment_Scanner_Marker_Files1

### License ###
**License:** AGPLv3, https://www.gnu.org/licenses/agpl-3.0.en.html<br>
**Copyright:** 2014 - ${build.year} University Medicine Greifswald<br>
**Contact:** https://www.ths-greifswald.de/kontakt/