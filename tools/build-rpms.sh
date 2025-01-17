#!/usr/bin/env bash

set -ev

SCRIPT_DIR=$(dirname $(readlink -f $0))
PROJECT_ROOT=$(dirname ${SCRIPT_DIR})

container_bin=$(command -v podman || command -v docker)
if [[ ${?} != 0 ]]; then
  echo "FAILURE: Neither docker nor podman is installed or in the current PATH."
  exit 99
fi

pushd ${PROJECT_ROOT}

  # This needs to be rm'd with sudo as it can have different uid/gid values
  # due to being mounted into the container on previous runs
  sudo rm -rf contrib/build

  NAME="${PWD##*/}"
  pushd ../
    tar -czf /tmp/directord.tar.gz --exclude .tox "${NAME}"
    mv /tmp/directord.tar.gz "${PROJECT_ROOT}/contrib/container-build/"
  popd

  eval ${container_bin} build -t directord-builder -f ${PROJECT_ROOT}/contrib/container-build/Containerfile ${PROJECT_ROOT}/contrib/container-build

  RELEASE_VERSION=$(awk -F'"' '/version/ {print $2}' ${PROJECT_ROOT}/directord/meta.py)
  GIT_REF=$(git rev-parse --short HEAD)
  eval ${container_bin} run --env GIT_REF="${GIT_REF}" --env RELEASE_VERSION="${RELEASE_VERSION}" --net=host -v ${PROJECT_ROOT}/contrib:/home/builder/rpm:Z directord-builder
popd
