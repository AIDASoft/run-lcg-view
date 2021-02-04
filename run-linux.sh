#!/usr/bin/env bash

set -e

VIEW_PATH="/cvmfs/sft.cern.ch/lcg/views/"
if [[ "${LCG_RELEASE}" == *"dev"* ]]
then
  VIEW_PATH="/cvmfs/sft-nightlies.cern.ch/lcg/views/"
fi

echo "Starting docker image for ${SYSTEM}"
docker run -it --name view_worker -v ${GITHUB_WORKSPACE}:${GITHUB_WORKSPACE} -v /cvmfs:/cvmfs:shared -d ghcr.io/aidasoft/${SYSTEM}:latest /bin/bash
echo "Docker image ready for ${SYSTEM}"

echo "#!/usr/bin/env bash

set -e

source ${VIEW_PATH}/${LCG_RELEASE_PLATFORM}/setup.sh

${RUN}
" > ${GITHUB_WORKSPACE}/action_payload.sh
chmod a+x ${GITHUB_WORKSPACE}/action_payload.sh

echo "####################################################################"
echo "###################### Executing user payload ######################"
echo "VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV"

docker exec view_worker /bin/bash -c "${GITHUB_WORKSPACE}/action_payload.sh"
