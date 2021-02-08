#!/usr/bin/env bash

set -e

echo "Checking if there is a working CVMFS mount"

if [ ! -d "/cvmfs/sft.cern.ch/lcg/" ]; then
  echo "The directory /cvmfs/sft.cern.ch/lcg/ cannot be accessed!"
  echo "Make sure you are using the cvmfs-contrib/github-action-cvmfs@v2 action"
  exit 1
fi

if [ ! -d "/cvmfs/sft-nightlies.cern.ch/lcg/" ]; then
  echo "The directory /cvmfs/sft-nightlies.cern.ch/lcg/ cannot be accessed!"
  echo "Make sure you are using the cvmfs-contrib/github-action-cvmfs@v2 action"
  exit 1
fi

if [ ! -d "/cvmfs/geant4.cern.ch/share/" ]; then
  echo "The directory /cvmfs/geant4.cern.ch/share/ cannot be accessed!"
  echo "Make sure you are using the cvmfs-contrib/github-action-cvmfs@v2 action"
  exit 1
fi

echo "CVMFS mount present"

if [ -z "${VIEW_PATH}" ]; then
  VIEW_PATH="/cvmfs/sft.cern.ch/lcg/views/${LCG_RELEASE_PLATFORM}"
  if [[ "${LCG_RELEASE}" == *"dev"* ]]; then
    VIEW_PATH="/cvmfs/sft-nightlies.cern.ch/lcg/views/${LCG_RELEASE}/latest/${LCG_PLATFORM}"
  fi
fi

echo "Full view path is ${VIEW_PATH}"

if [ ! -d "${VIEW_PATH}" ]; then
  echo "Did not find a view under this path!"
  exit 1
fi

echo "Starting docker image for ${SYSTEM}"
docker run -it --name view_worker -v ${GITHUB_WORKSPACE}:${GITHUB_WORKSPACE} -v /cvmfs:/cvmfs:shared -d ghcr.io/aidasoft/${SYSTEM}:latest /bin/bash
echo "Docker image ready for ${SYSTEM}"

echo "#!/usr/bin/env bash

set -e

source ${VIEW_PATH}/${SETUP_SCRIPT}

${RUN}
" > ${GITHUB_WORKSPACE}/action_payload.sh
chmod a+x ${GITHUB_WORKSPACE}/action_payload.sh

echo "####################################################################"
echo "###################### Executing user payload ######################"
echo "VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV"

docker exec view_worker /bin/bash -c "cd ${GITHUB_WORKSPACE}; ./action_payload.sh"
