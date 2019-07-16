#!/bin/bash -l
pwd
ls -alh .ci/header
. .ci/header
echo ex.sh
whoami
set -eux
. ~/.bashrc
printenv
#which kubash
