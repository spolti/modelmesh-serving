#!/bin/bash

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/utils.sh"

set -Eeuo pipefail

namespace=modelmesh-serving
ctrlnamespace=${namespace}
tag=none
force=false

function showHelp() {
  echo "usage: $0 [flags]"
  echo
  echo "Flags:"
  echo "  -n, --namespace                (optional) Kubernetes namespace to deploy FVT test components to(default modelmesh-serving)."
  echo "  -c, --ctrl-namespace           (optional) Kubernetes namespace to deploy modelmesh controller to(default modelmesh-serving)."
  echo "  -t, --tag                      (optional) Set tag fast,stable to change images quickly(default none)."
  echo "  -f, --force                    (optional) Copy fvt manifests from opendatahub/odh-manifest(default false)."
  echo
  echo "Installs components related to fvt test"
}


while (($# > 0)); do
  case "$1" in
  -h | --h | --he | --hel | --help)
    showHelp
    exit 2
    ;;
  -n | --n | -namespace | --namespace)
    shift
    namespace="$1"
    ;;
  -c | --c | -ctrl-namespace | --ctrl-namespace)
    shift
    ctrlnamespace="$1"
    ;;    
  -t | --t | -tag | --tag)
    shift
    tag="$1"
    ;;
  -f | --f | -force | --force)
    force=true
    ;;     
  -*)
    die "Unknown option: '${1}'"
    ;;       
  esac
  shift
done    

# Copy fvt tests manifests into manifest folder
if [[ ! -d $MANIFESTS_DIR/fvt ]] || [[ ${force} == "true" ]];then
  cp -R $MANIFESTS_DIR/fvt_templates $MANIFESTS_DIR/fvt
  cp -R $ODH_MANIFESTS_DIR/model-mesh/odh-modelmesh-controller/dependencies/* $MANIFESTS_DIR/fvt/.
  # Convert imaes to use quay.io image (avoid dockerhub pull limit)
  sed 's+kserve/modelmesh-minio-dev-examples:latest+quay.io/jooholee/minio-examples:latest+g' -i opendatahub/scripts/manifests/fvt/fvt.yaml
  sed 's+kserve/modelmesh-minio-examples:latest+quay.io/jooholee/minio-examples:latest+g' -i opendatahub/scripts/manifests/fvt/fvt.yaml
  sed 's+ubuntu+quay.io/fedora/fedora:38+g' -i opendatahub/scripts/manifests/fvt/fvt.yaml
fi

# Copy opendatahub params.env into manifests folder to get the right images
if [[ ! -f $MANIFESTS_DIR/params.env ]] || [[ ${force} == "true" ]];then
  cp -R $ODH_MANIFESTS_DIR/model-mesh/base/params.env $MANIFESTS_DIR/.
fi

# The upstream use ClusterServingRuntime so this replace ClusterServingRuntime to ServingRuntime.
if [[ ! -d $MANIFESTS_DIR/runtimes ]] || [[ ${force} == "true" ]];then
  cp -R $ODH_MANIFESTS_DIR/model-mesh/odh-modelmesh-controller/runtimes $MANIFESTS_DIR/.
  # Remove not supported runtimes
  pushd $MANIFESTS_DIR/runtimes

  kustomize edit remove transformer ../default/metadataLabelTransformer.yaml
  sed 's+ClusterServingRuntime+ServingRuntime+g' -i ./*
  
  openvino_img=$(cat $MANIFESTS_DIR/params.env |grep odh-openvino|cut -d= -f2)
  sed "s+\$(odh-openvino)+${openvino_img}+g" -i ./*

  popd
fi

# Create a namespace
oc project $namespace|| oc new-project $namespace

# Download images on each node
$SCRIPT_DIR/download_images_on_nodes.sh $tag

# Deploy NFS Provisioner
# $SCRIPT_DIR/deploy_nfs_provisioner.sh $namespace
oc get ns nfs-provisioner|| $SCRIPT_DIR/deploy_nfs_provisioner.sh nfs-provisioner

# Deploy fvt
pushd $MANIFESTS_DIR/fvt
kustomize edit set namespace "$namespace"
popd

kustomize build $MANIFESTS_DIR/fvt/ |oc apply -f -

info "Waiting for dependent pods to be up ..."
wait_for_pods_ready "-l app=minio"

# pvc initialize for fvt test.
info "Waiting for FVT PVC storage to be initialized ..."
kubectl wait --for=condition=complete --timeout=180s job/pvc-init

# Setup the namespace for modelmesh test
oc label namespace ${namespace} modelmesh-enabled=true --overwrite=true

# Deploy runtime
kustomize build $MANIFESTS_DIR/runtimes/ |oc apply -f -

# Create a rolebinding for sa 'modelmesh-seving-sa' which is managed by odh-model-controller with inferenceservice
oc get sa modelmesh-serving-sa -n  ${namespace}  ||oc create sa modelmesh-serving-sa -n  ${namespace} 
oc get clusterrolebinding ${namespace}-modelmesh-serving-sa-auth-delegator || sed "s/%namespace%/${namespace}/g" $MANIFESTS_DIR/modelmesh-serving-sa-rolebinding.yaml | oc create -f -

# Create a SA "prometheus-ns-access" becuase odh-model-controller create rolebinding "prometheus-ns-access" with the SA where namespaces have modelmesh-enabled=true label
oc get sa prometheus-ns-access -n  ${namespace}  ||oc create sa prometheus-ns-access -n  ${namespace}  

