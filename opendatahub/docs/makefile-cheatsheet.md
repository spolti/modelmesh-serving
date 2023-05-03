# Makefile Cheatsheet

**Base variables**

```
export OCP_TOKEN=sha256~XXXX; export OCP_ADDRESS=api.XXXX.com:6443
```
## Target: deploy-mm-for-odh

This is for deploying modelmesh using odh manifests. By default, it is using kfctl cli but if you set `OP_KFDEF` to true, it will deploy opendatahub operator and the operator will reconcile the kfdef file.

**Using custom odh manifests**

For example, if you want to use the manifests under this repo: `https://api.github.com/repos/TEST/modelmesh-serving/tarball/custom_odh`
You can set these variable with the target:
```
USER=TEST BRANCH=custom_odh CONTROLLERNAMESPACE=opendatahub make deploy-mm-for-odh
```
*(Note)* Default value for `USER`, `BRANCH`, `CONTROLLERNAMESPACE` is `opendatahub-io`, `main`, `opendatahub`.

**Deploy fast/stable images**

This help you to deploy the latest images for modelmesh.

```
TAG=fast CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving make deploy-mm-for-odh

or

TAG=stable CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving make deploy-mm-for-odh
```

You can set a custom image only for specific component. The others will use fast image. (modelmesh/modelmesh-controller/modelmesh-runtime-adapter/rest-proxy/ odh-model-controller)

(ex) modelmesh
```
TAG=fast CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving CUSTOM_IMG=modelmesh=quay.io/opendatahub/modelmesh:v0.9.3-auth make deploy-mm-for-odh
```

## Target: deploy-fvt-for-odh

This target help deploying fvt related objects such as minio, pvc and preparing fvt test like downloading related images priorly.

**Default**
It will deploy the fvt objects in the `NAMESPACE`.

```
NAMESPACE=modelmesh-serving make deploy-fvt-for-odh
```

**Download fast/stable images**

```
TAG=fast NAMESPACE=modelmesh-serving make deploy-fvt-for-odh

or

TAG=stable NAMESPACE=modelmesh-serving  make deploy-fvt-for-odh
```

You can set a custom image only for specific component. The others will use fast image. (modelmesh/modelmesh-controller/modelmesh-runtime-adapter/rest-proxy/ odh-model-controller)

(ex) modelmesh + other fast images
```
TAG=fast NAMESPACE=modelmesh-serving CUSTOM_IMG=modelmesh=quay.io/opendatahub/modelmesh:v0.9.3-auth make deploy-fvt-for-odh
```

## Target: e2e-test-for-odh (E2E Test)

This is an all-in-one target for deploying modelmesh, minio, and creating FVT objects. When FVT test preparation is done, it will trigger to start the FVT test.

**Default**

```
CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving NAMESPACESCOPEMODE=true make e2e-test-for-odh
```

**fast/stable images**

```
TAG=fast CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving NAMESPACESCOPEMODE=true make e2e-test-for-odh

or

TAG=stable CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving NAMESPACESCOPEMODE=true make e2e-test-for-odh
```

**Set custom image**

```
CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving CUSTOM_IMG=modelmesh=quay.io/opendatahub/modelmesh:v0.9.3-auth NAMESPACESCOPEMODE=true make e2e-test-for-odh
```

**Set custom repo uri**

```
USER=Jooho BRANCH=restructed_odh_manifests CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving NAMESPACESCOPEMODE=true make e2e-test-for-odh
```

**Use odh operator to deploy modelmesh**
~~~
OP_KFDEF=true CONTROLLERNAMESPACE=opendatahub NAMESPACE=modelmesh-serving NAMESPACESCOPEMODE=true make e2e-test-for-odh
~~~

## cleanup-for-odh

The following environmental variables can be mixed up.

**Delete modelmesh-controller deployed by kustomize manifests**

```
C_MM_CTRL_KUSTOMIZE=true make cleanup-for-odh
```

**Delete modelmesh-controller deployed by kfctl manifests**

```
C_MM_CTRL_KFCTL=true make cleanup-for-odh
```

**Delete modelmesh-controller deployed by kfdef with odh operator**

```
C_MM_CTRL_OPS=true make cleanup-for-odh
```

**Delete fvt related objects(modelmesh ns)**

```
C_MM_TEST=true make cleanup-for-odh
```

**Delete all objects related for fvt test (opendatahub/modelmesh ns, nfsprovisioner)**

```
C_FULL=true make cleanup-for-odh
```
