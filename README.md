# GitHub Action: aidasoft/run-lcg-view
![linux](https://github.com/AIDASoft/run-lcg-view/workflows/linux/badge.svg)![macOS](https://github.com/AIDASoft/run-lcg-view/workflows/macOS/badge.svg)![dev3](https://github.com/AIDASoft/run-lcg-view/workflows/dev3/badge.svg)

This GitHub Action executes user payload code inside a LCG view environment, specified by the user.

## Instructions

# Prerequisites
This action depends on the user to call the companion action `uses: cvmfs-contrib/github-action-cvmfs@v2` before using `uses: aidasoft/run-lcg-view@main`, which will install CVMFS on the node. GitHub Actions currently do not support to call from within `run-lcg-view` the action `github-action-cvmfs`, this needs to be done explicitly by the user.

# Example

You can use this GitHub Action in a workflow in your own repository with `uses: aidasoft/run-lcg-view@main`.

A minimal job example for GitHub-hosted runners of type `ubuntu-latest`:
```yaml
jobs:
  run-lcg:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: cvmfs-contrib/github-action-cvmfs@v2
    - uses: aidasoft/run-lcg-view@main
      with:
        release-platform: "LCG_99/x86_64-centos7-gcc10-opt"
        run: |
          gcc --version
          which gcc
```
In this case the action will automatically resolve the correct docker image (in this case `centos7`) and download it from the GitHub Container Registry. The `Dockerfile`s for the supported images can be found in the [AIDASoft/management](https://github.com/AIDASoft/management) repository.

The action mounts the checkout directory into the mentioned container and wraps the variable `run` in the script:

```sh
#!/usr/bin/env bash

set -e

source ${VIEW_PATH}/setup.sh

${RUN} # the multi-line variable specified in the action under run: |
```

Which is executed in the container and thus giving the user a easy and direct access run arbitrary code on top of LCG views.


The Action also works with runners of type `macos-latest`, however in this case it is necessary to specify the repositories you want to mount (via the variable `cvmfs_repositories`), as there is not auto mount for macOS. A minimal example of usage on `macos-latest` is:
```yaml
jobs:
  run-lcg:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v2
    - uses: cvmfs-contrib/github-action-cvmfs@v2
      with:
        cvmfs_repositories: 'sft.cern.ch,geant4.cern.ch'
    - uses: aidasoft/run-lcg-view@main
      with:
        release-platform: "LCG_99/x86_64-mac1015-clang120-opt"
        run: |
          which ddsim
          ddsim --help
```
Beware that because the runner cannot be rebooted in the macOS case, the repositories are mounted under `/Users/Shared/cvmfs/`. It is also necessary to mount `geant4.cern.ch` in addition to `sft.cern.ch` as the Geant4 data files associated to a view are stored in the Geant4 cvmfs repository.

## Parameters
The following parameters are supported:
 - `release`: LCG view release are you targeting (e.g. `LCG_99`)
 - `platform`: LCG view platform are you targeting (e.g. `x86_64-centos8-gcc10-opt`)
 - `release-platform`:LCG view release platform string are you targeting (e.g. `LCG_99/x86_64-centos8-gcc10-opt`)
 - `run`: They payload code you want to execute on-top of the view

Please be aware that you must use the combination of parameters `release` and `platform` together or use just the variable `release-platform` alone. This two options are give to enable the user more flexifility to form their workflow with matrix expressions.

## Minimal Example

There are minimal examples, which are also workflows in this repository in the subfolder [.github/workflows/](https://github.com/AIDASoft/run-lcg-view/tree/main/.github/workflows).

## Limitations

The action will always resolve the correct image to execute your code on top the requested view, therefore you must always set the top level GitHub Action variable `runs-on: ubuntu-latest`. Hower this is not the case if you want to execute on macOS, there you have to set this variable to `runs-on: macos-latest`.
