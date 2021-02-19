#!/usr/bin/env bash

set -e
if [ -z "${VIEW_PATH}" ]; then
  if [ ! -z "${LCG_RELEASE}" ] && [ ! -z "${LCG_RELEASE_PLATFORM}" ]; then
    echo "You set the variable release and release-platform together, this is not possible."
    echo "You either the variable pair release and platform or just release-platform."
    exit 1
  fi


  if [ ! -z "${LCG_PLATFORM}" ] && [ ! -z "${LCG_RELEASE_PLATFORM}" ]; then
    echo "You set the variable platform and release-platform together, this is not possible."
    echo "You either the variable pair release and platform or just release-platform."
    exit 1
  fi

  if [ ! -z "${LCG_PLATFORM}" ]; then
    export LCG_RELEASE_PLATFORM="${LCG_RELEASE}/${LCG_PLATFORM}"
  fi
  export LCG_RELEASE=$(echo "${LCG_RELEASE_PLATFORM}" | cut -d '/' -f 1)
  export LCG_PLATFORM=$(echo "${LCG_RELEASE_PLATFORM}" | cut -d '/' -f 2)
  export SYSTEM=$(echo "${LCG_RELEASE_PLATFORM}" | cut -d '/' -f 2 | cut -d '-' -f 2)
else
  export SYSTEM=$(echo "${VIEW_PATH}" | awk -F'x86_64-' '{print $2}' | cut -d '-' -f 1)
fi

if [ "$(uname)" == "Linux" ]; then
  if [[ "${SYSTEM}" == *"mac"* ]]; then
    echo "You are trying to use a mac view on a linux system, this is not possible."
    exit 1
  fi
  if [ ! -z "${COVERITY_PROJECT_TOKEN}" ]; then
    if [ "$1" == "local" ]; then
      if
      . run-coverity.sh
    else
      $THIS/run-coverity.sh
    fi
  else
    if [ "$1" == "local" ]; then
      if
      . run-linux.sh
    else
      $THIS/run-linux.sh
    fi
  fi
fi


if [ "$(uname)" == "Darwin" ]; then
  if [[ "${SYSTEM}" != *"mac"* ]]; then
    echo "You are trying to use a non macOS view on a macOS system, this is not possible."
    exit 1
  fi
  if [ "$1" == "local" ]; then
    . run-macOS.sh
  else
    $THIS/run-macOS.sh
  fi
fi
