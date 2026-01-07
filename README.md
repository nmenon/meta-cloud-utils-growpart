# meta-cloud-utils-growpart
Simple yocto layer to bring in growpart from https://github.com/canonical/cloud-utils/blob/main/bin/growpart

# kas fragment to add this to builds

```yaml
header:
  version: 17

repos:
  meta-cloud-utils-growpart:
    url: https://github.com/nmenon/meta-cloud-utils-growpart.git
    branch: main
    layers:
      meta-cloud-utils-growpart:

local_conf_header:
  growpart: |
    IMAGE_INSTALL:append = " cloud-utils-growpart"
```

# Configure bitbake-setup to pick this up

TBD: TEST THIS

Add the following to the "sources" section:

```json
        "meta-cloud-utils-growpart": {
            "git-remote": {
                "remotes": {
                    "origin": {
                        "uri": "https://github.com/nmenon/meta-cloud-utils-growpart.git"
                    }
                },
                "branch": "main",
                "rev": "main"
            }
        },
```

```json
        "configurations": [
        {
            "bb-layers": ["meta-cloud-utils-growpart"]
```


# Add with bitbake-layers

TBD: TEST THIS

```shell

git clone -b main --depth 1  https://github.com/nmenon/meta-cloud-utils-growpart.git

...

. oe-init-build-env build

....

bitbake-layers add-layer meta-cloud-utils-growpart

```
