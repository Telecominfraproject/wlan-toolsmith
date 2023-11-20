#!/bin/bash

function check_env()
{
    if [ -z "$CLUSTER_NAME" ] ; then
        echo "Missing CLUSTER_NAME definition"
        echo "Make sure to set environment variables eg. source env_file"
        exit 1
    elif [ -z "$CLUSTER_INSTANCE_TYPE" ] ; then
        echo "Missing CLUSTER_INSTANCE_TYPE definition"
        echo "Make sure to set environment variables eg. source env_file"
        exit 1
    elif [ -z "$AWS_REGION" ] ; then
        echo "Missing AWS_REGION definition"
        echo "Make sure to set environment variables eg. source env_file"
        exit 1
#    elif [ -z "$AWS_REGION_REGISTRY" ] ; then
#        echo "Missing AWS_REGION_REGISTRY definition"
#        echo "Make sure to set environment variables eg. source env_file"
#        exit 1
    fi
    if [ -z "$AWS_DEFAULT_REGION" ] ; then
        export AWS_DEFAULT_REGION="$AWS_REGION"
        #echo "Default AWS_DEFAULT_REGION to $AWS_DEFAULT_REGION"
    fi
    if [ -z "$CLUSTER_VERSION" ] ; then
        export CLUSTER_VERSION="1.27"
        echo "Default CLUSTER_VERSION to $CLUSTER_VERSION"
    fi
    if [ -z "$CLUSTER_NODES" ] ; then
        export CLUSTER_NODES="1"
        echo "Default CLUSTER_NODES to $CLUSTER_NODES"
    fi
    if [ -z "$CLUSTER_MIN_NODES" ] ; then
        export CLUSTER_MIN_NODES="1"
        echo "Default CLUSTER_MIN_NODES to $CLUSTER_MIN_NODES"
    fi
    if [ -z "$CLUSTER_MAX_NODES" ] ; then
        export CLUSTER_MAX_NODES="3"
        echo "Default CLUSTER_MAX_NODES to $CLUSTER_MAX_NODES"
    fi
    if [ -z "$CLUSTER_VOLUME_SIZE" ] ; then
        export CLUSTER_VOLUME_SIZE="100"
        echo "Default CLUSTER_VOLUME_SIZE to $CLUSTER_VOLUME_SIZE"
    fi
    if [ -z "$CLUSTER_ZONE_ID" ] ; then
        echo "CLUSTER_ZONE_ID not set - external-dns may not work!"
    fi
#    if [ -z "$CLUSTER_FS_DRIVER" ] ; then
#        export CLUSTER_FS_DRIVER="efs"
#        echo "Default CLUSTER_FS_DRIVER to $CLUSTER_FS_DRIVER"
#    fi
}

function show_env()
{
    echo "  - AWS profile: $AWS_PROFILE"
    echo "  - Region: $AWS_REGION"
    echo "  - Name: $CLUSTER_NAME"
    echo "  - Instance type: $CLUSTER_INSTANCE_TYPE"
    echo "  - Volume size: $CLUSTER_VOLUME_SIZE GiB"
    echo "  - Kubernetes version: $CLUSTER_VERSION"
    echo "  - # of nodes: $CLUSTER_NODES"
    echo "  - Min # of nodes: $CLUSTER_MIN_NODES"
    echo "  - Max # of nodes: $CLUSTER_MAX_NODES"
    #echo "  - AWS region registry: $AWS_REGION_REGISTRY"
    #echo "  - File System Driver: $CLUSTER_FS_DRIVER"
}

function logx()
{
    local x="$1"

    echo "-> $x"
}

function logv()
{
    local nm="$1"
    local val="$2"

    echo "-> $nm = $val"
    echo "${nm}=\"$val\"" >> ${CLUSTER_NAME}-logs
}
