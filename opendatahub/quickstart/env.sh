#!/bin/bash

export CURRENT_DIR=$(dirname "$(realpath "$0")")
export OPENDATAHUB_DIR=$(dirname "$CURRENT_DIR")
export QUICKSTART_DIR=$(dirname "$CURRENT_DIR"/quickstart )

export ROOT_DIR=${OPENDATAHUB_DIR}/../..
export COMMON_MANIFESTS_DIR=$OPENDATAHUB_DIR/common_manifests
export FVT_TEST_DIR=$ROOT_DIR/fvt/testdata
export HPA_DIR=$QUICKSTART_DIR/hpa
export PVC_DIR=$QUICKSTART_DIR/pvc
export BASIC_DIR=$QUICKSTART_DIR/basic

export ODH_NS=opendatahub
export MINIO_NS=minio
export TEST_MM_NS=model-serving
