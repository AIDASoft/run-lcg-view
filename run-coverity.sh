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

if [ -z "${COVERITY_CONTAINER}" ]; then
  echo "Action variable coverity-container empty!"
  exit 1
fi

if [ -z "${COVERITY_CMAKE_COMMAND}" ]; then
  echo "Action variable coverity-cmake-command empty!"
  exit 1
fi

if [ -z "${COVERITY_PROJECT}" ]; then
  echo "Action variable coverity-project empty!"
  exit 1
fi

if [ -z "${COVERITY_PROJECT_TOKEN}" ]; then
  echo "Action variable coverity-project-token empty!"
  exit 1
fi

if [ -z "${GITHUB_PAT}" ]; then
  echo "Action variable github-pat empty!"
  exit 1
fi

echo "Login into GitHub Container Registry"
echo ${GITHUB_PAT} | docker login ghcr.io --username ${GITHUB_ACTOR} --password-stdin;
echo "Login successful"


echo "Starting docker image ${COVERITY_CONTAINER} for Coverity"
docker run -it --name view_worker -v ${GITHUB_WORKSPACE}:${GITHUB_WORKSPACE} -v /cvmfs:/cvmfs:shared -d ${COVERITY_CONTAINER} /bin/bash
echo "Docker image ready for Coverity"

echo "#!/usr/bin/env bash

set -e

source ${VIEW_PATH}/${SETUP_SCRIPT}
${RUN}
mkdir build
cd build
${COVERITY_CMAKE_COMMAND}
cov-build --dir cov-int make -j4
tar czvf /myproject.tgz cov-int
" > ${GITHUB_WORKSPACE}/coverity_scan.sh
chmod a+x ${GITHUB_WORKSPACE}/coverity_scan.sh

echo "::endgroup::" # Launch container

echo "#####################################################################"
echo "###################### Executing Coverity Scan ######################"
echo "VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV"

docker exec view_worker /bin/bash -c "cd ${GITHUB_WORKSPACE}; ./coverity_scan.sh"

echo "#####################################################################"
echo "###################### Coverity Scan Compelte #######################"
echo "#####################################################################"

echo "::group::Upload artifacts"
echo "Start uploading compilation units for analysis"

docker cp view_worker:/myproject.tgz myproject.tgz

if [ "$1" != "local" ]; then
  curl --form token=${COVERITY_PROJECT_TOKEN} \
     --form email=noreply@cern.ch \
     --form file=@myproject.tgz \
     --form version="master" \
     --form description="Scan by run-lcg-view GitHub Action" \
     https://scan.coverity.com/builds?project=${COVERITY_PROJECT}
else
  echo "Not submitting to server only test run"
fi
echo "::endgroup::"
