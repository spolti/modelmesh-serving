#!/bin/bash

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/utils.sh"

# For ROSA Platform
default_sc=gp3

if [[ -n $C_NFS ]] || [[ -n $C_FULL ]]; then
  oc delete nfsprovisioner --all --force -n nfs-provisioner
  oc delete ns nfs-provisioner
  oc delete storageclass nfs 
  oc patch storageclass ${default_sc} -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
fi

if [[ -n $C_MM_TEST ]] || [[ -n $C_FULL ]]; then
  kustomize build opendatahub/scripts/manifests/runtimes/ |oc delete -f -
  oc delete pvc,pod --all --force -n modelmesh-serving
  oc delete ns modelmesh-serving
fi

if [[ -n $C_MM_CTRL_KUSTOMIZE ]] || [[ -n $C_FULL ]]; then
  kustomize build $ODH_MANIFESTS_DIR/model-mesh/base  | oc delete -f -
fi

if [[ -n $C_MM_CTRL_KFCTL ]] || [[ -n $C_FULL ]]; then
  kfctl build -V -f $OPENDATAHUB_DIR/kfdef-local.yaml -d | oc delete -f -
  rm -rf $OPENDATAHUB_DIR/.cache $OPENDATAHUB_DIR/kustomize
  oc delete ns opendatahub
fi

if [[ -n $C_MM_CTRL_OPS ]] || [[ -n $C_FULL ]]; then
  oc delete kfdef opendatahub -n opendatahub
  oc delete ns opendatahub
  oc delete -f opendatahub/scripts/manifests/subs_odh_operator.yaml
fi
