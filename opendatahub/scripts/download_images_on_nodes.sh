#!/bin/bash

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/utils.sh"

tag=$1

export TRITON_SERVER=nvcr.io/nvidia/tritonserver:21.06.1-py3 
export ML_SERVER=seldonio/mlserver:0.5.2 
export TORCHSERVE=pytorch/torchserve:0.6.0-cpu
export OPENVINO=$(cat $MANIFESTS_DIR/params.env |grep odh-openvino|cut -d= -f2)
export MODELMESH=$(cat $MANIFESTS_DIR/params.env |grep odh-modelmesh=|cut -d= -f2)
export MODELMESH_RUNTIME=$(cat $MANIFESTS_DIR/params.env |grep odh-modelmesh-runtime-adapter=|cut -d= -f2)
export REST_PROXY=$(cat $MANIFESTS_DIR/params.env |grep odh-mm-rest-proxy=|cut -d= -f2)

# You can choose fast/stable for image tag to test easily
if [[ ${tag} == "fast" ]]; then
  echo "TAG=fast is set"
  export MODELMESH=quay.io/opendatahub/modelmesh:fast
  export MODELMESH_RUNTIME=quay.io/opendatahub/modelmesh-runtime-adapter:fast
  export REST_PROXY=quay.io/opendatahub/rest-proxy:fast
elif [[ ${tag} == "stable" ]]; then
  echo "TAG=stable is set"
  export MODELMESH=quay.io/opendatahub/modelmesh:stable
  export MODELMESH_RUNTIME=quay.io/opendatahub/modelmesh-runtime-adapter:stable
  export REST_PROXY=quay.io/opendatahub/rest-proxy:stable
fi

images=(${TRITON_SERVER} ${ML_SERVER} ${OPENVINO} ${TORCHSERVE} ${MODELMESH} ${MODELMESH_RUNTIME} ${REST_PROXY})

echo 
echo "Start dowonload the following images:"
echo ${images[@]}

cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: image-downloader
spec:
  selector:
    matchLabels:
      app: image-downloader
  template:
    metadata:
      labels:
        app: image-downloader
    spec:
      containers:
      - name: triton-image-downloader
        image: ${TRITON_SERVER}
        command: ["/bin/sh"]
        args: ["-c", "sleep infinity"]
      - name: mlserver-image-downloader
        image: ${ML_SERVER}
        command: ["/bin/sh"]
        args: ["-c", "sleep infinity"]
      - name: openvino-image-downloader
        image: ${OPENVINO}
        command: ["/bin/sh"]
        args: ["-c", "sleep infinity"]
      - name: torchserve-image-downloader
        image: ${TORCHSERVE}
        command: ["/bin/sh"]
        args: ["-c", "sleep infinity"]
      - name: modelmesh-image-downloader
        image: ${MODELMESH}
        command: ["/bin/sh"]
        args: ["-c", "sleep infinity"]
      - name: modelmesh-runtime-image-downloader
        image: ${MODELMESH_RUNTIME}
        command: ["/bin/sh"]
        args: ["-c", "sleep infinity"]
      - name: rest-proxy-image-downloader
        image: ${REST_PROXY}
        command: ["/bin/sh"]
        args: ["-c", "sleep infinity"]
EOF

wait_downloading_images $images

echo 
echo "Delete image downloading daemonset"
oc delete daemonset  image-downloader --force --grace-period=0
