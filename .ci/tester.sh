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
  kubash -n coreos1 yaml2cluster ~/.kubash/examples/coreos1-stacked.yaml
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
