#!/bin/bash -l
ls -alh .ci/header
. .ci/header
echo builder.sh
whoami
set -eux
. ~/.bashrc
printenv
which kubash
which packer

main () {
  kubash build -y --target-os ubuntu1.13.8 --verbosity=100
  kubash build -y --target-os ubuntu1.14.4 --verbosity=100
  kubash build -y --target-os ubuntu1.15.0 --verbosity=100
  kubash -n coreos1 yaml2cluster ~/coreos1/coreos1.yaml
  kubash -n coreos1 provision --verbosity=100
  kubash -n coreos1 init --verbosity=100
  cp ~/.kubash/clusters/coreos1/config ~/.kube/config
  date -I > $THIS_CLUSTER_NAME.log
  kubectl get nodes >> coreos1.log
  kubectl get pods --all-namespaces >> coreos1.log
  rm -Rf ~/.kubash/clusters/coreos1
  kubash -n coreos1 decommission -y 
}

time main $@
