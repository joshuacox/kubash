#!/bin/bash -l
ls -alh .ci/header
. .ci/header
echo builder.sh
whoami
set -eux
. ~/.bashrc
printenv
which kubash
