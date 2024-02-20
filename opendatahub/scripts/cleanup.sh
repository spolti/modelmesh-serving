#!/bin/bash

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/utils.sh"

# For ROSA Platform
default_sc=gp3

ctrlnamespace=opendatahub
namespace=modelmesh-serving

if [[ -n $CONTROLLERNAMESPACE ]];then
  ctrlnamespace=$CONTROLLERNAMESPACE
fi

if [[ -n $NAMESPACE ]];then
  namespace=$NAMESPACE
fi

if [[ -n $C_NFS ]] || [[ -n $C_FULL ]]; then
  oc delete nfsprovisioner --all --force -n nfs-provisioner
  oc delete ns nfs-provisioner
  oc delete storageclass nfs 
  oc patch storageclass ${default_sc} -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  oc delete ns model-serving
fi

if [[ -n $C_MM_TEST ]] || [[ -n $C_FULL ]]; then
  kustomize build  "${MANIFESTS_DIR}"/runtimes/ |oc delete -f -
  oc delete pvc,pod --all --force -n "${namespace}"
  oc delete ns "${namespace}"
fi

if [[ -n $C_MM_CTRL_KUSTOMIZE ]] || [[ -n $C_FULL ]]; then
  kustomize build $MM_MANIFESTS_DIR/overlays/odh  | oc delete -f -
fi

if [[ -n $C_MM_CTRL_KFCTL ]] || [[ -n $C_FULL ]]; then
  oc project $ctrlnamespace
  rm -rf $OPENDATAHUB_DIR/.cache $OPENDATAHUB_DIR/kustomize
  rm -rf /tmp/modelmesh-e2e/.cache /tmp/modelmesh-e2e/kustomize
  rm -rf /tmp/.cache /tmp/kustomize
  rm -rf /tmp/odh-manifests.gzip 
  oc delete ns $ctrlnamespace
fi

if [[ -n $C_MM_CTRL_OPS ]] || [[ -n $C_FULL ]]; then
  oc delete ns ${ctrlnamespace}
  oc delete -f ${MANIFESTS_DIR}/subs_odh_operator.yaml
  if [[ $(oc get csv -n openshift-operators |grep opendatahub|awk '{print $1}'|wc -l) == 1 ]];then
    oc delete csv $(oc get csv |grep opendatahub|awk '{print $1}') -n openshift-operators
  fi
fi
