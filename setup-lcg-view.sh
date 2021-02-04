#!/usr/bin/env bash

set -e

echo "Checking if there is a working CVMFS mount"

if [ ! -d "/cvmfs/sft.cern.ch/lcg/" ]
then
    echo "The directory /cvmfs/sft.cern.ch/lcg/ cannot be accessed!"
    echo "Make sure you are using the cvmfs-contrib/github-action-cvmfs@v2 action"
    exit 1
fi

if [ ! -d "/cvmfs/sft-nightlies.cern.ch/lcg/" ]
then
    echo "The directory /cvmfs/sft-nightlies.cern.ch/lcg/ cannot be accessed!"
    echo "Make sure you are using the cvmfs-contrib/github-action-cvmfs@v2 action"
    exit 1
fi

echo "CVMFS mount present"

if [[ -v ${LCG_RELEASE} && -v ${LCG_RELEASE_PLATFORM} ]]
then
	echo "You set the variable release and release-platform together, this is not possible."
	echo "You either the variable pair release and platform or just release-platform."
	exit 1
fi

if [[ -v ${LCG_PLATFORM} && -v ${LCG_RELEASE_PLATFORM} ]]
then
	echo "You set the variable platform and release-platform together, this is not possible."
	echo "You either the variable pair release and platform or just release-platform."
	exit 1
fi

if [[ -v ${LCG_PLATFORM} ]]
then
	export LCG_RELEASE_PLATFORM="${LCG_RELEASE}/${LCG_PLATFORM}"
fi
export LCG_RELEASE=$(echo "${LCG_RELEASE_PLATFORM}" | cut -d '/' -f 1)
export SYSTEM=$(echo "${LCG_RELEASE_PLATFORM}" | cut -d '/' -f 2 | cut -d '-' -f 2)


if [ "$(uname)" == "Linux" ]; then
  if [[ "${SYSTEM}" == *"mac"* ]]; then
    echo "You are trying to use a mac view on a linux system, this is not possible."
    exit 1
  fi
  if [ "$1" == "local" ]; then
    . run-linux.sh
  else
    $THIS/run-linux.sh
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
