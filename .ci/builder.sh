#!/bin/bash -l
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.kubash/bin:$PATH
set -eux
. ~/.bashrc
printenv
which kubash
