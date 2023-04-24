# Opendatahub Scripts

This folder consists of two main parts: scripts and manifests. 
manifests are the part that deploys the components required for fvt (functional validation test) of the modelmesh deployed through opendatahub manifests, and the template folder exists so that these manifests can be recreated at any time. And finally, there are manifests that are copied from upstream to create ServingRuntime for FVT.


## Manifests
- fvt
  - deploy components for fvt tests.
- fvt_templates 
  - fvt templates manifest to make fvt folder based on the latest upstream version.
- runtimes
  -  deploy ServingRuntimes
- subs_odh_operator.yaml
  - deploy the latest opendatahub operator.


## Scripts

Scripts in this folder are also created to support fvt tests. 

- [deploy_nfs_provisioner.sh] (./deploy_nfs_provisioner)
  - script to install nfs provisioner to enable PVC testing on openshift dedicated.

- [download_images_on_nodes.sh](./download_images_on_nodes.sh) 
  - This script uses daemonset to ensure that the required images are downloaded to all nodes before the FVT starts. This prevents the FVT test from failing due to a long time it takes to get the images.

- [deploy_fvt.sh ](./deploy_fvt.sh)
  - This script contains deploy_nfs_provisioner.sh and download_images_on_nodes.sh and is the main file that is called to prepare the FVT test.
  