#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
MANIFESTS_DIR=$SCRIPT_DIR/manifests
OPENDATAHUB_DIR=$(dirname "$SCRIPT_DIR")
ROOT_DIR=${OPENDATAHUB_DIR}/..
MM_HOME_DIR=/tmp/modelmesh-e2e

MM_MANIFESTS_DIR=$SCRIPT_DIR/../../config

export PATH=${ROOT_DIR}/bin:$PATH

