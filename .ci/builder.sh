#!/bin/bash -l
ls -alh .ci/header
. .ci/header
echo builder.sh
whoami
set -eux
. ~/.bashrc
printenv
which kubash

main () {
  kubash build -y --target-os ubuntu1.13.8 --verbosity=100
  kubash build -y --target-os ubuntu1.14.4 --verbosity=100
  kubash build -y --target-os ubuntu1.15.0 --verbosity=100
  kubash build -y --target-os coreos --builder coreos 
}

time main $@
