#!/bin/bash

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/utils.sh"

namespace=$1 
controllerns=$2
nsscope=$3
stable=$4

retry=5
count=1
makefile_path=${OPENDATAHUB_DIR}/../Makefile

if [[ z$controllerns == z ]]; then
  controllerns=${namespace}
fi

if [[ z$nsscope == z ]]; then
  nsscope=false
fi

fvt_lists=()
ginkgo_options=""
if [[ z$stable != z ]]; then
  fvt_string=$(grep -A 1 '^fvt-stable:$' ${makefile_path} | sed -n '2{s/^[[:blank:]]*//p;q}')
else
  fvt_string=$(grep -A 1 '^fvt:$' ${makefile_path} | sed -n '2{s/^[[:blank:]]*//p;q}')
fi

while IFS= read -r target; do
    fvt_lists+=("$target")
done < <(echo "$fvt_string" |grep -o 'fvt/[^ ]*')

ginkgo_options=$(echo ${fvt_string} |sed 's/fvt.* //')

info "* FVT Test List:"
for i in "${!fvt_lists[@]}"; do
    echo "  $i: ${fvt_lists[i]}"
done
info "GINKGO OPTIONS: $ginkgo_options"
echo "-----------------------------------"
echo 

info "* Start FVT test"
echo "namespace=${namespace}, controllerns=${controllerns}, nsscope=${nsscope}"

for i in "${!fvt_lists[@]}"; do
  echo CONTROLLERNAMESPACE=$controllerns NAMESPACE=$namespace NAMESPACESCOPEMODE=$nsscope ${ginkgo_options} ${fvt_lists[i]}
  CONTROLLERNAMESPACE=$controllerns NAMESPACE=$namespace NAMESPACESCOPEMODE=$nsscope ${ginkgo_options} ${fvt_lists[i]}
  fvt_result=$?
  
  while [[ $fvt_result != 0 ]]
  do
    if [[ $retry != $count ]];then
      info "$fvt_lists[i] failed. Retry it : retry count($count)"
      echo "Rollback minio storage secret"
      sed "s/controller_namespace/${namespace}/g" opendatahub/scripts/manifests/fvt/minio-storage-secret.yaml | oc apply -n $namespace  -f -
      
      echo "Restart ServingRuntime and controllers"
      oc delete pod --force -n $namespace -l modelmesh-service=modelmesh-serving 
      oc delete pod --force -n $controllerns -l app=odh-model-controller 
      oc delete pod --force -n $controllerns -l control-plane=modelmesh-controller
      
      wait_for_pods_ready "-l control-plane=modelmesh-controller" "$controllerns"
      
      # wait_for_pods_ready "-l app=odh-model-controller" "$controllerns" 

      echo "Waiting 60 secs before retrying"
      sleep 60 
      count=$((count+1))
      CONTROLLERNAMESPACE=$controllerns NAMESPACE=$namespace NAMESPACESCOPEMODE=$nsscope ${ginkgo_options} ${fvt_lists[i]}
      fvt_result=$?
    else
      die "FVT test(${fvt_lists[i]}) failed with $count retries"
    fi
  done
    success "Passed ${fvt_lists[i]}. Move on the next test"
    count=1
done
 
success "[SUCCESS] FVT Test Passed!"
