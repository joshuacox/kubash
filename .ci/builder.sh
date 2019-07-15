#!/bin/bash -l
ls -alh ./header
. ./header
echo builder.sh
whoami
set -eux
. ~/.bashrc
printenv
which kubash
