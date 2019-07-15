#!/bin/bash -l
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.kubash/bin:$PATH
echo builder.sh
whoami
set -eux
. ~/.bashrc
printenv
which kubash
