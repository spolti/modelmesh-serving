#!/bin/bash
source "$(dirname "$(realpath "$0")")/../env.sh"
source "${OPENDATAHUB_DIR}/../scripts/utils.sh"

export CURRENT_DIR=$(dirname "$(realpath "$0")")
export DEMO_HOME=/tmp/modelmesh/basic

cd ${ROOT_DIR}
CONTROLLERNAMESPACE=opendatahub NAMESPACE=${TEST_MM_NS} C_MM_TEST=true C_MM_CTRL_KUSTOMIZE=yes make cleanup-for-odh
