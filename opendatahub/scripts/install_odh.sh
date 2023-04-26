#!/bin/bash

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/utils.sh"

MM_HOME_DIR=/tmp/modelmesh-3
KFDEF_FILE=${MM_HOME_DIR}/kfdef.yaml

tag=none
ctrlnamespace=opendatahub
img_map=none
img_name=
img_url=
mm_user=opendatahub-io
mm_branch=main
function showHelp() {
  echo "usage: $0 [flags]"
  echo
  echo "Flags:"
  echo "  -c, --ctrl-namespace           (optional) Kubernetes namespace to deploy modelmesh controller to(default modelmesh-serving)."
  echo "  -t, --tag                      (optional) Set tag fast,stable to change images quickly(default none)."
  echo "  -i, --image                    (optional) Set custom image (default none)."
  echo "  -u, --user                     (optional) Set odh-manifests repo user to be used for deployment(default opendatahub-io) - modelmesh/modelmesh-serving/modelmesh-runtime-adapter/rest-proxy odh-model-controller."
  echo "                                   ex) -u opendatahub-io"
  echo "                                   meaning > https://api.github.com/repos/opendatahub-io"
  echo "  -b, --branch                    (optional) Set odh-manifests repo branch to be used for deployment (default main)."
  echo "                                 ex) -i rest-proxy=quay.io/opendatahub/rest-proxy:pr-89"
  echo
  echo "Installs modelmesh controller."
}


while (($# > 0)); do
  case "$1" in
  -h | --h | --he | --hel | --help)
    showHelp
    exit 2
    ;;
  -c | --c | -ctrl-namespace | --ctrl-namespace)
    shift
    ctrlnamespace="$1"
    ;;  
  -i | --i | -image | --image)
    shift
    img_map="$1"
    img_name=$(echo ${img_map}|cut -d'=' -f1)
    img_url=$(echo ${img_map}|cut -d'=' -f2)
    echo $img_name $img_url
    ;;    
  -t | --t | -tag | --tag)
    shift
    tag="$1"
    ;;    
  -u | --u | -user | --user)
    shift
    mm_user="$1"
    ;;    
  -b | --b | -branch | --branch)
    shift
    mm_branch="$1"
    ;;    
  -*)
    die "Unknown option: '${1}'"
    ;;       
  esac
  shift
done    

allowedImgName=false
if [[ ${img_map} != none ]]; then
  checkAllowedImage ${img_name}
  if [[ $? == 0 ]]; then
    allowedImgName=true
  fi
fi


if [[ -d ${MM_HOME_DIR} ]]; then
  info "Delete the exising ${MM_HOME_DIR} folder"
  rm -rf ${MM_HOME_DIR}
fi

info "Creating a ${MM_HOME_DIR} folder"
mkdir -p ${MM_HOME_DIR}

# You can choose fast/stable for image tag to test easily
if [[ ${tag} == "fast" ]]; then
  info "TAG=fast is set"
  cp $OPENDATAHUB_DIR/kfdef/kfdef-fast.yaml  ${KFDEF_FILE}
elif [[ ${tag} == "stable" ]]; then
  info "TAG=stable is set"
  cp $OPENDATAHUB_DIR/kfdef/kfdef-stable.yaml  ${KFDEF_FILE}
elif [[ ${tag} == "none" ]]; then
  info "TAG is NOT set"
  cp $OPENDATAHUB_DIR/kfdef/kfdef.yaml  ${KFDEF_FILE}
else
  die "Unknown tag: ${tag}"
fi
echo 

# Update repo uri
if [[ ${mm_user} != opendatahub-io ]];then
  sed "s/%mm_user%/${mm_user}/g" -i ${KFDEF_FILE} 
fi
if [[ ${mm_branch} != main ]];then
  sed "s/%mm_branch%/${mm_branch}/g" -i ${KFDEF_FILE}
fi

# If the image is in allowed image list, update the img url
if [[ ${allowedImgName} == "true" ]] && [[ ${tag} != "none" ]] ; then
  sed "s+quay.io/.*${img_name}:.*$+${img_url}+g" -i ${KFDEF_FILE}
fi

# Deploy opendatahub operator 
oc apply -f ${MANIFESTS_DIR}/subs_odh_operator.yaml

# Create the kfdef in a ctrlnamespace
oc project ${ctrlnamespace} || oc new-project ${ctrlnamespace}
oc apply -n ${ctrlnamespace} -f ${KFDEF_FILE}

wait_for_pods_ready "-l control-plane=modelmesh-controller"
wait_for_pods_ready "-l app=odh-model-controller" 
