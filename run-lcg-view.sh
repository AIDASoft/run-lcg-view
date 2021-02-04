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
SYSTEM=$(echo "${LCG_RELEASE_PLATFORM}" | cut -d '/' -f 2 | cut -d '-' -f 2)

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
