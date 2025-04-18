# GitHub Action: aidasoft/run-lcg-view
![linux](https://github.com/AIDASoft/run-lcg-view/workflows/linux/badge.svg)![dev3](https://github.com/AIDASoft/run-lcg-view/workflows/dev3/badge.svg)[![coverity](https://github.com/AIDASoft/run-lcg-view/actions/workflows/coverity.yml/badge.svg)](https://github.com/AIDASoft/run-lcg-view/actions/workflows/coverity.yml)

This GitHub Action executes user payload code inside a LCG view environment, specified by the user.

## Instructions

### Prerequisites
This action depends on the user to call the companion action `uses: cvmfs-contrib/github-action-cvmfs@v2` before using `uses: aidasoft/run-lcg-view@v4`, which will install CVMFS on the node. GitHub Actions currently do not support calling the action `github-action-cvmfs` from within `run-lcg-view`, this needs to be done explicitly by the user.

### Example

You can use this GitHub Action in a workflow in your own repository with `uses: aidasoft/`.

A minimal job example for GitHub-hosted runners of type `ubuntu-latest`:
```yaml
jobs:
  run-lcg:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: cvmfs-contrib/github-action-cvmfs@v2
    - uses: aidasoft/run-lcg-view@v4
      with:
        release-platform: "LCG_99/x86_64-centos7-gcc10-opt"
        run: |
          gcc --version
          which gcc
```
In this case the action will automatically resolve the correct container image (in this case `centos7`) and spawn an instance with Docker from GitHub Container Registry or with Singularity from `/cvmfs/unpacked.cern.ch/`. The `Dockerfile` for the supported images can be found in the [AIDASoft/management](https://github.com/AIDASoft/management) repository.

The action mounts the checkout directory into the mentioned container and wraps the variable `run` in the script:

```sh
#!/usr/bin/env bash
export LC_ALL=C
set -e

source ${VIEW_PATH}/setup.sh

${RUN} # the multi-line variable specified in the action under run: |
```

which is executed in the container and thus giving the user an easy and direct access to run arbitrary code on top of LCG views.

#### macOS
It is currently not possible to mount CVMFS on the github CI machines with macOS.

### Parameters
The following parameters are supported:
 - `container`: Which container to use as base to setup a view. By default the container is inferred from `view-path` (default: `auto`)
 - `platform`: LCG view platform you are targeting (e.g. `x86_64-centos8-gcc10-opt`)
 - `release`: LCG view release you are targeting (e.g. `LCG_99`)
 - `release-platform`:LCG view release platform string you are targeting (e.g. `LCG_99/x86_64-centos8-gcc10-opt`)
 - `run`: They payload code you want to execute on top of the view
 - `setup-script`: Initialization/Setup script for a view that sets the environment (e.g. `setup.sh`)
 - `view-path`: Path where the setup script for the custom view is location. By specifying this variable the auto-resolving of the view based on `release` and `platform` is disabled. Furthermore the full path has to contain the architecture of the build in the form `/dir1/dir2/x86_64-{arch}-gcc../dir4/dir5`. The system will try to resolve the docker container equal to the string `{arch}` (the string after `x86_64-`).

Please be aware that you must use the combination of parameters `release` and `platform` together or use just the variable `release-platform` alone. These two options are given to enable more flexibility for the user to form their workflow with matrix expressions.

### Minimal Example

There are minimal examples, which are also workflows in this repository in the subfolder [.github/workflows/](https://github.com/AIDASoft/run-lcg-view/tree/main/.github/workflows).

## Limitations

The action will always resolve the correct image to execute your code on top the requested view, therefore you must always set the top level GitHub Action variable `runs-on: ubuntu-latest`.

## Coverity Scan extension
### Prerequisites
It is also possible to automatize [Coverity Scan](https://scan.coverity.com/) with this action. There are several steps that you need to do before being able to use this specific feature of this action:
 - Register you Open Source Project with [Coverity Scan](https://scan.coverity.com/)
 - Create a private Github Container Registry image with the Coverity Scan binaries (see [Dockerfile](https://github.com/AIDASoft/management/blob/master/coverity/Dockerfile) and [workflow](https://github.com/AIDASoft/management/blob/master/.github/workflows/images-creator.yml#L46)) embedded within. This will remove the need to always download the binary for each scan
 - Create a [Personal Access Token](https://github.com/settings/tokens) to be able to access the private image (add this variable as a secret)
 - Add to the project secrets the Coverity Scan token from your project

### Example
You can use this feature from this GitHub Action in a workflow in your own repository with `uses: aidasoft/run-lcg-view@v4`.
```yaml
jobs:
  run-coverity:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: cvmfs-contrib/github-action-cvmfs@v2
    - uses: aidasoft/run-lcg-view@v4
      with:
        coverity-container: 'ghcr.io/aidasoft/coverity:latest'
        coverity-cmake-command: 'cmake -DCMAKE_CXX_STANDARD=17 ..'
        coverity-project: 'AIDASoft%2Fpodio'
        coverity-project-token: ${{ secrets.PODIO_COVERITY_TOKEN }}
        github-pat: ${{ secrets.READ_COVERITY_IMAGE }}
        release-platform: "LCG_99/x86_64-centos7-gcc10-opt"
```
The user needs to take care that the `release-platform` is compatible with the `coverity-container`.

The action mounts the checkout directory into the selected container and wraps the variable `coverity-cmake-command` in the script:

```sh
#!/usr/bin/env bash

set -e

source ${VIEW_PATH}/${SETUP_SCRIPT}
${RUN}
mkdir build
cd build
${COVERITY_CMAKE_COMMAND}
cov-build --dir cov-int make -j4
tar czvf /myproject.tgz cov-int
```
It is expected that the `cov-build` command is already in the `PATH` of the selected image.

The action finishes by uploading the tar ball to the server as per instruction given by Coverity Scan.

### Parameters for Coverity extension
The following parameters are supported:
 - ` coverity-container`: Location of container that has Coverity Scan installed (default: `ghcr.io/aidasoft/coverity:latest` but not public)
- `coverity-cmake-command`:  CMake command for building your project, assuming in source build.
- `coverity-project`: Coverity project name in URL encoding ( `/` -> `%2F` e.g. `AIDASoft%2FDD4hep`)'. Name under which your project is registered with the Coverity Scan server.
- `coverity-project-token`: Coverity project token to interact with the server
- `github-pat`: GitHub Personal Access Token for reading your custom image given under `coverity-container`
