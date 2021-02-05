#!/bin/zsh

set -e

echo "Checking if there is a working CVMFS mount"

if [ ! -d "/Users/Shared/cvmfs/sft.cern.ch/lcg/" ]; then
    echo "The directory /Users/Shared/cvmfs/sft.cern.ch/lcg cannot be accessed!"
    echo "Make sure you are using the cvmfs-contrib/github-action-cvmfs@v2 action"
    echo "and that you have set cvmfs_repositories: 'sft.cern.ch,geant4.cern.ch'."
    echo "There is no automout on macOS."
    exit 1
fi

if [ ! -d "/Users/Shared/cvmfs/geant4.cern.ch/share/" ]; then
    echo "The directory /Users/Shared/cvmfs/geant4.cern.ch/share/ cannot be accessed!"
    echo "Make sure you are using the cvmfs-contrib/github-action-cvmfs@v2 action"
    echo "and that you have set cvmfs_repositories: 'sft.cern.ch,geant4.cern.ch'."
    echo "There is no automout on macOS."
    exit 1
fi

echo "CVMFS mount present"

VIEW_PATH="/Users/Shared/cvmfs/sft.cern.ch/lcg/views/${LCG_RELEASE_PLATFORM}"
echo "Full view path is ${VIEW_PATH}"

if [ ! -d "${VIEW_PATH}" ]; then
    echo "Did not find a view under this path!"
    exit 1
fi

echo "#!/bin/zsh

set -e

source ${VIEW_PATH}/${SETUP_SCRIPT}

${RUN}
" > ${GITHUB_WORKSPACE}/action_payload.sh
chmod a+x ${GITHUB_WORKSPACE}/action_payload.sh

echo "####################################################################"
echo "###################### Executing user payload ######################"
echo "VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV"

${GITHUB_WORKSPACE}/action_payload.sh
