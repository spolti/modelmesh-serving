#!/bin/bash

export SCRIPT_DIR=$(dirname "$(realpath "$0")")
export MANIFESTS_DIR=$SCRIPT_DIR/manifests
export OPENDATAHUB_DIR=$(dirname "$SCRIPT_DIR")
export ODH_MANIFESTS_DIR=$OPENDATAHUB_DIR/odh-manifests


# echo $SCRIPT_DIR
# echo $MANIFESTS_DIR
# echo $OPENDATAHUB_DIR
# echo $ODH_MANIFESTS_DIR
