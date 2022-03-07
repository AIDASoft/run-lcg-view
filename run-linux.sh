#!/usr/bin/env bash

set -e
echo "::group::Launching container"

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

echo "#!/usr/bin/env bash
export LC_ALL=C
set -e

source ${VIEW_PATH}/${SETUP_SCRIPT}

${RUN}
" > ${GITHUB_WORKSPACE}/action_payload.sh
chmod a+x ${GITHUB_WORKSPACE}/action_payload.sh

if [ ${UNPACKED} == "true" ]; then
  echo "Install Singularity"
  conda install --quiet --yes -c conda-forge singularity > /dev/null 2>&1
  eval "$(conda shell.bash hook)"

  echo "Starting Singularity image for ${SYSTEM} from /cvmfs/unpacked.cern.ch"
  singularity instance start --bind /cvmfs --bind ${GITHUB_WORKSPACE}:${GITHUB_WORKSPACE} /cvmfs/unpacked.cern.ch/ghcr.io/aidasoft/${SYSTEM}:latest view_worker
else
  echo "Starting docker image for ${SYSTEM}"
  docker run -it --name view_worker -v ${GITHUB_WORKSPACE}:${GITHUB_WORKSPACE} -v /cvmfs:/cvmfs:shared -d ghcr.io/aidasoft/${SYSTEM}:latest /bin/bash
  echo "Docker image ready for ${SYSTEM}"
fi

echo "::endgroup::" # Launch container

echo "####################################################################"
echo "###################### Executing user payload ######################"
echo "VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV"

if [ ${UNPACKED} == "true" ]; then
  singularity exec instance://view_worker /bin/bash -c "cd ${GITHUB_WORKSPACE}; ./action_payload.sh"
else
  docker exec view_worker /bin/bash -c "cd ${GITHUB_WORKSPACE}; ./action_payload.sh"
fi
