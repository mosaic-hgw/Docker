# Docker

## Splitting Mosaic images into different layers
```
──┬─ base-image (debian:12)
  ├─── db-layer (mysql:8, ...)
  └─┬─ java-layer (zulujre:17, 21, ...)
    ├─┬─ app-layer (wildfly:26, 31, ...)
    │ ├─┬─ db-layer (wildfly-db:31, ..)
    │ │ └─── tool-layer (gpas-db:2024, ..)
    │ └─── tool-layer (gpas:2024, ..)
    └─── test-layer (jmeter:5)
```

## There are certain dependencies:
- all layers need at least the base-image
- the app-layer and the test-layer need at least the java-layer
- the tools-layer needs at least one matching app-layer

## Unfortunately, this layer concept has only one disadvantage.
Each additional layer can only add information to the existing layer, not remove it.
As a result, a layer-based image will always be larger than an image created from just a Dockerfile.
